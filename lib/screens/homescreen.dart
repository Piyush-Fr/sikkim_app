import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sikkim_app/screens/chatbot.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.terrain, 'label': 'Mountains'},
    {'icon': Icons.account_balance, 'label': 'Monasteries'},
    {'icon': Icons.water, 'label': 'Lakes'},
  ];

  final List<Map<String, dynamic>> _featuredPlaces = [
    {
      'name': 'Tsomgo Lake',
      'image': 'assets/images/gangtok1.jpg',
      'rating': 4.8,
      'description':
          'A glacial lake at 12,400 feet, reflecting the changing colors of the sky.',
      'region': 'EAST SIKKIM',
      'fullDescription':
          'Nestled in the lap of the mighty Himalayas, Tsomgo Lake (also known as Changu Lake) is a glacial lake situated at an elevation of 12,400 feet. The lake is about 40 kilometers from Gangtok and remains frozen during winter. It is considered sacred by the local Sikkimese people and is surrounded by steep mountains on all sides.\n\nThe lake reflects different colors with the change of seasons and is absolutely stunning to behold. During winter, the lake is completely frozen and covered with snow, offering a magical sight. In spring, the surrounding area blooms with vibrant rhododendrons and wildflowers, making it a paradise for nature lovers and photographers.\n\nThe best time to visit is between May and August when the snow melts and the lake is accessible. Adventure enthusiasts can enjoy yak rides near the lake. The pristine beauty and spiritual significance of Tsomgo Lake make it one of the most visited tourist destinations in Sikkim.',
    },
    {
      'name': 'Rumtek Monastery',
      'image': 'assets/images/Rumtek1.jpg',
      'rating': 4.7,
      'description':
          'The largest monastery in Sikkim, a masterpiece of Tibetan architecture.',
      'region': 'GANGTOK',
      'fullDescription':
          'Perched on a verdant hilltop 24 kilometers from Gangtok, the Rumtek Monastery, also known as the Dharma Chakra Centre, stands as a majestic beacon of Tibetan Buddhism in Sikkim. A replica of the Tsurphu Monastery in Tibet, Rumtek serves as the seat of the Karmapa, the head of the Karma Kagyu lineage, and offers tourists a profound glimpse into a rich spiritual and cultural heritage.\n\nUpon arrival, visitors are greeted by the monastery\'s stunning traditional Tibetan architecture. The vibrant murals, intricate woodwork, and the golden roof of the main temple create a visually captivating experience. Inside, the grand prayer hall is adorned with exquisite thangkas (silk paintings), ancient statutes, and a palpable aura of peace. A significant highlight for any visitor is the Golden Stupa, a magnificent reliquary containing the sacred relics of the 16th Karmapa.\n\nThe best time to visit Rumtek is from March to May and from October to December when the weather is pleasant and the skies are clear, affording breathtaking views of the surrounding valleys and the distant Himalayan peaks.',
    },
    {
      'name': 'Yuksom',
      'image': 'assets/images/Yuksom.jpg',
      'rating': 4.6,
      'description':
          'The historic first capital of Sikkim, gateway to Kanchenjunga treks.',
      'region': 'WEST SIKKIM',
      'fullDescription':
          'Nestled in the pristine wilderness of West Sikkim, Yuksom is a quaint and historically significant village that beckons travelers with its serene landscapes, rich cultural heritage, and legendary past. Often referred to as the "Gateway to Kanchenjunga," this idyllic hamlet was the first capital of Sikkim.\n\nYuksom\'s most profound claim to fame is its role as the coronation site of the first Chogyal (king) of Sikkim in 1642. The throne, made of stone and set amidst a grove of ancient cypress trees at Norbugang Coronation Throne, remains a revered site of pilgrimage. The historic Dubdi Monastery, one of the oldest in Sikkim, is perched on a hilltop above Yuksom, offering panoramic views.\n\nBeyond its historical and religious sites, Yuksom is the starting point for some of the most spectacular treks in the Himalayas, including the renowned Dzongri-Goecha La trek. The best time to visit is from March to June and from September to November.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        toolbarHeight: 60,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 26),
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text(
          'Sikkim Tourism',
          style: TextStyle(
            color: Color(0xFF4A90FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {},
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1A1F36),
                backgroundImage:
                    FirebaseAuth.instance.currentUser?.photoURL != null
                        ? NetworkImage(
                            FirebaseAuth.instance.currentUser!.photoURL!)
                        : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(Icons.person_outline,
                        color: Colors.white70, size: 22)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildHeroBanner(),
            const SizedBox(height: 20),
            _buildCategoryChips(),
            const SizedBox(height: 28),
            _buildFeaturedPlacesSection(),
            const SizedBox(height: 28),
            _buildProTipCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Hero Banner ───────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              'assets/images/gangtok1.jpg',
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0A0E21).withOpacity(0.4),
                    const Color(0xFF0A0E21).withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'WELCOME TO PARADISE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Heading
                  const Text(
                    'Explore the Magic of\nSikkim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Text(
                    'Experience breathtaking landscapes and\nvibrant culture in the heart of the\nHimalayas.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4A90FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4A90FF)
                      : Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Featured Places Section ───────────────────────────────────────────
  Widget _buildFeaturedPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Places',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Must-visit iconic destinations',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF4A90FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredPlaces.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _buildPlaceCard(_featuredPlaces[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return GestureDetector(
      onTap: () {
        _showPlaceDetails(
          title: place['name'] as String,
          imagePath: place['image'] as String,
          description: place['fullDescription'] as String,
        );
      },
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: const Color(0xFF141829),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                place['image'] as String,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB800), size: 16),
                          const SizedBox(width: 3),
                          Text(
                            '${place['rating']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    place['description'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Region tag
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF4A90FF), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        place['region'] as String,
                        style: const TextStyle(
                          color: Color(0xFF4A90FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pro Tip Card ──────────────────────────────────────────────────────
  Widget _buildProTipCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFF4A90FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Tip: Best Time to Visit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Visit between March and May for blooming rhododendrons and clear skies.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Place Details Bottom Sheet ────────────────────────────────────────
  void _showPlaceDetails({
    required String title,
    required String imagePath,
    required String description,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E21).withOpacity(0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        imagePath,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close,
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.4,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatbotWithQuery extends StatefulWidget {
  final String initialQuery;

  const ChatbotWithQuery({super.key, required this.initialQuery});

  @override
  State<ChatbotWithQuery> createState() => _ChatbotWithQueryState();
}

class _ChatbotWithQueryState extends State<ChatbotWithQuery> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendInitialQuery();
      });
    });
  }

  void _sendInitialQuery() {
    // Handled by the Chatbot widget itself
  }

  @override
  Widget build(BuildContext context) {
    return Chatbot(initialQuery: widget.initialQuery);
  }
}
