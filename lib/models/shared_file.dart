/// Model representing a file that is being shared over the network.
class SharedFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final DateTime addedAt;

  SharedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Get file size in human readable format
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if this is a video file
  bool get isVideo => mimeType.startsWith('video/');

  /// Check if this is an audio file
  bool get isAudio => mimeType.startsWith('audio/');

  /// Check if this is an image file
  bool get isImage => mimeType.startsWith('image/');

  /// Convert to JSON for API response
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'formattedSize': formattedSize,
    'mimeType': mimeType,
    'isVideo': isVideo,
    'isAudio': isAudio,
    'isImage': isImage,
  };

  @override
  String toString() => 'SharedFile(name: $name, size: $formattedSize)';
}
