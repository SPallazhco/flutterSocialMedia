import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/screens/profile/post_detail_screen.dart';

class PostsGrid extends StatelessWidget {
  final String userId;

  const PostsGrid({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
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

  // Método para construir el widget de video (puedes personalizarlo según tus necesidades)
  Widget _buildVideo(String mediaUrl) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}
