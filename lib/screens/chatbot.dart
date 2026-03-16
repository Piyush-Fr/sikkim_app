import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/secrets.dart';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot>
    with AutomaticKeepAliveClientMixin<Chatbot> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final List<_Message> _messages = <_Message>[];
  String? _activeUserId;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _msgSub;
  bool _hasNetwork = true;
  bool _isSpeaking = false; // tracked to know if TTS is currently narrating
  bool _isLoading = false;
  bool _narrationEnabled = true; // Speaker toggle

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initLocal();
    _initTts();
    _watchConnectivity();
    _attachToCurrentUser();

    // If an initial query is provided, send it after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final q = widget.initialQuery?.trim();
      if (q != null && q.isNotEmpty) {
        _textController.text = q;
        final locale = q.contains(RegExp('[\u0900-\u097F]'))
            ? 'hi-IN'
            : 'en-IN';
        await _askGuide(locale);
      }
    });
  }

  Future<void> _attachToCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Not logged in: clear active user and stop listening
        _msgSub?.cancel();
        setState(() {
          _activeUserId = null;
          _messages.clear();
        });
        return;
      }
      setState(() => _activeUserId = user.uid);
      _listenUserMessages(user.uid);
    } catch (e) {
      print('Error attaching to user: $e');
    }
  }

  // Removed unused session update method

  // Sign-in functionality moved to login.dart

  void _listenUserMessages(String uid) {
    _msgSub?.cancel();
    _msgSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
          final List<_Message> loaded = <_Message>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final role = (data['role'] ?? '').toString();
            final text = (data['text'] ?? '').toString();
            if (role.isEmpty || text.isEmpty) continue;
            loaded.add(_Message(role: role, text: text));
          }
          if (mounted) {
            setState(() {
              _messages
                ..clear()
                ..addAll(loaded);
            });
          }
          // Cache messages locally for quick restore
          try {
            if (loaded.isNotEmpty) {
              final box = Hive.box('guide_cache');
              final compact = loaded
                  .map((m) => {'role': m.role, 'text': m.text})
                  .toList(growable: false);
              box.put('cached_messages', compact);
              print('Cached ${loaded.length} messages locally');
            }
          } catch (e) {
            print('Error caching messages: $e');
          }
        });
  }

  Future<void> _initLocal() async {
    try {
      // Hive is already initialized in main.dart, just access the box
      final box = Hive.box('guide_cache');
      // Hydrate from cached messages
      final List cached =
          box.get('cached_messages', defaultValue: <dynamic>[]) as List;
      if (cached.isNotEmpty) {
        final restored = cached
            .map(
              (e) => _Message(
                role: (e['role'] ?? '').toString(),
                text: (e['text'] ?? '').toString(),
              ),
            )
            .where((m) => m.role.isNotEmpty && m.text.isNotEmpty)
            .toList();
        if (restored.isNotEmpty && mounted) {
          setState(() {
            _messages
              ..clear()
              ..addAll(restored);
          });
        }
      }
    } catch (e) {
      print('Error loading cached messages: $e');
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setVoice({'name': 'en-in-x-end-local', 'locale': 'en-IN'});
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  void _watchConnectivity() async {
    // connectivity_plus 6.x returns List<ConnectivityResult>
    final statusList = await Connectivity().checkConnectivity();
    _hasNetwork = statusList.any((s) => s != ConnectivityResult.none);
    print('DEBUG CHATBOT: Initial network check: $_hasNetwork (status: $statusList)');
    _connSub = Connectivity().onConnectivityChanged.listen((list) {
      final anyConnected = list.any((s) => s != ConnectivityResult.none);
      print('DEBUG CHATBOT: Network changed: $anyConnected (status: $list)');
      setState(() => _hasNetwork = anyConnected);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _msgSub?.cancel();
    // STT disabled
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  // STT removed
  // _testConnection removed

  Future<void> _speak(String text, {String lang = 'en-IN'}) async {
    if (!_narrationEnabled) return;
    setState(() => _isSpeaking = true);
    await _tts.setLanguage(lang);
    if (lang.startsWith('hi')) {
      await _tts.setVoice({'name': 'hi-in-x-hia-local', 'locale': 'hi-IN'});
    }
    await _tts.setSpeechRate(0.55);
    await _tts.speak(text);
  }

  Future<void> _askGuide(String locale) async {
    final input = _textController.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _messages.add(_Message(role: 'user', text: input));
      _isLoading = true;
    });
    // Persist user message (non-blocking — don't let Firestore hang the chatbot)
    _persistMessage(role: 'user', text: input).catchError((e) {
      print('DEBUG: Non-blocking persist error (user msg): $e');
    });

    final String prompt = _buildPrompt(input, locale);
    String reply;
    try {
      // Always try the API call directly — connectivity_plus is unreliable on many devices
      print('DEBUG CHATBOT: Calling Gemini API...');
      final apiKey = Secrets.geminiApiKey;
      print('DEBUG CHATBOT: Using API key: ${apiKey.substring(0, 10)}...');

      final model = genai.GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      print('DEBUG CHATBOT: Starting _generateWithRetry with 30s timeout...');
      String? respText;
      try {
        respText = await _generateWithRetry(model, prompt)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                print('DEBUG CHATBOT: Gemini API timed out after 30s');
                return null;
              },
            );
      } catch (retryError) {
        print('DEBUG CHATBOT: _generateWithRetry threw: $retryError');
        rethrow;
      }
      print('DEBUG CHATBOT: API result: ${respText == null ? "null" : "length=${respText.length}"}');

      if (respText != null && respText.isNotEmpty) {
        reply = respText;
        // Cache FAQ locally
        try {
          final box = Hive.box('guide_cache');
          final Map faq = box.get('faq', defaultValue: {}) as Map;
          faq[input] = reply;
          await box.put('faq', faq);
        } catch (e) {
          print('DEBUG CHATBOT: FAQ cache error (non-critical): $e');
        }
      } else {
        // API returned empty after all retries — show clear message
        reply = locale.startsWith('hi')
            ? 'API से कोई जवाब नहीं मिला। कृपया पुनः प्रयास करें।'
            : 'No response from AI. Please try again in a moment.';
      }
    } catch (e) {
      final err = e.toString();
      print('GEMINI ERROR: $err');
      reply = locale.startsWith('hi')
          ? 'त्रुटि: $err'
          : 'Error: $err';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_Message(role: 'assistant', text: reply));
      _isLoading = false;
      _textController.clear();
    });
    // Persist assistant message (non-blocking)
    _persistMessage(role: 'assistant', text: reply).catchError((e) {
      print('DEBUG: Non-blocking persist error (assistant msg): $e');
    });
    if (_narrationEnabled) {
      await _speak(reply, lang: locale.replaceAll('_', '-'));
    } else {
      await _tts.stop();
    }
  }

  Future<void> _persistMessage({
    required String role,
    required String text,
  }) async {
    // Add message to local UI state
    if (!mounted) return;

    // Also save to local storage immediately to ensure persistence
    try {
      final box = Hive.box('guide_cache');
      final List cached =
          box.get('cached_messages', defaultValue: <dynamic>[]) as List;
      final List<Map<String, dynamic>> updatedCache =
          List<Map<String, dynamic>>.from(cached);
      updatedCache.add({'role': role, 'text': text});
      await box.put('cached_messages', updatedCache);
    } catch (e) {
      print('Error saving message to local cache: $e');
    }

    // Then save to Firestore if we have a logged in user
    if (_activeUserId == null) return;
    try {
      final uid = _activeUserId!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .add({
            'uid': uid,
            'role': role,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error saving message to Firestore: $e');
    }
  }

  String _buildPrompt(String userInput, String locale) {
    final system = locale.startsWith('hi')
        ? 'आप "सिक्की" हैं, सिक्किम, भारत के लिए एक मित्रवत, उत्साही और विशेषज्ञ AI यात्रा गाइड। आपका मुख्य लक्ष्य उपयोगकर्ताओं को इस खूबसूरत हिमालयी राज्य की यात्रा की योजना बनाने में मदद करना है।'
        : 'You are "Sikky", a friendly, enthusiastic, and expert AI travel guide for Sikkim, India. Your primary goal is to help users plan a personalized and unforgettable trip to this beautiful Himalayan state.';

    final context = locale.startsWith('hi')
        ? 'आपके मुख्य निर्देश:\n\n1. प्रारंभिक अभिवादन और व्यक्तित्व:\n   - केवल पहली बार: आपको नई बातचीत की पहली बातचीत में इस परिचय के साथ शुरुआत करनी चाहिए: "नमस्ते! मैं सिक्की हूँ, सिक्किम के अजूबों की आपकी व्यक्तिगत गाइड! आपकी सही यात्रा की योजना बनाने में मदद के लिए, क्या आप मुझे बता सकते हैं कि आप कितने दिन बिताने की सोच रहे हैं और आपकी मुख्य रुचियां क्या हैं? क्या आप शांत मठों, साहसिक ट्रेकिंग, या मनमोहक प्राकृतिक दृश्यों की ओर आकर्षित हैं?"\n   - चल रही बातचीत: बाद के सभी संदेशों के लिए, परिचय को दोहराएं नहीं। अपने अन्य निर्देशों के आधार पर सीधे और सहायक रूप से उपयोगकर्ता के प्रश्न का उत्तर दें।\n\n2. यात्रा योजना विशेषज्ञ:\n   - जब कोई उपयोगकर्ता यात्रा की योजना बनाना चाहता है, तो अवधि (दिनों की संख्या) और उनकी मुख्य रुचियों (जैसे मठ, ट्रेकिंग, प्रकृति, संस्कृति, भोजन) के बारे में पूछें।\n   - उनके इनपुट के आधार पर, संक्षिप्त, दिन-प्रतिदिन का कार्यक्रम बनाएं। प्रत्येक दिन की गतिविधियों के लिए बुलेट पॉइंट्स का उपयोग करें।\n   - तार्किक मार्ग सुझाएं। उदाहरण के लिए, पूर्वी सिक्किम (गंगटोक, त्सोमगो झील) के आकर्षणों को एक साथ समूहीकृत करें, और पश्चिमी सिक्किम (पेलिंग, युक्सोम) के आकर्षणों को एक साथ समूहीकृत करें।\n   - यात्रा के समय और परमिट आवश्यकताओं (जैसे उत्तरी सिक्किम के लिए) के बारे में जागरूक रहें। जब परमिट की आवश्यकता हो तो उल्लेख करें।\n\n3. ज्ञान आधार:\n   - आपके पास सिक्किम के मठों की गहरी जानकारी है, जिसमें शामिल हैं लेकिन इन्हीं तक सीमित नहीं: रुमटेक, पेमायंगत्से, ताशीडिंग, एंचे, रालांग, और दुब्दी। ऐतिहासिक संदर्भ प्रदान करें, प्रत्येक को क्या अनूठा बनाता है, और यदि संभव हो तो खुलने के समय जैसी आगंतुक जानकारी।\n   - आप गंगटोक (एमजी मार्ग), त्सोमगो झील, नाथुला पास, पेलिंग, युक्सोम, लाचुंग, युमथांग घाटी, और गुरुडोंगमार झील जैसे अन्य प्रमुख पर्यटन स्थलों के भी विशेषज्ञ हैं।\n   - यात्रा का सबसे अच्छा समय, आजमाने के लिए स्थानीय व्यंजन, परिवहन विकल्प (साझा जीप बनाम निजी टैक्सी), और सांस्कृतिक शिष्टाचार पर व्यावहारिक सलाह प्रदान करें।\n\n4. स्वर और शैली:\n   - हमेशा मित्रवत, धैर्यवान और प्रोत्साहित करने वाला रहें।\n   - अपने उत्तरों को स्पष्ट, अच्छी तरह से संरचित और पढ़ने में आसान रखें। मुख्य जानकारी को उजागर करने के लिए सूचियों का उपयोग करें, लेकिन बोल्ड टेक्स्ट या किसी मार्कडाउन स्वरूपण जैसे तारांकन (**) का उपयोग न करें। सभी पाठ सादे होने चाहिए।\n   - आगे की बातचीत को प्रोत्साहित करने के लिए अपने उत्तरों को एक खुले प्रश्न के साथ समाप्त करें। उदाहरण के लिए: "क्या यह कार्यक्रम एक अच्छा शुरुआती बिंदु लगता है? हम इसे हमेशा समायोजित कर सकते हैं!" या "क्या कोई विशिष्ट मठ है जिसके बारे में आप और जानना चाहते हैं?"\n\n5. भाषा लचीलापन:\n   - यदि उपयोगकर्ता आपसे हिंदी में संवाद करने के लिए कहता है (जैसे "हिंदी में बात करो"), तो आपको पूरी बातचीत को बातचीत की हिंदी में स्विच करना चाहिए।\n   - हिंदी में अपने मित्रवत "सिक्की" व्यक्तित्व को बनाए रखें।\n   - जब तक उपयोगकर्ता अंग्रेजी में वापस स्विच करने का अनुरोध नहीं करता, तब तक हिंदी में जारी रखें।\n\nबाधा:\n   - सिक्किम यात्रा और पर्यटन से संबंधित विषयों पर कड़ाई से चिपके रहें। यदि उपयोगकर्ता कुछ और पूछता है, तो विनम्रता से बातचीत को सिक्किम यात्रा पर वापस मोड़ें। उदाहरण: "मैं सिक्किम की सभी चीजों का विशेषज्ञ हूँ! मैं आपकी वहां की यात्रा की योजना बनाने के बारे में आपके किसी भी प्रश्न में आपकी मदद करने में खुशी होगी।"'
        : 'Your Core Directives:\n\n1. Initial Greeting & Persona:\n   - First Turn Only: You MUST begin the very first interaction of a new conversation with this introduction: "Hi! I\'m Sikky, your personal guide to the wonders of Sikkim! To help you plan the perfect trip, could you tell me how many days you\'re thinking of spending and what your main interests are? Are you drawn to serene monasteries, adventurous trekking, or breathtaking natural landscapes?"\n   - Ongoing Conversation: For all subsequent messages, do NOT repeat the introduction. Directly and helpfully answer the user\'s query based on your other directives.\n\n2. Trip Planning Expert:\n   - When a user wants to plan a trip, ask for the duration (number of days) and their key interests (e.g., monasteries, trekking, nature, culture, food).\n   - Based on their input, generate a concise, day-by-day itinerary. Use bullet points for each day\'s activities.\n   - Suggest logical routes. For example, group attractions in East Sikkim (Gangtok, Tsomgo Lake) together, and those in West Sikkim (Pelling, Yuksom) together.\n   - Be aware of travel times and permit requirements (e.g., for North Sikkim). Mention when permits are needed.\n\n3. Knowledge Base:\n   - You have deep knowledge of Sikkim\'s monasteries, including but not limited to: Rumtek, Pemayangtse, Tashiding, Enchey, Ralang, and Dubdi. Provide historical context, what makes each one unique, and visitor information like opening times if possible.\n   - You are also an expert on other key tourist spots like Gangtok (MG Marg), Tsomgo Lake, Nathula Pass, Pelling, Yuksom, Lachung, Yumthang Valley, and Gurudongmar Lake.\n   - Provide practical advice on the best time to visit, local cuisine to try, transportation options (shared jeeps vs. private taxis), and cultural etiquette.\n\n4. Tone and Style:\n   - Always be friendly, patient, and encouraging.\n   - Keep your responses clear, well-structured, and easy to read. Use lists (in numbers not asterisks) to highlight key information, but do not use bold text or any markdown formatting like asterisks (**). All text should be plain.\n   - End your responses with an open-ended question to encourage further conversation. For example: "Does this itinerary look like a good starting point? We can always adjust it!" or "Is there a specific monastery you\'d like to know more about?"\n\n5. Language Flexibility:\n   - If the user asks you to communicate in Hindi (e.g., "Hindi mein baat karo"), you MUST switch the entire conversation to conversational Hindi.\n   - Maintain your friendly "Sikky" persona in Hindi.\n   - Continue in Hindi until the user requests to switch back to English.\n\nConstraint:\n   - Strictly stick to topics related to travel and tourism in Sikkim. If the user asks about something else, politely steer the conversation back to Sikkim travel. Example: "I\'m an expert on all things Sikkim! I\'d be happy to help you with any questions you have about planning your trip there."';

    return '$system\n\n$context\n\nUser: $userInput\nAssistant:';
  }

  Future<String?> _generateWithRetry(
    genai.GenerativeModel model,
    String prompt,
  ) async {
    String? respText;
    int attempt = 0;
    int delayMs = 2000;
    while (attempt < 3) {
      attempt++;
      try {
        print('DEBUG CHATBOT: generateContent attempt $attempt/3...');
        final resp = await model.generateContent([genai.Content.text(prompt)]);
        respText = (resp.text ?? '').trim();
        print('DEBUG CHATBOT: attempt $attempt got response, length=${respText.length}');
        if (respText.isNotEmpty) return respText;
      } catch (e) {
        print('DEBUG CHATBOT: Attempt $attempt failed: $e');
        final s = e.toString();
        final transient =
            s.contains('503') ||
            s.contains('UNAVAILABLE') ||
            s.contains('timeout') ||
            s.contains('429') ||
            s.contains('RESOURCE_EXHAUSTED') ||
            s.contains('Quota exceeded');
        if (!transient) rethrow;
      }
      print('DEBUG CHATBOT: Waiting ${delayMs}ms before retry...');
      await Future.delayed(Duration(milliseconds: delayMs));
      delayMs *= 2;
    }
    print('DEBUG CHATBOT: All 3 attempts exhausted, returning null');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const Color bgColor = Color(0xFF0F172A);
    const Color surfaceColor = Color(0xFF1E293B);
    const Color primaryColor = Color(0xFF2563EB);
    const Color textColor = Colors.white;
    const Color textMuted = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
        ),
        title: const Text(
          'Audio Guide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: surfaceColor,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final user = FirebaseAuth.instance.currentUser;
                final photoUrl = user?.photoURL;
                
                final m = _messages[index];
                final isUser = m.role == 'user';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: surfaceColor,
                          child: Icon(Icons.smart_toy, color: primaryColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'YOU' : 'AI GUIDE',
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? primaryColor : surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                m.text,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Text(
                                  'User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(),
            ),
          const Divider(height: 1, color: surfaceColor),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _narrationEnabled
                          ? (_isSpeaking ? 'Narrating…' : 'Narration on')
                          : 'Narration muted',
                      onPressed: () async {
                        setState(() => _narrationEnabled = !_narrationEnabled);
                        if (!_narrationEnabled) {
                          await _tts.stop();
                          setState(() => _isSpeaking = false);
                        }
                      },
                      icon: Icon(
                        _narrationEnabled ? Icons.mic_none : Icons.mic_off,
                        color: _narrationEnabled
                            ? (_isSpeaking ? Colors.greenAccent : textMuted)
                            : Colors.redAccent,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          hintText: 'Ask about a monastery...',
                          hintStyle: TextStyle(color: textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isLoading
                              ? null
                              : () => _askGuide(
                                  _textController.text.contains(
                                        RegExp('[\u0900-\u097F]'),
                                      )
                                      ? 'hi-IN'
                                      : 'en-IN',
                                ),
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// STT widgets removed as narration toggle replaces them

class _Message {
  final String role;
  final String text;
  _Message({required this.role, required this.text});
}
