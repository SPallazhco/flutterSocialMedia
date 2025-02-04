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

      // Obtener el número de seguidores y seguidos
      final followersSnapshot = await _firestore
          .collection('followers')
          .where('followedUserId', isEqualTo: widget.userId)
          .get();
      setState(() {
        followersCount = followersSnapshot.docs.length;
      });

      final followingSnapshot = await _firestore
          .collection('follows')
          .where('followerUserId', isEqualTo: widget.userId)
          .get();
      setState(() {
        followingCount = followingSnapshot.docs.length;
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

    final followsDoc = await _firestore
        .collection('follows')
        .where('followerUserId', isEqualTo: currentUserId)
        .where('followedUserId', isEqualTo: widget.userId)
        .get();

    setState(() {
      isFollowing = followsDoc.docs.isNotEmpty;
    });
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _auth.currentUser!.uid;
    final userRef = _firestore.collection('Users').doc(widget.userId);
    final currentUserRef = _firestore.collection('Users').doc(currentUserId);

    try {
      if (isFollowing) {
        // Dejar de seguir
        await _firestore
            .collection('follows')
            .where('followerUserId', isEqualTo: currentUserId)
            .where('followedUserId', isEqualTo: widget.userId)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        await _firestore
            .collection('followers')
            .where('followerUserId', isEqualTo: currentUserId)
            .where('followedUserId', isEqualTo: widget.userId)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        // Actualiza solo el contador de seguidores del usuario objetivo
        setState(() {
          isFollowing = false;
          followersCount--; // Decrecer solo los seguidores
        });
      } else {
        // Seguir
        final currentUserData = (await currentUserRef.get()).data();
        final targetUserData = (await userRef.get()).data();

        if (currentUserData != null && targetUserData != null) {
          final currentUserFollowData = {
            'name': currentUserData['username'],
            'lastname': currentUserData['lastname'],
            'profileImage': currentUserData['profileImage'],
            'followerUserId': currentUserId,
            'followedUserId': widget.userId,
          };

          final targetUserFollowData = {
            'name': targetUserData['username'],
            'lastname': targetUserData['lastname'],
            'profileImage': targetUserData['profileImage'],
            'followerUserId': currentUserId,
            'followedUserId': widget.userId,
          };

          // Agregar la relación de seguimiento a la colección "follows"
          await _firestore.collection('follows').add(currentUserFollowData);
          // Agregar la relación de seguidor a la colección "followers"
          await _firestore.collection('followers').add(targetUserFollowData);

          // Actualiza solo el contador de seguidores del usuario objetivo
          setState(() {
            isFollowing = true;
            followersCount++; // Aumentar solo los seguidores del usuario objetivo
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
