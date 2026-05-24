# Environment Setup

## Current Machine Check

Checked on 2026-05-24:

- `git`: installed
- `node`: available through Codex app bundle
- `flutter`: installed, 3.44.0 stable
- `dart`: installed, 3.12.0
- `bun`: installed, 1.3.14
- `npx`: not found as a standalone system command

`flutter doctor` status:

- Flutter: OK
- Chrome web target: OK
- Connected device detection: OK
- Network resources: OK
- Android toolchain: missing Android SDK
- iOS/macOS toolchain: full Xcode missing, CocoaPods missing

## Install Flutter

Flutter is installed. Verify any time with:

```bash
flutter doctor
flutter --version
dart --version
```

For VS Code, install:

- Flutter extension
- Dart extension

The app has been created in `frontend/ai_closet_app`.

```bash
cd frontend/ai_closet_app
flutter run
```

## Install Node Tooling

`npx getdesign@latest add apple` requires Node.js/npm tooling. On macOS, install Node through one of:

- Homebrew: `brew install node`
- Volta
- fnm
- official Node installer

Then run from project root:

```bash
npx getdesign@latest add apple
```

## Install Bun For gstack

gstack setup requires Bun. Bun is installed and gstack setup has completed for Codex.

```bash
gstack ready (codex)
```
