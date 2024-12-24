import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/services/get_thumbnail_url_service.dart';
import 'package:social_media/widgets/feed/user_story.dart';
import 'package:social_media/widgets/posts/post_card.dart';
import 'package:social_media/services/story_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Historias
          SizedBox(
            height: 120, // Espacio para las historias
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('stories')
                  .where('createdAt',
                      isGreaterThan: Timestamp.fromDate(
                          DateTime.now().subtract(const Duration(hours: 24))))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stories = snapshot.data?.docs ?? [];

                // Agrupar las historias por usuario
                Map<String, List<Map<String, dynamic>>> groupedStories = {};

                for (var story in stories) {
                  final storyData = story.data() as Map<String, dynamic>;
                  final userId = storyData['userId'];

                  if (groupedStories.containsKey(userId)) {
                    groupedStories[userId]?.add(storyData);
                  } else {
                    groupedStories[userId] = [storyData];
                  }
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupedStories.keys.length +
                      1, // +1 para el usuario actual
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildMyStory();
                    }

                    final userId = groupedStories.keys.elementAt(index - 1);
                    final userStories = groupedStories[userId]!;

                    return _buildStoryTile(userStories, userId);
                  },
                );
              },
            ),
          ),
          const Divider(),
          // Feed de publicaciones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data?.docs ?? [];

                if (posts.isEmpty) {
                  return const Center(
                      child: Text("No hay publicaciones disponibles."));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postId = post.id;
                    final postData = post.data() as Map<String, dynamic>;

                    return PostCard(
                      postId: postId,
                      postData: postData,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStory() {
    return GestureDetector(
      onTap: () => StoryService().uploadStory(context),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text('Tu historia', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryTile(
      List<Map<String, dynamic>> userStories, String userId) {
    return GestureDetector(
      onTap: () {
        _viewStories(userStories);
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
        child: Column(
          children: [
            FutureBuilder<String?>(
              future: getThumbnailUrl(userStories[
                  0]), // Solo obtenemos la miniatura de la primera historia
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 30,
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.error, color: Colors.white),
                  );
                }

                final thumbnailPath = snapshot.data!;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: thumbnailPath.startsWith('http')
                          ? NetworkImage(thumbnailPath) // URL de red
                          : FileImage(File(thumbnailPath)), // Ruta local
                    ),
                    if (userStories
                        .any((story) => story['mediaType'] == 'video'))
                      const Icon(Icons.play_circle_filled,
                          size: 30, color: Colors.white),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              userStories[0][
                  'username'], // Usamos el primer nombre de usuario en las historias agrupadas
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _viewStories(List<Map<String, dynamic>> userStories) {
    showDialog(
      context: context,
      builder: (context) {
        return StoryViewer(userStories: userStories);
      },
    );
  }
}
