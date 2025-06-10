# Gremory

**Your Personal AI Assistant – Fully Customizable and Private**

Gremory is an open-source Flutter application that serves as a personal assistant, much like ChatGPT, but with a twist — **you deploy it, you control it**. Use your own models and infrastructure to maintain full control over your data and experience.

Whether you want it on Android, iOS, macOS, or the Web — Gremory goes where you go.

<br>

## ✨ Features

* Works across platforms: Android, iOS, macOS, Web
* Integrates with your own backend and models
* Store data securely on your own cloud or database
* Easily customizable for your use case

<br>


## 🚀 Getting Started

### 1. Install Flutter

To get started, make sure you have Flutter installed:
👉 [Flutter Installation Guide](https://docs.flutter.dev/install)

---

### 2. Configure the Application

1. Copy the example config:

   ```
   cp config.json.example config.json
   ```
2. Set your backend URL in `config.json`.

---

### 3a. Install Dependencies

Run the following in your project directory:

```bash
flutter pub get
```

---

### 3b. Set Your icon

Run the following in your project directory to set your own default icon:

```bash
flutter pub run flutter_launcher_icons
```

---

### 4. Run the App

You can run the app on various platforms. Here’s how:

#### 🧪 Test on Chrome

```bash
flutter run -d chrome --dart-define-from-file=config.json
```

#### 💻 Test on macOS

```bash
flutter run -d macOS --dart-define-from-file=config.json
```

#### 📱 Test on Android Emulator

> You need Android Studio with a configured emulator.

1. Open VS Code.
2. Use Command Palette:

   ```
   >Flutter: Select Device
   ```
3. Once your emulator is selected and running, run the app:

* **Debug mode:**

  ```bash
  flutter run -d your-emulator-name --dart-define-from-file=config.json
  ```

* **Release mode:**

  ```bash
  flutter run -d your-emulator-name --dart-define-from-file=config.json --release
  ```

<br>

#### 💻 Creating a Release build apk

```bash
flutter build apk --release -v --dart-define-from-file=config.json
```
For Debug Model, replace `--release` with `--debug`.


---
## 📌 Todo

* [ ] Optimize API calls to avoid redundant requests and improve performance.
* [ ] Add personalization features using user-specific data.
* [ ] Enable media uploads and allow Q\&A over uploaded content.

<br>

## 💡 Notes

* The app is designed to be **modular and private-first**. You can integrate any open-source LLMs and host them however you like.
* Want to run it offline with your own model? Totally doable.
* Currently in active development — contributions and feedback are welcome!

---