import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/screens/profile/post_detail_screen.dart';
import 'package:social_media/widgets/profile/video_player.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Obtener datos del usuario
        final userDoc =
            await _firestore.collection('Users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data();
          });
        } else {
          throw 'Usuario no encontrado';
        }

        // Obtener publicaciones del usuario
        final postsQuery = await _firestore
            .collection('posts')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .get();

        // Agregar el postId a cada post
        setState(() {
          userPosts = postsQuery.docs.map((doc) {
            final data = doc.data();
            data['postId'] = doc.id; // Agregar el ID del documento
            return data;
          }).toList();
        });
      }
      setState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener información: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al obtener información.\nPor favor, intenta más tarde.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Stack(
                    children: [
                      // Contenido principal
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          // Información del usuario
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Imagen de perfil
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: userData?['profileImage'] !=
                                          null
                                      ? NetworkImage(userData!['profileImage'])
                                      : null,
                                  child: userData?['profileImage'] == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                // Nombre y apellido
                                Text(
                                  "${userData?['username'] ?? 'Nombre'} ${userData?['lastname'] ?? 'Apellido'}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Correo electrónico
                                Text(
                                  userData?['email'] ?? 'Correo no disponible',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const Divider(height: 32),
                              ],
                            ),
                          ),
                          // Sección de publicaciones
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Publicaciones",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                userPosts.isEmpty
                                    ? const Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.photo_library_outlined,
                                              size: 80,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "Aún no hay publicaciones",
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 4.0,
                                          mainAxisSpacing: 4.0,
                                        ),
                                        itemCount: userPosts.length,
                                        itemBuilder: (context, index) {
                                          final post = userPosts[index];
                                          final mediaType = post['mediaType'];
                                          final mediaUrl = post['mediaUrl'];

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PostDetailScreen(
                                                          post: post),
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
                                                  Positioned(
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
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Botón de configuración flotante en la parte superior derecha
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.black),
                          onPressed: () {
                            Navigator.pushNamed(context, 'settings');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVideo(String videoUrl) {
    return VideoPlayerWidget(videoUrl: videoUrl);
  }
}
