import 'package:video_thumbnail/video_thumbnail.dart';

Future<String?> getThumbnailUrl(Map<String, dynamic> storyData) async {
  if (storyData['mediaType'] == 'image') {
    return storyData['mediaUrl']; // URL directa para imágenes.
  } else if (storyData['mediaType'] == 'video') {
    try {
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: storyData['mediaUrl'],
        imageFormat: ImageFormat.JPEG,
        maxHeight: 120, // Altura máxima de la miniatura.
        quality: 75,
      );
      return thumbnailPath; // Devolvemos la ruta local del archivo.
    } catch (e) {
      return null; // Manejo de errores.
    }
  }
  return null;
}
