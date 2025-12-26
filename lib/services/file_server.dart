import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../models/shared_file.dart';

/// HTTP server for serving files over the local network.
class FileServer {
  HttpServer? _server;
  final List<SharedFile> _sharedFiles = [];
  bool _isRunning = false;

  /// Check if the server is currently running
  bool get isRunning => _isRunning;

  /// Get list of currently shared files
  List<SharedFile> get sharedFiles => List.unmodifiable(_sharedFiles);

  /// Add files to share
  void addFiles(List<SharedFile> files) {
    for (final file in files) {
      if (!_sharedFiles.any((f) => f.id == file.id)) {
        _sharedFiles.add(file);
      }
    }
  }

  /// Remove a file from sharing
  void removeFile(String fileId) {
    _sharedFiles.removeWhere((f) => f.id == fileId);
  }

  /// Clear all shared files
  void clearFiles() {
    _sharedFiles.clear();
  }

  /// Start the HTTP server
  Future<void> start(int port) async {
    if (_isRunning) return;

    final router = Router();

    // Home page with file list
    router.get('/', _handleHome);

    // API: Get list of shared files
    router.get('/api/files', _handleFilesList);

    // Stream a file
    router.get('/file/<id>', _handleFileStream);

    // Download a file
    router.get('/download/<id>', _handleDownload);

    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    );

