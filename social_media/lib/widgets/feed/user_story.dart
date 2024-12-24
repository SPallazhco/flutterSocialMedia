import 'dart:async';

import 'package:flutter/material.dart';
import 'package:social_media/widgets/feed/story_video_player.dart';

class StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> userStories;

  const StoryViewer({super.key, required this.userStories});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  int currentIndex = 0;
  late PageController pageController;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () {
              // Avanzar a la siguiente historia al hacer clic en la pantalla
              if (currentIndex < widget.userStories.length - 1) {
                currentIndex++;
                pageController.jumpToPage(currentIndex);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: PageView.builder(
              controller: pageController,
              itemCount: widget.userStories.length,
              itemBuilder: (context, index) {
                final story = widget.userStories[index];
                if (story['mediaType'] == 'image') {
                  if (timer == null || !timer!.isActive) {
                    timer = Timer(const Duration(seconds: 10), () {
                      if (currentIndex < widget.userStories.length - 1) {
                        currentIndex++;
                        pageController.jumpToPage(currentIndex);
                      } else {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                  return Image.network(
                    story['mediaUrl'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Text('Error al cargar la imagen'));
                    },
                  );
                } else if (story['mediaType'] == 'video') {
                  return StoryVideoPlayer(videoUrl: story['mediaUrl']);
                }
                return const Center(child: Text('Tipo de medio no soportado'));
              },
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () {
                timer?.cancel();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
