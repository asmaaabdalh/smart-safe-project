# IoT Secured Smart Safe
A smart, internet-connected safe that combines the reliability of hardware with the flexibility of a mobile application to provide a modern and secure storage solution. This project was developed as a final project for the IoT SW & HW Engineering Field Training Program.

 Features
 Remote Control via Mobile App: Lock and unlock the safe from anywhere in the world using a secure Flutter application.

 Secure Authentication: User sign-up and login system powered by Supabase for robust security.

 Dual Alarm System:

An alarm is triggered after three incorrect password attempts.

A unique light-based alarm (using an LDR sensor) detects forced entry attempts and triggers an immediate alert.

 Smart Auto-Lock: The safe door automatically locks if the IR sensor detects no presence for a set period, ensuring it's never left open by mistake.

 Real-time Status Display: An onboard LCD screen provides instant feedback on the safe's status (Locked, Unlocked, Connecting, etc.).

 System Architecture
The system operates on a client-server model where the Flutter application and the ESP32 microcontroller act as clients. They communicate indirectly through a central MQTT broker (HiveMQ), which relays messages between them. User data and authentication are handled separately by Supabase.

**

 Technology Stack
Hardware
Microcontroller: ESP32

Actuator: Servo Motor SG90

Sensors: IR (Infrared) Sensor, LDR (Light Dependent Resistor)

Interface: 16x2 I2C LCD Display, LED, Buzzer

Firmware (ESP32)
Language: C++

Framework: Arduino

IDE: PlatformIO with VS Code

Mobile Application
Framework: Flutter

Language: Dart

Backend & Cloud
Database & Auth: Supabase (PostgreSQL + Authentication)

Communication Protocol: MQTT

MQTT Broker: HiveMQ Cloud

 Getting Started
To get a local copy up and running, follow these simple steps.

Prerequisites
Flutter SDK installed.

VS Code with the PlatformIO extension.

An account on Supabase and HiveMQ Cloud.

Installation & Setup
Clone the repo:

git clone https://github.com/your_username/your_repository_name.git

Flutter App Setup:

Navigate to the Flutter project directory.

Install packages:

flutter pub get

Create a .env file and add your Supabase credentials.

ESP32 Firmware Setup:

Open the firmware directory in VS Code (it will automatically launch PlatformIO).

In the main.cpp file, update the Wi-Fi and HiveMQ credentials.

Build and upload the code to your ESP32.

 Team Members
 
[Shahd Walid] - Role ( Hardware & Firmware Lead)

[Asmaa Abdullah] - Role (Flutter UI Developer)

[Nourean Husain] - Role (Flutter Backend Developer)

[Basmala Mahmoud] - Role (DevOps & Integration Lead)

📄 License
Distributed under the MIT License. See LICENSE for more information.