    _isRunning = true;
    print('Server running on http://${_server!.address.address}:${_server!.port}');
  }

  /// Stop the HTTP server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
    }
  }

  /// CORS middleware to allow cross-origin requests
  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Range',
    'Access-Control-Expose-Headers': 'Content-Length, Content-Range',
  };

  /// Handle home page request
  Response _handleHome(Request request) {
    return Response.ok(
      _generateWebPlayerHtml(),
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  /// Handle API request for files list
  Response _handleFilesList(Request request) {
    final filesJson = _sharedFiles.map((f) => f.toJson()).toList();
    return Response.ok(
      jsonEncode({'files': filesJson}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Handle file streaming request with range support
  Future<Response> _handleFileStream(Request request, String id) async {
    final file = _sharedFiles.firstWhere(
      (f) => f.id == id,
      orElse: () => throw Exception('File not found'),
    );

    final fileHandle = File(file.path);
    if (!await fileHandle.exists()) {
      return Response.notFound('File not found');
    }

    final fileSize = await fileHandle.length();
    final rangeHeader = request.headers['range'];

    if (rangeHeader != null) {
      // Handle range requests for video seeking
      return _handleRangeRequest(fileHandle, fileSize, rangeHeader, file.mimeType);
    }

    // Full file response
    return Response.ok(
      fileHandle.openRead(),
      headers: {
        'Content-Type': file.mimeType,
        'Content-Length': fileSize.toString(),
        'Accept-Ranges': 'bytes',
      },
    );
  }

  /// Handle range requests for video streaming
  Response _handleRangeRequest(
    File file,
    int fileSize,
    String rangeHeader,
    String mimeType,
  ) {
    final rangeMatch = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(rangeHeader);
    if (rangeMatch == null) {
      return Response(416, body: 'Invalid range');
    }

    final startStr = rangeMatch.group(1);
    final endStr = rangeMatch.group(2);

    int start = startStr != null && startStr.isNotEmpty ? int.parse(startStr) : 0;
    int end = endStr != null && endStr.isNotEmpty ? int.parse(endStr) : fileSize - 1;

    if (start >= fileSize || end >= fileSize || start > end) {
      return Response(416, body: 'Range not satisfiable');
    }

    final contentLength = end - start + 1;

    return Response(
      206,
      body: file.openRead(start, end + 1),
      headers: {
        'Content-Type': mimeType,
        'Content-Length': contentLength.toString(),
        'Content-Range': 'bytes $start-$end/$fileSize',
        'Accept-Ranges': 'bytes',
      },
    );
  }

  /// Handle file download request
  Future<Response> _handleDownload(Request request, String id) async {
    final file = _sharedFiles.firstWhere(
      (f) => f.id == id,
      orElse: () => throw Exception('File not found'),
    );

    final fileHandle = File(file.path);
    if (!await fileHandle.exists()) {
      return Response.notFound('File not found');
    }

    final fileSize = await fileHandle.length();

    return Response.ok(
      fileHandle.openRead(),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="${file.name}"',
        'Content-Length': fileSize.toString(),
      },
    );
  }

  /// Generate the web player HTML page
  String _generateWebPlayerHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ViewerAssist - File Manager</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --bg-primary: #0d1117;
            --bg-secondary: #161b22;
            --bg-tertiary: #21262d;
            --bg-hover: #30363d;
            --border-color: #30363d;
            --text-primary: #f0f6fc;
            --text-secondary: #8b949e;
            --accent-blue: #58a6ff;
            --accent-green: #3fb950;
            --accent-purple: #a371f7;
            --accent-orange: #d29922;
            --accent-red: #f85149;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        /* Header / Toolbar */
        .toolbar {
            background: var(--bg-secondary);
            border-bottom: 1px solid var(--border-color);
            padding: 12px 20px;
            display: flex;
            align-items: center;
            gap: 16px;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .logo {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--accent-blue);
        }
        
        .logo-icon {
            font-size: 1.5rem;
        }
        
        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--text-secondary);
            flex: 1;
        }
        
        .breadcrumb-item {
            padding: 6px 12px;
            background: var(--bg-tertiary);
            border-radius: 6px;
            font-size: 0.875rem;
        }
        
        .view-toggle {
            display: flex;
            background: var(--bg-tertiary);
            border-radius: 6px;
            overflow: hidden;
        }
        
        .view-btn {
            padding: 8px 12px;
            border: none;
            background: transparent;
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.2s;
            font-size: 1rem;
        }
        
        .view-btn:hover {
            color: var(--text-primary);
        }
        
        .view-btn.active {
            background: var(--accent-blue);
            color: white;
        }
        
        /* Main Layout */
        .main-container {
            display: flex;
            flex: 1;
            overflow: hidden;
        }
        
        /* Sidebar */
        .sidebar {
            width: 240px;
            background: var(--bg-secondary);
            border-right: 1px solid var(--border-color);
            padding: 16px 0;
            display: flex;
            flex-direction: column;
        }
        
        .sidebar-section {
            padding: 0 12px;
            margin-bottom: 24px;
        }
        
        .sidebar-title {
            font-size: 0.75rem;
            text-transform: uppercase;
            color: var(--text-secondary);
            margin-bottom: 8px;
            padding: 0 8px;
        }
        
        .sidebar-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 12px;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
            color: var(--text-secondary);
        }
        
        .sidebar-item:hover {
            background: var(--bg-hover);
            color: var(--text-primary);
        }
        
        .sidebar-item.active {
            background: rgba(88, 166, 255, 0.15);
            color: var(--accent-blue);
        }
        
        .sidebar-icon {
            font-size: 1.1rem;
        }
        
        .sidebar-count {
            margin-left: auto;
            background: var(--bg-tertiary);
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 0.75rem;
        }
        
        /* File List */
        .file-area {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
        }
        
        .file-header {
            display: grid;
            grid-template-columns: 40px 1fr 120px 100px 50px;
            gap: 12px;
            padding: 10px 16px;
            background: var(--bg-tertiary);
            border-radius: 8px;
            margin-bottom: 8px;
            font-size: 0.75rem;
            text-transform: uppercase;
            color: var(--text-secondary);
            font-weight: 600;
        }
        
        .file-list {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }
        
        .file-row {
            display: grid;
            grid-template-columns: 40px 1fr 120px 100px 50px;
            gap: 12px;
            padding: 12px 16px;
            background: var(--bg-secondary);
            border-radius: 8px;
            border: 1px solid transparent;
            cursor: pointer;
            transition: all 0.2s;
            align-items: center;
        }
        
        .file-row:hover {
            background: var(--bg-tertiary);
            border-color: var(--border-color);
        }
        
        .file-row.selected {
            background: rgba(88, 166, 255, 0.1);
            border-color: var(--accent-blue);
        }
        
        .file-icon-wrapper {
            width: 36px;
            height: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
            font-size: 1.25rem;
        }
        
        .file-icon-video { background: rgba(248, 81, 73, 0.2); }
        .file-icon-audio { background: rgba(163, 113, 247, 0.2); }
        .file-icon-image { background: rgba(63, 185, 80, 0.2); }
        .file-icon-other { background: rgba(139, 148, 158, 0.2); }
        
        .file-info {
            display: flex;
            flex-direction: column;
            gap: 4px;
            min-width: 0;
        }
        
        .file-name {
            font-weight: 500;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .file-type {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }
        
        .file-size, .file-date {
            color: var(--text-secondary);
            font-size: 0.875rem;
        }
        
        .file-actions-cell {
            display: flex;
            gap: 8px;
        }
        
        .action-btn {
            width: 32px;
            height: 32px;
            display: flex;
            align-items: center;
            justify-content: center;
            border: none;
            background: var(--bg-tertiary);
            color: var(--text-secondary);
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
        }
        
        .action-btn:hover {
            background: var(--accent-blue);
            color: white;
        }
        
        /* Grid View */
        .file-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 16px;
        }
        
        .file-card {
            background: var(--bg-secondary);
            border-radius: 12px;
            padding: 16px;
            border: 1px solid transparent;
            cursor: pointer;
            transition: all 0.2s;
            text-align: center;
        }
        
        .file-card:hover {
            background: var(--bg-tertiary);
            border-color: var(--border-color);
            transform: translateY(-2px);
        }
        
        .file-card.selected {
            border-color: var(--accent-blue);
            background: rgba(88, 166, 255, 0.1);
        }
        
        .file-card-icon {
            font-size: 3rem;
            margin-bottom: 12px;
        }
        
        .file-card-name {
            font-weight: 500;
            margin-bottom: 4px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .file-card-size {
            font-size: 0.75rem;
            color: var(--text-secondary);
        }
        
        /* Preview Panel */
        .preview-panel {
            position: fixed;
            top: 0;
            right: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.9);
            display: none;
            flex-direction: column;
            z-index: 200;
        }
        
        .preview-panel.active {
            display: flex;
        }
        
        .preview-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 24px;
            background: var(--bg-secondary);
            border-bottom: 1px solid var(--border-color);
        }
        
        .preview-title {
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .preview-close {
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            border: none;
            background: var(--bg-tertiary);
            color: var(--text-primary);
            border-radius: 8px;
            cursor: pointer;
            font-size: 1.25rem;
        }
        
        .preview-close:hover {
            background: var(--accent-red);
        }
        
        .preview-content {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            overflow: auto;
        }
        
        .preview-content video,
        .preview-content audio {
            max-width: 100%;
            max-height: 100%;
            border-radius: 12px;
        }
        
        .preview-content img {
            max-width: 100%;
            max-height: 100%;
            border-radius: 12px;
            object-fit: contain;
        }
        
        /* Status Bar */
        .status-bar {
            background: var(--bg-secondary);
            border-top: 1px solid var(--border-color);
            padding: 8px 20px;
            display: flex;
            align-items: center;
            gap: 24px;
            font-size: 0.75rem;
            color: var(--text-secondary);
        }
        
        .status-item {
            display: flex;
            align-items: center;
            gap: 6px;
        }
        
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--accent-green);
        }
        
        /* Empty State */
        .empty-state {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: var(--text-secondary);
            text-align: center;
            padding: 40px;
        }
        
        .empty-icon {
            font-size: 4rem;
            margin-bottom: 16px;
            opacity: 0.5;
        }
        
        .empty-title {
            font-size: 1.25rem;
            margin-bottom: 8px;
            color: var(--text-primary);
        }
        
        /* Loading */
        .loading {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            gap: 16px;
        }
        
        .spinner {
            width: 40px;
            height: 40px;
            border: 3px solid var(--bg-tertiary);
            border-top-color: var(--accent-blue);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .sidebar { display: none; }
            .file-header { display: none; }
            .file-row {
                grid-template-columns: 40px 1fr 50px;
            }
            .file-row .file-size,
            .file-row .file-date { display: none; }
        }
    </style>
