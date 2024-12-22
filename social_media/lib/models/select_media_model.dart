import 'package:image_picker/image_picker.dart';

class SelectedMedia {
  final XFile file;
  final String mediaType; // 'image' o 'video'

  SelectedMedia({required this.file, required this.mediaType});
}
