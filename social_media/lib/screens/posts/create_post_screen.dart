import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _mediaFile;
  bool isVideo = false;
  bool isLoading = false;

  VideoPlayerController? _videoController;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Future<void> _selectMedia() async {
    final picker = ImagePicker();
    try {
      final mediaType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar tipo de archivo'),
          content: const Text('¿Qué tipo de archivo deseas cargar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'image'),
              child: const Text('Imagen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'video'),
              child: const Text('Video'),
            ),
          ],
        ),
      );

      if (mediaType == null) return;

      XFile? pickedFile;

      if (mediaType == 'image') {
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1080,
        );
        isVideo = false;
        _disposeVideoController();
      } else if (mediaType == 'video') {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
        isVideo = true;
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
        });

        if (isVideo) {
          _initializeVideoController();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  void _initializeVideoController() {
    if (_mediaFile != null) {
      _videoController = VideoPlayerController.file(_mediaFile!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _uploadPost() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona una imagen o video.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw 'Usuario no autenticado.';
      }

      final String userFolder = currentUser.uid;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef =
          _storage.ref().child('posts/$userFolder/$fileName');
      final UploadTask uploadTask = storageRef.putFile(_mediaFile!);

      final TaskSnapshot snapshot = await uploadTask;
      final String mediaUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('posts').add({
        'userId': currentUser.uid,
        'mediaUrl': mediaUrl,
        'mediaType': isVideo ? 'video' : 'image',
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Post creado con éxito!')),
      );

      setState(() {
        _mediaFile = null;
        _descriptionController.clear();
        _locationController.clear();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el post: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Publicación'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _selectMedia,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _mediaFile == null
                          ? const Center(
                              child: Text(
                                'Seleccionar imagen o video',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? _videoController != null &&
                                          _videoController!.value.isInitialized
                                      ? AspectRatio(
                                          aspectRatio: _videoController!
                                              .value.aspectRatio,
                                          child: VideoPlayer(_videoController!),
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                  : Image.file(
                                      _mediaFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _uploadPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Publicar'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const LinearProgressIndicator(), // Barra de progreso
        ],
      ),
    );
  }
}