</head>
<body>
    <!-- Toolbar -->
    <div class="toolbar">
        <div class="logo">
            <span class="logo-icon">📁</span>
            <span>ViewerAssist</span>
        </div>
        <div class="breadcrumb">
            <span class="breadcrumb-item">🏠 Shared Files</span>
        </div>
        <div class="view-toggle">
            <button class="view-btn active" onclick="setView('list')" id="list-btn">☰</button>
            <button class="view-btn" onclick="setView('grid')" id="grid-btn">▦</button>
        </div>
    </div>
    
    <!-- Main Container -->
    <div class="main-container">
        <!-- Sidebar -->
        <div class="sidebar">
            <div class="sidebar-section">
                <div class="sidebar-title">Quick Access</div>
                <div class="sidebar-item active" onclick="filterFiles('all')">
                    <span class="sidebar-icon">📂</span>
                    <span>All Files</span>
                    <span class="sidebar-count" id="count-all">0</span>
                </div>
            </div>
            <div class="sidebar-section">
                <div class="sidebar-title">File Types</div>
                <div class="sidebar-item" onclick="filterFiles('video')">
                    <span class="sidebar-icon">🎬</span>
                    <span>Videos</span>
                    <span class="sidebar-count" id="count-video">0</span>
                </div>
                <div class="sidebar-item" onclick="filterFiles('audio')">
                    <span class="sidebar-icon">🎵</span>
                    <span>Audio</span>
                    <span class="sidebar-count" id="count-audio">0</span>
                </div>
                <div class="sidebar-item" onclick="filterFiles('image')">
                    <span class="sidebar-icon">🖼️</span>
                    <span>Images</span>
                    <span class="sidebar-count" id="count-image">0</span>
                </div>
                <div class="sidebar-item" onclick="filterFiles('other')">
                    <span class="sidebar-icon">📄</span>
                    <span>Documents</span>
                    <span class="sidebar-count" id="count-other">0</span>
                </div>
            </div>
        </div>
        
        <!-- File Area -->
        <div class="file-area" id="file-area">
            <div class="loading">
                <div class="spinner"></div>
                <p>Loading files...</p>
            </div>
        </div>
    </div>
    
    <!-- Status Bar -->
    <div class="status-bar">
        <div class="status-item">
            <span class="status-dot"></span>
            <span>Connected</span>
        </div>
        <div class="status-item" id="file-count-status">0 files</div>
        <div class="status-item" id="total-size-status">0 bytes</div>
    </div>
    
    <!-- Preview Panel -->
    <div class="preview-panel" id="preview-panel">
        <div class="preview-header">
            <span class="preview-title" id="preview-title">-</span>
            <button class="preview-close" onclick="closePreview()">✕</button>
        </div>
        <div class="preview-content" id="preview-content"></div>
    </div>

    <script>
        let files = [];
        let currentView = 'list';
        let currentFilter = 'all';
        
        async function loadFiles() {
            try {
                const response = await fetch('/api/files');
                const data = await response.json();
                files = data.files;
                updateCounts();
                renderFiles();
            } catch (error) {
                document.getElementById('file-area').innerHTML = 
                    '<div class="empty-state"><span class="empty-icon">⚠️</span><div class="empty-title">Error loading files</div></div>';
            }
        }
        
        function updateCounts() {
            document.getElementById('count-all').textContent = files.length;
            document.getElementById('count-video').textContent = files.filter(f => f.isVideo).length;
            document.getElementById('count-audio').textContent = files.filter(f => f.isAudio).length;
            document.getElementById('count-image').textContent = files.filter(f => f.isImage).length;
            document.getElementById('count-other').textContent = files.filter(f => !f.isVideo && !f.isAudio && !f.isImage).length;
            
            document.getElementById('file-count-status').textContent = files.length + ' file' + (files.length !== 1 ? 's' : '');
            
            const totalSize = files.reduce((sum, f) => sum + f.size, 0);
            document.getElementById('total-size-status').textContent = formatSize(totalSize);
        }
        
        function formatSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
            if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
            return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB';
        }
        
        function getFilteredFiles() {
            if (currentFilter === 'all') return files;
            if (currentFilter === 'video') return files.filter(f => f.isVideo);
            if (currentFilter === 'audio') return files.filter(f => f.isAudio);
            if (currentFilter === 'image') return files.filter(f => f.isImage);
            if (currentFilter === 'other') return files.filter(f => !f.isVideo && !f.isAudio && !f.isImage);
            return files;
        }
        
        function filterFiles(type) {
            currentFilter = type;
            document.querySelectorAll('.sidebar-item').forEach(el => el.classList.remove('active'));
            event.currentTarget.classList.add('active');
            renderFiles();
        }
        
        function setView(view) {
            currentView = view;
            document.getElementById('list-btn').classList.toggle('active', view === 'list');
            document.getElementById('grid-btn').classList.toggle('active', view === 'grid');
            renderFiles();
        }
        
        function getFileIcon(file) {
            if (file.isVideo) return '🎬';
            if (file.isAudio) return '🎵';
            if (file.isImage) return '🖼️';
            return '📄';
        }
        
        function getIconClass(file) {
            if (file.isVideo) return 'file-icon-video';
            if (file.isAudio) return 'file-icon-audio';
            if (file.isImage) return 'file-icon-image';
            return 'file-icon-other';
        }
        
        function renderFiles() {
            const container = document.getElementById('file-area');
            const filteredFiles = getFilteredFiles();
            
            if (filteredFiles.length === 0) {
                container.innerHTML = '<div class="empty-state"><span class="empty-icon">📭</span><div class="empty-title">No files found</div><p>No files are being shared</p></div>';
                return;
            }
            
            if (currentView === 'list') {
                container.innerHTML = `
                    <div class="file-header">
                        <span></span>
                        <span>Name</span>
                        <span>Size</span>
                        <span>Type</span>
                        <span></span>
                    </div>
                    <div class="file-list">
                        \${filteredFiles.map(file => `
                            <div class="file-row" onclick="openPreview('\${file.id}')">
                                <div class="file-icon-wrapper \${getIconClass(file)}">
                                    \${getFileIcon(file)}
                                </div>
                                <div class="file-info">
                                    <div class="file-name">\${file.name}</div>
                                    <div class="file-type">\${file.mimeType}</div>
                                </div>
                                <div class="file-size">\${file.formattedSize}</div>
                                <div class="file-date">\${file.mimeType.split('/')[0]}</div>
                                <div class="file-actions-cell">
                                    <a class="action-btn" href="/download/\${file.id}" onclick="event.stopPropagation()" title="Download">⬇</a>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                `;
            } else {
                container.innerHTML = `
                    <div class="file-grid">
                        \${filteredFiles.map(file => `
                            <div class="file-card" onclick="openPreview('\${file.id}')">
                                <div class="file-card-icon">\${getFileIcon(file)}</div>
                                <div class="file-card-name">\${file.name}</div>
                                <div class="file-card-size">\${file.formattedSize}</div>
                            </div>
                        `).join('')}
                    </div>
                `;
            }
        }
        
        function openPreview(fileId) {
            const file = files.find(f => f.id === fileId);
            if (!file) return;
            
            const panel = document.getElementById('preview-panel');
            const content = document.getElementById('preview-content');
            const title = document.getElementById('preview-title');
            
            title.textContent = file.name;
            const fileUrl = '/file/' + fileId;
            
            if (file.isVideo) {
                content.innerHTML = `<video src="\${fileUrl}" controls autoplay></video>`;
            } else if (file.isAudio) {
                content.innerHTML = `<audio src="\${fileUrl}" controls autoplay></audio>`;
            } else if (file.isImage) {
                content.innerHTML = `<img src="\${fileUrl}" alt="\${file.name}">`;
            } else {
                window.location.href = '/download/' + fileId;
                return;
            }
            
            panel.classList.add('active');
        }
        
        function closePreview() {
            document.getElementById('preview-panel').classList.remove('active');
            document.getElementById('preview-content').innerHTML = '';
        }
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') closePreview();
        });
        
        // Load files
        loadFiles();
        setInterval(loadFiles, 5000);
    </script>
</body>
</html>
''';
  }
}
