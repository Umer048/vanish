<div align="center">
  <img src="https://github.com/user-attachments/assets/3be84199-a09c-4db0-b07b-4741b35530ae" width="250" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/544a6c8c-9884-4e74-9f6f-18a812c2dd96" width="250" />
</div>
<br><br>
## Vanish Class Network - Flutter App

## What is this?
Vanish is a mobile chat application where messages disappear exactly 30 seconds after they are delivered. This app connects to the shared class relay server to communicate with all other students' apps.

## Platform Used
- **Framework:** Flutter (Dart)
- **Target Device:** Android (Tested on Android 16 / POCO C75)
- **Storage:** Local JSON file (`vanish_state.json`) for offline queue and state persistence.

## Relay Address
The app connects to the official class relay:
`wss://vanish-relay-sawaira.bonto.page/ws`

## How to Build and Run
1. Clone the repository: `git clone https://github.com/Umer048/vanish.git`
2. Open the project in Android Studio.
3. Ensure the Flutter SDK is installed.
4. Connect an Android device or start an emulator.
5. Run `flutter pub get` in the terminal.
6. Press the **Run** button (or execute `flutter run`).
7. Enter your display name and click "Enter Vanish".

## Academic Integrity & AI Disclosure
- **AI Tools:** I used AI assistance for code refactoring, fixing Flutter deprecations (`withOpacity`), and understanding the WebSocket protocol structure. However, I understand every line of the submitted code.
- **Class Work:** The protocol document (`PROTOCOL.md`) was provided by Sawaira Waheed and agreed upon by the class.

## Features Implemented
- Protocol v1 integration (Join, Welcome, Message, Expired, Ping/Pong, Presence).
- Precise countdown timer based on server time (handles clock skew).
- Offline message queue (messages are saved locally and sent when reconnected).
- Real deletion of messages from local storage.
