import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sikkim_app/screens/chatbot.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 80,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hi, ${FirebaseAuth.instance.currentUser?.displayName?.split(' ')[0] ?? 'Traveler'}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
              backgroundImage:
                  FirebaseAuth.instance.currentUser?.photoURL != null
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : null,
              child: FirebaseAuth.instance.currentUser?.photoURL == null
                  ? Text(
                      FirebaseAuth
                                  .instance
                                  .currentUser
                                  ?.displayName
                                  ?.isNotEmpty ==
                              true
                          ? FirebaseAuth.instance.currentUser!.displayName![0]
                                .toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promotional Banner
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.landscape,
                      color: Colors.blue[400],
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You're getting best Advice and Information about Sikkim",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Explore Sikkim",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.blue[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Your trips section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Your trips",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Trip Cards
            Container(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTripCard(
                    "Gangtok",
                    "Wed, Oct 1 – Thu, Oct 2",
                    "assets/images/gangtok1.jpg",
                    "1 view",
                    "6 saves",
                  ),
                  SizedBox(width: 15),
                  _buildTripCard(
                    "Rumtek",
                    "Fri, Oct 4 – Sat, Oct 5",
                    "assets/images/Rumtek1.jpg",
                    "2 views",
                    "8 saves",
                  ),
                  SizedBox(width: 15),
                  _buildTripCard(
                    "Yuksom",
                    "Sun, Oct 6 – Mon, Oct 7",
                    "assets/images/Yuksom.jpg",
                    "3 views",
                    "12 saves",
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Recent searches section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Your recent searches",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Recent searches list
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildRecentSearchItem(
                    "Gangtok monasteries",
                    Icons.location_on,
                    "Gangtok monasteries",
                  ),
                  _buildRecentSearchItem(
                    "Sikkim trekking routes",
                    Icons.hiking,
                    "Sikkim trekking routes",
                  ),
                  _buildRecentSearchItem(
                    "Pelling sightseeing",
                    Icons.visibility,
                    "Pelling sightseeing",
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(
    String title,
    String dates,
    String imagePath,
    String views,
    String saves,
  ) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              imagePath,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.home, size: 14, color: Colors.grey[400]),
                    SizedBox(width: 4),
                    Text(
                      views,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(width: 15),
                    Icon(Icons.favorite, size: 14, color: Colors.grey[400]),
                    SizedBox(width: 4),
                    Text(
                      saves,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String text, IconData icon, String query) {
    return GestureDetector(
      onTap: () {
        // Navigate to chatbot with the search query
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotWithQuery(initialQuery: query),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[500]),
          ],
        ),
      ),
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
    // Send the initial query after a short delay to ensure the chatbot is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _sendInitialQuery();
      });
    });
  }

  void _sendInitialQuery() {
    // This will be handled by the Chatbot widget itself
    // We'll pass the query through a callback or state management
  }

  @override
  Widget build(BuildContext context) {
    return Chatbot(initialQuery: widget.initialQuery);
  }
}
