import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/screens/profile/post_detail_screen.dart';
import 'package:social_media/widgets/common/info_card.dart';
import 'package:social_media/widgets/profile/video_player.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? userData;
  bool _isLoading = false;
  bool isFollowing = false; // Estado del botón seguir/dejar de seguir
  int followersCount = 0; // Número de seguidores
  int followingCount = 0; // Número de seguidores
  int postsCount = 0; // Número de publicaciones

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkIfFollowing();
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
          followersCount = ((userData?['followers'] as List?)?.length) ?? 0;
        });
      }

      // Obtener el número de usuarios seguidos
      final currentUserDoc = await _firestore
          .collection('Users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (currentUserDoc.exists) {
        setState(() {
          followingCount =
              ((currentUserDoc.data()?['following'] as List?)?.length) ?? 0;
        });
      }

      // Obtener el número de publicaciones
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        postsCount = postsSnapshot.docs.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener datos del usuario: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc =
          await _firestore.collection('Users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          followersCount = ((userData?['followers'] as List?)?.length) ?? 0;
        });
      }

      // Obtener el número de publicaciones
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        postsCount = postsSnapshot.docs.length;
      });
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

  Future<void> _checkIfFollowing() async {
    final currentUserId = _auth.currentUser!.uid;
    final userDoc =
        await _firestore.collection('Users').doc(widget.userId).get();

    if (userDoc.exists) {
      final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
      setState(() {
        isFollowing = followers.contains(currentUserId);
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _auth.currentUser!.uid;
    final userRef = _firestore.collection('Users').doc(widget.userId);
    final currentUserRef = _firestore.collection('Users').doc(currentUserId);

    if (isFollowing) {
      // Dejar de seguir: remover el ID del usuario actual de los seguidores del otro usuario
      await userRef.update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });

      // Remover el ID del usuario que estamos dejando de seguir de nuestros seguidos
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([widget.userId]),
      });

      setState(() {
        isFollowing = false;
        followersCount--;
      });
    } else {
      // Seguir: agregar el ID del usuario actual a los seguidores del otro usuario
      await userRef.update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      // Agregar el ID del usuario que estamos siguiendo a nuestros seguidos
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([widget.userId]),
      });

      setState(() {
        isFollowing = true;
        followersCount++;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InfoCard(title: "Seguidores", count: followersCount),
                          InfoCard(title: "Seguidos", count: followingCount),
                          InfoCard(title: "Publicaciones", count: postsCount),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (widget.userId != _auth.currentUser!.uid)
                        ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFollowing ? Colors.red : Colors.blue,
                          ),
                          child: Text(
                            isFollowing ? "Dejar de seguir" : "Seguir",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
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
            final doc = posts[index];
            final postData = doc.data() as Map<String, dynamic>;
            final mediaType = postData['mediaType'];
            final mediaUrl = postData['mediaUrl'];

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
                  Container(
                    color: Colors.grey[300],
                    child: mediaType == 'video'
                        ? _buildVideo(mediaUrl)
                        : Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
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
