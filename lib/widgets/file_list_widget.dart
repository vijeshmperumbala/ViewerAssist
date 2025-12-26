import 'package:flutter/material.dart';
import '../models/shared_file.dart';

/// Widget to display a list of shared files.
class FileListWidget extends StatelessWidget {
  final List<SharedFile> files;
  final Function(SharedFile)? onRemove;
  final bool showRemoveButton;

  const FileListWidget({
    super.key,
    required this.files,
    this.onRemove,
    this.showRemoveButton = true,
  });

  IconData _getFileIcon(SharedFile file) {
    if (file.isVideo) return Icons.video_file;
    if (file.isAudio) return Icons.audio_file;
    if (file.isImage) return Icons.image;
    return Icons.insert_drive_file;
  }

  Color _getIconColor(SharedFile file) {
    if (file.isVideo) return const Color(0xFF00d2ff);
    if (file.isAudio) return const Color(0xFFff6b6b);
    if (file.isImage) return const Color(0xFF4ecdc4);
    return const Color(0xFFa8a8a8);
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No files selected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add files',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final file = files[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getIconColor(file).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getFileIcon(file),
                color: _getIconColor(file),
                size: 28,
              ),
            ),
            title: Text(
              file.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              file.formattedSize,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            trailing: showRemoveButton && onRemove != null
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () => onRemove!(file),
                  )
                : null,
          ),
        );
      },
    );
  }
}
