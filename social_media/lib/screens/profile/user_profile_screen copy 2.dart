import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/widgets/common/info_card.dart';
import 'package:social_media/widgets/posts/post_grid.dart';

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
  bool isFollowing = false;
  int followersCount = 0;
  int followingCount = 0;
  int postsCount = 0;

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
      // Obtener los datos del perfil del usuario
      final userDoc =
          await _firestore.collection('Users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          followersCount = ((userData?['followers'] as List?)?.length) ?? 0;
          followingCount = ((userData?['following'] as List?)?.length) ?? 0;
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
          SnackBar(content: Text('Error al obtener datos del usuario: $e')));
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
      final followers =
          List<Map<String, dynamic>>.from(userDoc.data()?['followers'] ?? []);
      setState(() {
        isFollowing =
            followers.any((follower) => follower['userId'] == currentUserId);
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _auth.currentUser!.uid;
    final userRef = _firestore.collection('Users').doc(widget.userId);
    final currentUserRef = _firestore.collection('Users').doc(currentUserId);

    try {
      if (isFollowing) {
        // Dejar de seguir
        final userDoc = await userRef.get();
        final currentUserDoc = await currentUserRef.get();

        if (userDoc.exists && currentUserDoc.exists) {
          final followers = List<Map<String, dynamic>>.from(
              userDoc.data()?['followers'] ?? []);
          final following = List<Map<String, dynamic>>.from(
              currentUserDoc.data()?['following'] ?? []);

          // Filtra y elimina los objetos correspondientes
          final updatedFollowers = followers
              .where((follower) => follower['userId'] != currentUserId)
              .toList();
          final updatedFollowing = following
              .where((followed) => followed['userId'] != widget.userId)
              .toList();

          await userRef.update({'followers': updatedFollowers});
          await currentUserRef.update({'following': updatedFollowing});

          // Actualiza contadores
          setState(() {
            isFollowing = false;
            followersCount--;
          });
        }
      } else {
        // Seguir
        final currentUserData = (await currentUserRef.get()).data();
        final targetUserData = (await userRef.get()).data();

        if (currentUserData != null && targetUserData != null) {
          final currentUserFollowData = {
            'userId': currentUserId,
            'lastname': currentUserData['lastname'],
            'profileImage': currentUserData['profileImage'],
            'username': currentUserData['username'],
            'followDate': Timestamp.now(),
          };

          final targetUserFollowData = {
            'userId': widget.userId,
            'lastname': targetUserData['lastname'],
            'profileImage': targetUserData['profileImage'],
            'username': targetUserData['username'],
            'followDate': Timestamp.now(),
          };

          await userRef.update({
            'followers': FieldValue.arrayUnion([currentUserFollowData]),
          });

          await currentUserRef.update({
            'following': FieldValue.arrayUnion([targetUserFollowData]),
          });

          // Actualiza contadores
          setState(() {
            isFollowing = true;
            followersCount++;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el seguimiento: $e')));
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
                  child: Text("No se encontró la información del usuario."),
                )
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
                      PostsGrid(userId: widget.userId),
                    ],
                  ),
                ),
    );
  }
}
