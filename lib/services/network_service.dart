import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

/// Service for network-related operations like getting device IP address.
class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Default port for the file server
  static const int defaultPort = 8080;

  /// Get the device's WiFi IP address
  Future<String?> getWifiIPAddress() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      return wifiIP;
    } catch (e) {
      print('Error getting WiFi IP: $e');
      return null;
    }
  }

  /// Find an available port starting from the default
  Future<int> findAvailablePort({int startPort = defaultPort}) async {
    int port = startPort;
    while (port < startPort + 100) {
      try {
        final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await server.close();
        return port;
      } catch (e) {
        port++;
      }
    }
    return startPort; // Fallback to default
  }

  /// Generate the full sharing URL
  String getShareUrl(String ipAddress, int port) {
    return 'http://$ipAddress:$port';
  }

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    final ip = await getWifiIPAddress();
    return ip != null && ip.isNotEmpty;
  }
}
