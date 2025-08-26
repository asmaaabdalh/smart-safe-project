// lib/services/mqtt_service.dart

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart'; // Add this import
import 'dart:convert';

class MqttService with ChangeNotifier {
  // Use MqttBrowserClient for web
  late MqttBrowserClient client;
  final String clientIdentifier = 'flutter_client${DateTime.now().millisecondsSinceEpoch}';

  String _safeStatus = 'Unknown';
  String get safeStatus => _safeStatus;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  MqttService() {
    _initializeClient();
  }

  void _initializeClient() {
    // Use MqttBrowserClient for web with WebSocket URL
    client = MqttBrowserClient('wss://broker.hivemq.com:8884/mqtt', clientIdentifier);
    
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.port = 8884; // WebSocket port
    
    // Set callbacks for connection status
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> connect() async {
    try {
      print('MQTT_LOGS:: Connecting to WebSocket broker...');
      
      // Connect without credentials for public broker
      await client.connect();
      
    } on Exception catch (e) {
      print('Connection Exception: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    print('MQTT_LOGS:: Connected to broker successfully!');
    _isConnected = true;
    notifyListeners();

    // Subscribe to topics
    const topic = 'smart_safe/status';
    client.subscribe(topic, MqttQos.atLeastOnce);

    // Listen for messages
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      
      final payloadBytes = message.payload.message;
      final payload = utf8.decode(payloadBytes);

      print('Received status update: $payload');
      _safeStatus = payload;
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

  void publishPassword(String password) {
    if (!_isConnected) {
      print('Not connected to MQTT broker!');
      return;
    }

    const publishTopic = 'smart_safe/control';
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(password.trim());
    
    print('MQTT_LOGS:: Publishing password to topic: $publishTopic');
    client.publishMessage(publishTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    client.disconnect();
    print('MQTT_LOGS:: Disconnected from broker');
    _isConnected = false;
    notifyListeners();
  }
}