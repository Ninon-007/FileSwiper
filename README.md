<<<<<<< HEAD
# File Swiper 🗂️

A swipe-based file cleaning application for Android that helps you quickly organize and delete files from your Downloads folder.

## Features ✨

- 📱 **Swipe Interface** - Swipe left to delete, swipe right to keep
- 🖼️ **Image Preview** - View images with zoom capability
- 📄 **PDF Preview** - Read PDFs before deciding to delete
- 🗑️ **Delete Queue** - Review files before permanent deletion
- 🎨 **Material Design** - Clean, modern interface
- ⚡ **Fast & Responsive** - Smooth performance

## Setup Instructions 🚀

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code
- Android device or emulator (Android 5.0+)

### Step 1: Install Flutter Dependencies
```bash
cd file_swiper
flutter pub get
```

### Step 2: Configure Android
The necessary permissions are already configured in `AndroidManifest.xml`:
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE
- READ_MEDIA_IMAGES (Android 13+)
- MANAGE_EXTERNAL_STORAGE

### Step 3: Run the App
```bash
# Connect your Android device or start an emulator
flutter devices

# Run the app
flutter run
```

### Step 4: Build APK (Optional)
```bash
# Build release APK
flutter build apk --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi
```

## How to Use 📖

1. **Grant Permissions** - Allow storage access when prompted
2. **Swipe Files** - Swipe left (❌ delete) or right (✅ keep)
3. **Preview Files** - Tap the eye icon or tap the card to preview
4. **Review Queue** - Check the badge icon in the app bar to see queued deletions
5. **Confirm Delete** - Tap the delete icon when ready to permanently remove files

## Project Structure 📁

```
file_swiper/
├── lib/
│   └── main.dart              # Main application code
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   └── AndroidManifest.xml  # Permissions
│   │   └── build.gradle       # Android build config
├── pubspec.yaml               # Dependencies
└── README.md
```

## Dependencies 📦

- `path_provider` - Access Downloads directory
- `permission_handler` - Handle storage permissions
- `flutter_pdfview` - Display PDF files
- `path` - File path utilities

## Supported File Types 🎯

- **Images**: .jpg, .jpeg, .png, .gif, .webp
- **Documents**: .pdf

## Troubleshooting 🔧

### Permission Issues
If the app can't access files:
1. Go to Settings > Apps > File Swiper > Permissions
2. Enable "Files and media" or "Storage"
3. For Android 11+, enable "All files access" if needed

### Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

### Dependencies Not Found
```bash
# Update dependencies
flutter pub upgrade
```

## Future Enhancements 🚀

- [ ] Support for more file types (videos, documents)
- [ ] Undo functionality
- [ ] Statistics and storage saved
- [ ] Custom folder selection
- [ ] Dark mode
- [ ] File sharing

## License 📄

This project is open source and available for personal and commercial use.

## Author ✍️

Built with Flutter 💙
=======
# FileSwiper
>>>>>>> 96d5fa0f125417320bc9d6f357edeae56f78be21
