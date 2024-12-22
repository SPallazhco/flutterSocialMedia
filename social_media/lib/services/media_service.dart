import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:social_media/models/select_media_model.dart';

class MediaService {
  static Future<SelectedMedia?> selectMedia(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    return await showModalBottomSheet<SelectedMedia?>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Seleccionar Imagen'),
              onTap: () async {
                final selectedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                Navigator.pop(
                  context,
                  selectedFile != null
                      ? SelectedMedia(file: selectedFile, mediaType: 'image')
                      : null,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Seleccionar Video'),
              onTap: () async {
                final selectedFile = await picker.pickVideo(
                  source: ImageSource.gallery,
                  maxDuration: const Duration(seconds: 30),
                );
                Navigator.pop(
                  context,
                  selectedFile != null
                      ? SelectedMedia(file: selectedFile, mediaType: 'video')
                      : null,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
