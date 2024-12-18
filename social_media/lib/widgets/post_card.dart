import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostCard({
    Key? key,
    required this.postId,
    required this.postData,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  // Verificar si el usuario actual ya dio "like"
  void _checkIfLiked() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final likes = widget.postData['likes'] as List<dynamic>? ?? [];
    setState(() {
      isLiked = likes.contains(currentUser.uid);
    });
  }

  // Manejar "like" en una publicación
  Future<void> _toggleLike() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final likes = widget.postData['likes'] as List<dynamic>? ?? [];

    setState(() {
      if (isLiked) {
        likes.remove(currentUser.uid);
      } else {
        likes.add(currentUser.uid);
      }
      isLiked = !isLiked;
    });

    await _firestore.collection('posts').doc(widget.postId).update({
      'likes': likes,
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con usuario
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(
                widget.postData['userId'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(widget.postData['userId']),
            subtitle:
                Text(widget.postData['location'] ?? 'Ubicación no disponible'),
          ),
          // Imagen o video de la publicación
          if (widget.postData['mediaType'] == 'image')
            Image.network(widget.postData['mediaUrl'], fit: BoxFit.cover)
          else
            Container(
              height: 200,
              color: Colors.black12,
              child: const Center(
                child: Icon(Icons.videocam, size: 60, color: Colors.grey),
              ),
            ),
          // Descripción
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.postData['description'] ?? ''),
          ),
          // Acciones
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleLike,
              ),
              Text("${widget.postData['likes']?.length ?? 0} likes"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => CommentsScreen(postId: widget.postId),
                  //   ),
                  // );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
