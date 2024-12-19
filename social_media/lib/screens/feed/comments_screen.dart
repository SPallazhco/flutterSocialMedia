import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final commentsCollection = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentsCollection.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentData = comment.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: commentData['userImage'] != null &&
                                commentData['userImage'].isNotEmpty
                            ? NetworkImage(commentData['userImage'])
                            : null,
                        backgroundColor:
                            Colors.blueAccent, // Fondo para las iniciales
                        child: commentData['userImage'] == null ||
                                commentData['userImage'].isEmpty
                            ? Text(
                                commentData['username'][0]
                                    .toUpperCase(), // Inicial del username
                                style: const TextStyle(color: Colors.white),
                              )
                            : null, // Si hay imagen, no mostramos texto
                      ),
                      title: Text(commentData['username']),
                      subtitle: Text(commentData['text']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration:
                        const InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _addComment(commentsCollection),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(CollectionReference commentsCollection) async {
    if (_commentController.text.trim().isEmpty) return;
    final userId = _auth.currentUser?.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;

      await commentsCollection.add({
        'text': _commentController.text.trim(),
        'userId': userId,
        'username': userData['username'],
        'userImage': userData['profileImage'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    }
  }
}
