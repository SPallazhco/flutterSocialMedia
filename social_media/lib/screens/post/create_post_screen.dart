import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Variables necesarias
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _mediaFile; // Archivo de imagen o video
  bool isVideo = false; // Tipo de archivo seleccionado
  bool isLoading = false; // Indicador de carga

  // Controladores de texto
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Método para seleccionar imagen o video
  Future<void> _selectMedia() async {
    final picker = ImagePicker();

    try {
      // Diálogo para elegir el tipo de archivo
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

      // Lógica para seleccionar el archivo según el tipo
      if (mediaType == 'image') {
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1080,
        );
        isVideo = false;
      } else if (mediaType == 'video') {
        pickedFile = await picker.pickVideo(
          source: ImageSource.gallery,
        );
        isVideo = true;
      }

      // Guardar el archivo seleccionado
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  // Método para subir el post
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

      // Crear carpeta del usuario en Firebase Storage
      final String userFolder = currentUser.uid;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef =
          _storage.ref().child('posts/$userFolder/$fileName');
      final UploadTask uploadTask = storageRef.putFile(_mediaFile!);

      // Obtener URL del archivo subido
      final TaskSnapshot snapshot = await uploadTask;
      final String mediaUrl = await snapshot.ref.getDownloadURL();

      // Guardar datos del post en Firestore
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

      // Limpiar campos y estado
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de medios
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
                              ? const Icon(
                                  Icons.videocam,
                                  size: 80,
                                  color: Colors.blueAccent,
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
              // Campo de descripción
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Campo de ubicación
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              // Botón para subir el post
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
    );
  }
}
