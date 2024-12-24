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
  double progress = 0.0; // Para controlar la barra de progreso
  late Duration storyDuration;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    storyDuration =
        Duration(seconds: 10); // Duración de la historia (puedes cambiarla)
  }

  // Función para avanzar al siguiente estado
  void _nextStory() {
    if (currentIndex < widget.userStories.length - 1) {
      setState(() {
        currentIndex++;
        progress = 0.0; // Resetear progreso
      });
      pageController
          .jumpToPage(currentIndex); // Avanzamos a la siguiente historia
    } else {
      Navigator.of(context).pop(); // Volver al feed si no hay más historias
    }
  }

  // Función para actualizar el progreso de la barra de progreso
  void _updateProgress(double newProgress) {
    setState(() {
      progress = newProgress;
    });
  }

  // Controla el avance automático en las imágenes
  void _handleImageTimeout() {
    if (timer == null || !timer!.isActive) {
      timer = Timer(storyDuration, _nextStory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _nextStory(); // Avanzar a la siguiente historia al hacer clic en la pantalla
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: widget.userStories.length,
              itemBuilder: (context, index) {
                final story = widget.userStories[index];
                if (story['mediaType'] == 'image') {
                  _handleImageTimeout(); // Inicia el temporizador para imágenes
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
                  return StoryVideoPlayer(
                    videoUrl: story['mediaUrl'],
                    onVideoFinished:
                        _nextStory, // Avanzamos a la siguiente historia cuando el video termina
                    onProgressUpdate:
                        _updateProgress, // Actualización del progreso de la barra
                    storyDuration:
                        storyDuration, // Duración de la historia para sincronizar el progreso
                  );
                }
                return const Center(child: Text('Tipo de medio no soportado'));
              },
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                  progress = 0.0; // Resetear progreso al cambiar de página
                });
              },
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.userStories.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            index == currentIndex ? Colors.white : Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progress,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                backgroundColor: Colors.transparent,
                minHeight: 3,
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
