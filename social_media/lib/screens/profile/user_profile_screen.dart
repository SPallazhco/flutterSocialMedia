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
  bool isFollowing = false; // Estado del botón seguir/dejar de seguir
  int followersCount = 0; // Número de seguidores
  int followingCount = 0; // Número de seguidos
  int postsCount = 0; // Número de publicaciones

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkIfFollowing();
  }

  // Obtener datos del usuario (perfil, seguidores, seguidos, publicaciones)
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener los datos del perfil del usuario objetivo
      final userDoc =
          await _firestore.collection('Users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          followersCount = ((userData?['followers'] as List?)?.length) ?? 0;
        });
      }

      // Obtener el número de usuarios seguidos por el usuario actual
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
          SnackBar(content: Text('Error al obtener datos del usuario: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verificar si el usuario actual está siguiendo al usuario objetivo
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

  // Lógica de seguir o dejar de seguir
  Future<void> _toggleFollow() async {
    final currentUserId = _auth.currentUser!.uid;
    final userRef = _firestore.collection('Users').doc(widget.userId);
    final currentUserRef = _firestore.collection('Users').doc(currentUserId);

    setState(() {
      _isLoading = true;
    });

    try {
      if (isFollowing) {
        // Dejar de seguir: eliminar el ID del usuario actual de los seguidores del otro usuario
        await userRef.update({
          'followers': FieldValue.arrayRemove([currentUserId]),
        });

        // Eliminar el ID del usuario que estamos dejando de seguir de nuestros seguidos
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el seguimiento: $e')));
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
