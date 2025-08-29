// lib/services/mqtt_service.dart

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'dart:convert';

class MqttService with ChangeNotifier {
  late MqttBrowserClient client;
  final String clientIdentifier = 'flutter_client${DateTime.now().millisecondsSinceEpoch}';

  String _safeStatus = 'Unknown';
  String get safeStatus => _safeStatus;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // New variable to store the number of wrong attempts
  int _wrongAttempts = 0;
  int get wrongAttempts => _wrongAttempts;

  MqttService() {
    _initializeClient();
  }

  void _initializeClient() {
    client = MqttBrowserClient('wss://mqtt-dashboard.com:8884/mqtt', clientIdentifier);
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.port = 8884;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> connect() async {
    try {
      await client.connect();
    } catch (e) {
      print('MQTT_LOGS:: Exception: $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('MQTT_LOGS:: Connected to broker successfully!');
    _isConnected = true;
    notifyListeners();
    const topic = 'smart_safe/status';
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payloadBytes = message.payload.message;
      final payload = utf8.decode(payloadBytes);

      print('Received status update: $payload');
      
      // Check if the message contains the number of wrong attempts
      if (payload.startsWith('ALARM:')) {
        // Extract the number and update the state
        final parts = payload.split(':');
        if (parts.length > 1) {
          try {
            _wrongAttempts = int.parse(parts[1]);
            _safeStatus = 'ALARM';
          } catch (e) {
            print('Failed to parse wrong attempts count: $e');
            _wrongAttempts = 0; // Reset on parse error
            _safeStatus = payload;
          }
        }
      } else {
        _safeStatus = payload;
        // Reset wrong attempts when the status is not ALARM or LOCKED
        if (_safeStatus != 'LOCKED') {
          _wrongAttempts = 0;
        }
      }
      
      notifyListeners();
    });
  }

  void _onDisconnected() {
    print('MQTT_LOGS:: Disconnected from broker');
    _isConnected = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    print('MQTT_LOGS:: Subscribed to topic: $topic');
  }

  // The corrected publish method
  void publishPassword(String password) {
    if (!_isConnected) {
      print('Not connected to MQTT broker!');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(password);
    client.publishMessage(
      'smart_safe/control', 
      MqttQos.atMostOnce, 
      builder.payload!,
    );
    print('Published password: $password');
  }
}
