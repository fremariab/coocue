# Coocue – Smart Baby Monitoring App

**An AI-powered baby monitoring proof of concept built with Flutter, Firebase, WebRTC, and Machine Learning.**

Coocue is a mobile-based baby monitoring solution designed to explore the feasibility of using artificial intelligence and readily available Android smartphones to provide affordable infant monitoring in low-resource settings.

The application repurposes two Android smartphones into a cooperative baby monitoring system: one acts as the **Parent Phone**, while the other serves as the **Cot Phone**. Using AI-powered cry detection, real-time audio and video streaming, and remote control features, Coocue allows parents and caregivers to monitor their infants remotely without requiring dedicated IoT hardware.

## Project Links

- **Demo Video:** [Watch the Coocue Demo](https://studio.youtube.com/video/r-ZAMIl5lO8/edit)
- **GitHub Repository:** [Coocue](https://github.com/fremariab/coocue)
- **Cry Detection API:** [Coocue Cry Detector API]((https://github.com/fremariab/coocue_cry_detector_api))

## Background

Access to conventional baby monitoring systems can be limited in developing countries due to cost, availability, and infrastructure constraints.

Coocue explores an alternative approach by transforming spare or low-cost Android smartphones into intelligent baby monitors. The system combines machine learning, mobile communication, and cloud services to provide an accessible monitoring experience for parents and caregivers.

## Key Features

- **AI-Powered Cry Detection:** Uses a machine learning API to analyze audio recordings and identify whether a baby is crying.
- **Real-Time Audio and Video Streaming:** Enables parents to remotely monitor their infants through WebRTC.
- **Two-Way Audio Communication:** Allows parents to talk to their babies remotely.
- **Remote Lullaby Playback:** Parents can trigger lullaby playback on the Cot Phone.
- **Custom Lullaby Uploads:** Allows parents to upload and manage their own lullabies.
- **Device Pairing:** Connects Parent and Cot Phones using a six-digit authentication code.
- **Remote Device Controls:** Uses Firebase to synchronize commands and device states.
- **PIN-Protected Access:** Secures sensitive application features with a four-digit PIN.
- **Security Question Recovery:** Provides an additional mechanism for recovering access to protected features.

## How It Works

Coocue operates through two device roles within a single Flutter application.

### 1. Cot Phone

The Cot Phone is positioned near the infant and acts as the monitoring device. It:

- Captures audio and video.
- Periodically records short audio clips and sends them to the cry detection API.
- Receives and executes remote commands from the Parent Phone.
- Plays lullabies and audio received through two-way communication.
- Streams live audio and video to the Parent Phone.

### 2. Parent Phone

The Parent Phone serves as the caregiver's control interface. It:

- Connects to the Cot Phone using a six-digit pairing code.
- Displays the live camera feed.
- Allows parents to listen to their infants.
- Supports two-way audio communication.
- Allows remote lullaby playback.
- Provides access to application settings and monitoring controls.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter / Dart | Cross-platform mobile application development |
| Firebase Authentication | User authentication |
| Cloud Firestore | Device pairing, signaling, commands, and synchronization |
| Firebase Cloud Messaging | Push notifications |
| Firebase Storage | Lullaby and media storage |
| WebRTC | Real-time audio and video communication |
| Python / Flask | Backend API for cry detection |
| Machine Learning | Audio-based baby cry classification |
| just_audio | Lullaby and audio playback |

## System Architecture

Coocue follows a hybrid client architecture coordinated through Firebase.

The application runs on two Android devices, each assigned a distinct role. The Cot Phone handles audio/video capture, cry detection requests, and remote command execution. The Parent Phone handles monitoring, communication, and remote controls.

Firebase provides the backend infrastructure for device pairing, signaling, command exchange, notifications, and storage. WebRTC establishes peer-to-peer media communication between the two devices, while the Flask API handles machine learning inference.

### Architecture Overview

```text
                  FIREBASE SERVICES
        (Firestore, FCM, Firebase Storage)
                         |
              Device Pairing & Signaling
                         |
             +-----------+
