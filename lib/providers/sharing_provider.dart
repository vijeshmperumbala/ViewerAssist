import 'package:flutter/foundation.dart';
import '../models/shared_file.dart';
import '../services/file_server.dart';
import '../services/network_service.dart';
import '../services/file_picker_service.dart';

/// Provider for managing the file sharing state.
class SharingProvider extends ChangeNotifier {
  final FileServer _fileServer = FileServer();
  final NetworkService _networkService = NetworkService();
  final FilePickerService _filePickerService = FilePickerService();

  List<SharedFile> _selectedFiles = [];
  String? _ipAddress;
  int _port = NetworkService.defaultPort;
  bool _isSharing = false;
  String? _errorMessage;

  // Getters
  List<SharedFile> get selectedFiles => List.unmodifiable(_selectedFiles);
  String? get ipAddress => _ipAddress;
  int get port => _port;
  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;
  String get shareUrl => _ipAddress != null ? 'http://$_ipAddress:$_port' : '';

  /// Pick files to share
  Future<void> pickFiles() async {
    try {
      _errorMessage = null;
      final files = await _filePickerService.pickFiles();
      if (files.isNotEmpty) {
        _selectedFiles.addAll(files);
        _fileServer.addFiles(files);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick files: $e';
      notifyListeners();
    }
  }

  /// Remove a file from the selection
  void removeFile(SharedFile file) {
    _selectedFiles.removeWhere((f) => f.id == file.id);
    _fileServer.removeFile(file.id);
    notifyListeners();
  }

  /// Clear all selected files
  void clearFiles() {
    _selectedFiles.clear();
    _fileServer.clearFiles();
    notifyListeners();
  }

  /// Start sharing files over the network
  Future<bool> startSharing() async {
    try {
      _errorMessage = null;

      if (_selectedFiles.isEmpty) {
        _errorMessage = 'Please select files to share first';
        notifyListeners();
        return false;
      }

      // Check WiFi connection
      final isConnected = await _networkService.isConnectedToWifi();
      if (!isConnected) {
        _errorMessage = 'Please connect to a WiFi network';
        notifyListeners();
        return false;
      }

      // Get IP address
      _ipAddress = await _networkService.getWifiIPAddress();
      if (_ipAddress == null) {
        _errorMessage = 'Could not get WiFi IP address';
        notifyListeners();
        return false;
      }

      // Find available port
      _port = await _networkService.findAvailablePort();

      // Start the server
      await _fileServer.start(_port);
      _isSharing = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start sharing: $e';
      _isSharing = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop sharing files
  Future<void> stopSharing() async {
    try {
      await _fileServer.stop();
      _isSharing = false;
      _ipAddress = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop sharing: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _fileServer.stop();
    super.dispose();
  }
}
