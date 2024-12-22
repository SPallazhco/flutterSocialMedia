import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/services/get_thumbnail_url_service.dart';
import 'package:social_media/widgets/feed/story_video_player.dart';
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
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1, // +1 para el usuario actual
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildMyStory();
                    }
                    final story = stories[index - 1];
                    final storyData = story.data() as Map<String, dynamic>;

                    return _buildStoryTile(storyData);
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

  Widget _buildStoryTile(Map<String, dynamic> storyData) {
    return GestureDetector(
      onTap: () {
        _viewStory(storyData);
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
        child: Column(
          children: [
            FutureBuilder<String?>(
              future: getThumbnailUrl(storyData),
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
                          ? NetworkImage(thumbnailPath) // URL de red.
                          : FileImage(File(thumbnailPath)), // Ruta local.
                    ),
                    if (storyData['mediaType'] == 'video')
                      const Icon(Icons.play_circle_filled,
                          size: 30, color: Colors.white),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              storyData['username'],
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _viewStory(Map<String, dynamic> storyData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              if (storyData['mediaType'] == 'image')
                Image.network(
                  storyData['mediaUrl'],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                        child: Text('Error al cargar la imagen'));
                  },
                )
              else if (storyData['mediaType'] == 'video')
                StoryVideoPlayer(videoUrl: storyData['mediaUrl']),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
