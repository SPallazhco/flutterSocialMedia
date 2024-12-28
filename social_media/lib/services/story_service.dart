import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media/models/select_media_model.dart';
import 'package:social_media/services/media_service.dart';

class StoryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> userData = {};

  Future<void> uploadStory(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      return; // Usuario no autenticado.
    }

    final SelectedMedia? selectedMedia =
        await MediaService.selectMedia(context);

    if (selectedMedia == null) {
      return; // Usuario no seleccionó nada.
    }

    try {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      } else {
        return; // Usuario no encontrado.
      }

      final File file = File(selectedMedia.file.path);
      final String fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${selectedMedia.file.name}';

      // Guardar la historia en una carpeta específica del usuario
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('stories') // Carpeta de historias
          .child(user.uid) // Carpeta por usuario (usando el uid)
          .child(fileName); // Nombre del archivo único

      // Subir el archivo
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      final String mediaUrl = await snapshot.ref.getDownloadURL();

      // Guardar la historia en Firestore
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'username': userData['username'],
        'mediaUrl': mediaUrl,
        'mediaType': selectedMedia.mediaType, // 'image' o 'video'
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Confirmación de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historia subida con éxito')),
        );
      }
    } catch (e) {
      // Manejo de errores
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la historia: $e')),
      );
    }
  }
}
