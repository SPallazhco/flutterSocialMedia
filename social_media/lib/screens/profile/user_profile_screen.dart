import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media/screens/profile/post_detail_screen.dart';
import 'package:social_media/widgets/profile/video_player.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc =
          await _firestore.collection('Users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener datos del usuario: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil del Usuario"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(
                  child: Text("No se encontró la información del usuario."))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userData!['profileImage'] != null
                            ? NetworkImage(userData!['profileImage'])
                            : null,
                        child: userData!['profileImage'] == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${userData!['username']} ${userData!['lastname']}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData!['bio'] ?? "Sin biografía",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text(
                        "Publicaciones",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildposts(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildposts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Este usuario aún no ha publicado nada.",
              textAlign: TextAlign.center,
            ),
          );
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            // Extraer datos del documento
            final doc = posts[index];
            final postData = doc.data() as Map<String, dynamic>;
            final mediaType = postData['mediaType'];
            final mediaUrl = postData['mediaUrl'];

            // Agregar el postId a los datos
            postData['postId'] = doc.id;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: postData),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fondo con imagen o video
                  Container(
                    color: Colors.grey[300],
                    child: mediaType == 'video'
                        ? _buildVideo(mediaUrl)
                        : Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                  // Ícono para diferenciar videos
                  if (mediaType == 'video')
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideo(String videoUrl) {
    return VideoPlayerWidget(videoUrl: videoUrl);
  }
}
