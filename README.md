# ViewerAssist

A local network file sharing tool that allows you to share files from your mobile device and access them from any device (TV, laptop, tablet) connected to the same WiFi network.

## Features

- 📁 **Select Multiple Files** - Share videos, audio, images, and documents
- 🌐 **Local Network Sharing** - No internet required, works over WiFi
- 📱 **QR Code** - Scan QR code from TV or other devices for easy access
- 🎬 **Video Streaming** - Seek support via HTTP range requests
- 🖥️ **Web Player** - Modern, responsive web interface for playback
- ⬇️ **Download** - Download files directly to the client device

## Architecture

```
Mobile Device (Host)             Client Devices
┌─────────────────────┐         ┌──────────────────┐
│  ViewerAssist App   │         │   TV Browser     │
│  ┌───────────────┐  │  WiFi   │   Laptop Browser │
│  │ HTTP Server   │◄─┼─────────┤   Tablet Browser │
│  │ (shelf)       │  │         │                  │
│  └───────────────┘  │         └──────────────────┘
│  192.168.x.x:8080   │
└─────────────────────┘
```
## Sreens
### File Share Screen
![Alt text](/sharescreen.jpg)

## Getting Started

### Prerequisites

- Flutter SDK (3.7.2 or later)
- Android Studio / Xcode
- Physical Android or iOS device

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on device:
   ```bash
   flutter run
   ```

### Usage

1. **Add Files** - Tap the "Add Files" button to select files
2. **Start Sharing** - Tap "Start Sharing" button
3. **Access from TV** - Either:
   - Scan the QR code with your TV or another device
   - Enter the displayed URL in the TV's browser
4. **Play/Download** - Use the web interface to play or download files

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── shared_file.dart         # File data model
├── providers/
│   └── sharing_provider.dart    # State management
├── screens/
│   ├── home_screen.dart         # File selection screen
│   └── sharing_screen.dart      # Active sharing screen
├── services/
│   ├── file_picker_service.dart # File selection
│   ├── file_server.dart         # HTTP server
│   └── network_service.dart     # WiFi/IP utilities
└── widgets/
    ├── file_list_widget.dart    # File list component
    └── qr_code_widget.dart      # QR code display
```

## License

MIT License
