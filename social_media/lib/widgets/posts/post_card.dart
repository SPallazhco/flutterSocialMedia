import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostCard({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLiked = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();

    // Inicializar VideoPlayer si es un video
    if (widget.postData['mediaType'] == 'video') {
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.postData['mediaUrl']))
        ..initialize().then((_) {
          setState(() {}); // Refrescar para mostrar el video inicializado
        })
        ..setLooping(true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose(); // Liberar controlador de video
    super.dispose();
  }

  void _checkIfLiked() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final likes = widget.postData['likes'] as List<dynamic>? ?? [];
    setState(() {
      isLiked = likes.contains(currentUser.uid);
    });
  }

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

  String _getTimeAgo(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return timeago.format(dateTime);
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    final userDoc = await _firestore.collection('Users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(widget.postData['userId']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey,
                  ),
                  title: Text('Loading...'),
                );
              }

              final userData = snapshot.data!;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: userData['profileImage'] != null &&
                          userData['profileImage'].isNotEmpty
                      ? NetworkImage(userData['profileImage'])
                      : null,
                  child: userData['profileImage'] == null ||
                          userData['profileImage'].isEmpty
                      ? Text(
                          userData['username'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(userData['username']),
                subtitle: Text(
                  _getTimeAgo(widget.postData['createdAt']),
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
          // Contenido multimedia (imagen o video)
          if (widget.postData['mediaType'] == 'image')
            Image.network(
              widget.postData['mediaUrl'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.red),
              ),
            )
          else if (_videoController != null &&
              _videoController!.value.isInitialized)
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  if (!_videoController!.value.isPlaying)
                    const Icon(
                      Icons.play_circle_fill,
                      size: 64,
                      color: Colors.white,
                    ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
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
                  Navigator.pushNamed(
                    context,
                    'comments',
                    arguments: widget.postId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
