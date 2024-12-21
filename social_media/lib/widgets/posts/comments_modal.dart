import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsModal extends StatefulWidget {
  final String postId;

  const CommentsModal({super.key, required this.postId});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final commentsCollection = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments');

    return Padding(
      // Ajusta automáticamente el espacio del modal cuando el teclado aparece
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom, // Ajusta al teclado
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8, // 80% de la pantalla
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Barra indicadora en la parte superior
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
                      final commentData =
                          comment.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: commentData['userImage'] != null &&
                                  commentData['userImage'].isNotEmpty
                              ? NetworkImage(commentData['userImage'])
                              : null,
                          backgroundColor: Colors.blueAccent,
                          child: commentData['userImage'] == null ||
                                  commentData['userImage'].isEmpty
                              ? Text(
                                  commentData['username'][0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(commentData['username']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(commentData['text']),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    (commentData['likes'] ?? []).contains(
                                            FirebaseAuth
                                                .instance.currentUser?.uid)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: (commentData['likes'] ?? [])
                                            .contains(FirebaseAuth
                                                .instance.currentUser?.uid)
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      _toggleLike(comment.id, commentData),
                                ),
                                Text(
                                  '${(commentData['likes']?.length ?? 0)} likes',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                      decoration: const InputDecoration(
                        hintText: 'Agregar un comentario...',
                      ),
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
        'likes': [], // Inicializamos likes como lista vacía
      });

      _commentController.clear();
    }
  }

  Future<void> _toggleLike(
      String commentId, Map<String, dynamic> commentData) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    final likes = commentData['likes'] as List<dynamic>? ?? [];
    if (likes.contains(currentUser.uid)) {
      // Quitar like
      await commentRef.update({
        'likes': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      // Agregar like
      await commentRef.update({
        'likes': FieldValue.arrayUnion([currentUser.uid]),
      });
    }
  }
}
