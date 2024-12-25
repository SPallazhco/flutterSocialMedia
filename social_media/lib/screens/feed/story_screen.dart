import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media/widgets/feed/story_video_player.dart';

class StoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> userStories;

  const StoryScreen({super.key, required this.userStories});

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  int currentIndex = 0;
  late PageController pageController;
  Timer? timer;
  double progress = 0.0;
  late int storyDurationMilliseconds;
  bool isVideo = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _startTimer();
  }

  void _startTimer({Duration? duration}) {
    timer?.cancel();
    final storyDuration =
        duration ?? const Duration(seconds: 5); // Duración predeterminada
    storyDurationMilliseconds = storyDuration.inMilliseconds;
    progress = 0.0;

    if (!isVideo) {
      timer = Timer.periodic(const Duration(milliseconds: 50), (Timer t) {
        setState(() {
          progress += 50 / storyDurationMilliseconds;
          if (progress >= 1.0) {
            _nextStory();
          }
        });
      });
    }
  }

  void _nextStory() {
    timer?.cancel();
    if (currentIndex < widget.userStories.length - 1) {
      setState(() {
        currentIndex++;
        progress = 0.0;
        isVideo = widget.userStories[currentIndex]['mediaType'] == 'video';
      });
      pageController.jumpToPage(currentIndex);

      final nextStory = widget.userStories[currentIndex];
      final storyDuration = nextStory['mediaType'] == 'video'
          ? Duration(seconds: nextStory['duration'] ?? 5)
          : const Duration(seconds: 5);
      _startTimer(duration: storyDuration);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    timer?.cancel();
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        progress = 0.0;
        isVideo = widget.userStories[currentIndex]['mediaType'] == 'video';
      });
      pageController.jumpToPage(currentIndex);

      final previousStory = widget.userStories[currentIndex];
      final storyDuration = previousStory['mediaType'] == 'video'
          ? Duration(seconds: previousStory['duration'] ?? 5)
          : const Duration(seconds: 5);
      _startTimer(duration: storyDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.userStories.length,
              itemBuilder: (context, index) {
                final story = widget.userStories[index];
                if (story['mediaType'] == 'image') {
                  isVideo = false;
                  return Image.network(
                    story['mediaUrl'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Error al cargar la imagen'),
                      );
                    },
                  );
                } else if (story['mediaType'] == 'video') {
                  isVideo = true;
                  return StoryVideoPlayer(
                    videoUrl: story['mediaUrl'],
                    onVideoFinished: _nextStory,
                    onProgressUpdate: (value) {
                      setState(() {
                        progress =
                            value; // Actualiza el progreso según el video
                      });
                    },
                    storyDuration: Duration(
                      seconds: story['duration'] ?? 5,
                    ),
                  );
                }
                return const Center(child: Text('Tipo de medio no soportado'));
              },
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Row(
                children: List.generate(
                  widget.userStories.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: LinearProgressIndicator(
                        value: index < currentIndex
                            ? 1.0
                            : (index == currentIndex ? progress : 0.0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == currentIndex
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        backgroundColor: Colors.grey.shade300,
                        minHeight: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
