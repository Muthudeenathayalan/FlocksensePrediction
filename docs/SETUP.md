# FlockSense Setup & Deployment Guide

This guide walks through configuring the local development environment and deploying cloud functions for FlockSense.

## 1. Prerequisites

- Flutter SDK `^3.0.0`
- Dart SDK `^3.0.0`
- Node.js `18.x`
- Firebase CLI (`firebase-tools`)

## 2. Flutter Environment Setup

1. **Get Flutter dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**:
   - Ensure `firebase_options.dart` is configured for your Firebase Project.
   - For custom setup:
     ```bash
     flutterfire configure
     ```

3. **Run Flutter App**:
   ```bash
   flutter run -d chrome # Web
   flutter run -d android # Android device / emulator
   ```

## 3. Firebase Cloud Functions Setup

1. **Navigate to functions directory**:
   ```bash
   cd functions
   npm install
   ```

2. **Build TypeScript sources**:
   ```bash
   npm run build
   ```

3. **Deploy Functions**:
   ```bash
   firebase deploy --only functions
   ```
