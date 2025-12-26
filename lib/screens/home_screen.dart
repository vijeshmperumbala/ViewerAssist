import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sharing_provider.dart';
import '../widgets/file_list_widget.dart';
import 'sharing_screen.dart';

/// Home screen for selecting files to share.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '📁 ViewerAssist',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share files on your local network',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Selected files list
              Expanded(
                child: Consumer<SharingProvider>(
                  builder: (context, provider, _) {
                    return FileListWidget(
                      files: provider.selectedFiles,
                      onRemove: provider.removeFile,
                    );
                  },
                ),
              ),

              // Error message
              Consumer<SharingProvider>(
                builder: (context, provider, _) {
                  if (provider.errorMessage != null) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Bottom action buttons
              Consumer<SharingProvider>(
                builder: (context, provider, _) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Start sharing button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: provider.selectedFiles.isEmpty
                                ? null
                                : () async {
                                    final success = await provider.startSharing();
                                    if (success && context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SharingScreen(),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00d2ff),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.white.withOpacity(0.1),
                              disabledForegroundColor: Colors.white.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_tethering),
                                SizedBox(width: 8),
                                Text(
                                  'Start Sharing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (provider.selectedFiles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${provider.selectedFiles.length} file(s) selected',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<SharingProvider>().pickFiles();
        },
        backgroundColor: const Color(0xFF3a7bd5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Files'),
      ),
    );
  }
}
