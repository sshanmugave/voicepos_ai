# Releases

This folder contains downloadable build artifacts for quick testing.

## Current APK

- `app-release.apk` - Android release build
- `app-release.apk.sha1` - SHA1 checksum

If you want smaller APK files, build split-per-abi variants:

```bash
flutter build apk --release --split-per-abi
```
