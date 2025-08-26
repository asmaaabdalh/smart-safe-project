// lib/services/mqtt_service.dart

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';
import 'dart:convert'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class MqttService with ChangeNotifier {
  // -->> املأ هذه البيانات ببيانات HiveMQ الخاصة بك <<--
  final MqttServerClient client = MqttServerClient('dfc251f747a74e7f9c297471a17708ba.s1.eu.hivemq.cloud', '');
  final String _username = 'IOTclaster';
  final String _passwordAuth = '4B&3.KpGQm28uZ>hczC!';
  final String clientIdentifier = 'flutter_client${DateTime.now().millisecondsSinceEpoch}';

  String _safeStatus = 'Unknown';
  String get safeStatus => _safeStatus;

  Future<void> connect() async {
    client.port = 8883; // المنفذ الآمن
    client.secure = true;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.clientIdentifier = clientIdentifier;

    try {
      final securityContext = SecurityContext.defaultContext;
      final trustedRoot = await rootBundle.load('assets/hivemq-ca.pem');
      securityContext.setTrustedCertificatesBytes(trustedRoot.buffer.asUint8List());
      client.securityContext = securityContext;
    } catch (e) {
      print('Failed to load certificates: $e');
      client.disconnect();
      return;
    }

    try {
      print('MQTT_LOGS:: Connecting to broker...');
      await client.connect(_username, _passwordAuth);
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT_LOGS:: Connected to broker.');
      
      const topic = 'smart_safe/status'; 
      client.subscribe(topic, MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        
        // CORRECTED: Access the payload bytes directly and decode to string
        final payloadBytes = message.payload.message;
        final payload = utf8.decode(payloadBytes);
        
        print('Received status update: $payload');
        _safeStatus = payload;
        notifyListeners(); 
      });
    } else {
      print('ERROR: MQTT client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void publishPassword(String password) {
    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      print('Not connected to MQTT broker!');
      return;
    }

    const publishTopic = 'smart_safe/control';
    
    // Corrected way to create and publish the payload
    final builder = MqttClientPayloadBuilder();
    builder.addString(password.trim());
    
    print('MQTT_LOGS:: Publishing password to topic: $publishTopic');
    client.publishMessage(publishTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    client.disconnect();
  }
}