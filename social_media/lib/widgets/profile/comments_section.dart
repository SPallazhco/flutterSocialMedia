import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsSection extends StatelessWidget {
  final String postId;

  const CommentsSection({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No hay comentarios aún');
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data() as Map<String, dynamic>;
            final createdAt = comment['createdAt']?.toDate();

            // Obtener la fecha en formato relativo
            final formattedDate = createdAt != null
                ? timeago.format(createdAt,
                    locale: 'es') // Ajuste al idioma español
                : 'Fecha desconocida';

            return ListTile(
              leading: const Icon(Icons.comment),
              title: Text(comment['text'] ?? ''),
              subtitle: Text(
                'Por: ${comment['username'] ?? 'Anónimo'} • $formattedDate',
              ),
            );
          },
        );
      },
    );
  }
}
