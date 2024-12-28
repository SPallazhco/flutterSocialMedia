import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media/widgets/profile/comments_section.dart';
import 'package:video_player/video_player.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<String> likedUsernames = [];
  bool isLoadingLikes = true;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _fetchLikedUsernames();
    _initializeMedia();
  }

  Future<void> _fetchLikedUsernames() async {
    try {
      final likeIds = widget.post['likes'] ?? [];
      if (likeIds.isNotEmpty) {
        final userDocs = await _firestore
            .collection('Users')
            .where(FieldPath.documentId, whereIn: likeIds)
            .get();

        setState(() {
          likedUsernames = userDocs.docs
              .map((doc) => doc.data()['username'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching liked usernames: $e');
    } finally {
      setState(() {
        isLoadingLikes = false;
      });
    }
  }

  void _initializeMedia() {
    if (widget.post['mediaType'] == 'video') {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.post['mediaUrl']))
            ..initialize().then((_) {
              setState(() {});
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String postId = widget.post['postId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medio del post (imagen o video)
            Center(
              child: widget.post['mediaType'] == 'video'
                  ? _videoController != null &&
                          _videoController!.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // Video
                            AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            // Botón de reproducción/pausa
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                });
                              },
                              child: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator())
                  : Image.network(
                      widget.post['mediaUrl'],
                      fit: BoxFit.cover,
                      height: 250,
                    ),
            ),
            const SizedBox(height: 16),
            // Título o descripción del post
            Text(
              widget.post['description'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Información adicional (ejemplo: fecha de publicación)
            Text(
              'Publicado el: ${widget.post['createdAt']?.toDate().toString() ?? 'Desconocido'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            // Sección de likes
            isLoadingLikes
                ? const Center(child: CircularProgressIndicator())
                : likedUsernames.isEmpty
                    ? Row(
                        children: [
                          const Icon(Icons.thumb_up, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Nadie ha dado me gusta aún',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.thumb_up, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatLikedUsernames(likedUsernames),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
            const Divider(height: 32),
            // Sección de comentarios
            const Text(
              'Comentarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CommentsSection(postId: postId),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLikedUsernames(List<String> usernames) {
    if (usernames.length > 2) {
      return '${usernames[0]}, ${usernames[1]} y ${usernames.length - 2} más';
    } else if (usernames.length == 2) {
      return '${usernames[0]} y ${usernames[1]}';
    } else {
      return usernames.first;
    }
  }
}
