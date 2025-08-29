# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS # <-- 1. استيراد المكتبة
import paho.mqtt.client as mqtt
import os

# --- Flask App Setup ---
app = Flask(__name__)
# -->> 2. تفعيل CORS للسماح لأي موقع بالاتصال <<--
# This is the crucial line that solves the connection error
CORS(app) 

# --- Configuration ---
# IMPORTANT: Replace with your REAL HiveMQ password
HIVEMQ_PASSWORD = "4B&3.KpGQm28uZ>hczC!" 

# --- MQTT Publish Function ---
# This function connects, sends one message, and disconnects.
# It's simple and reliable for servers like Railway.
def send_mqtt_message(topic, message):
    try:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        client.username_pw_set("IOTclaster", HIVEMQ_PASSWORD)
        client.tls_set() # Enable SSL/TLS for secure connection
        
        print(f"Connecting to broker to send message to {topic}...")
        client.connect("dfc251f747a74e7f9c297471a17708ba.s1.eu.hivemq.cloud", 8883, 60)
        
        client.loop_start()
        print(f"Publishing message: '{message}' to topic: '{topic}'")
        client.publish(topic, message, qos=1)
        client.loop_stop()
        
        client.disconnect()
        print("Message sent and disconnected.")
        return True
    except Exception as e:
        print(f"Failed to send MQTT message: {e}")
        return False

# --- Flask Routes ---
@app.route('/')
def home():
    """A simple route to confirm the API is running."""
    return "Smart Safe API is running!"

@app.route('/ask', methods=['POST'])
def ask():
    """
    Receives a question from the Flutter app, processes it,
    and sends a command via MQTT.
    """
    question = request.json.get('question', '').lower()
    if not question:
        return jsonify({"answer": "Please provide a question."}), 400
    
    # Simple logic without LangChain for now to ensure stability
    if "open" in question or "unlock" in question:
        if send_mqtt_message("safe/password", "1234"):
            return jsonify({"answer": "Unlock command sent successfully!"})
        else:
            return jsonify({"answer": "Failed to send unlock command."}), 500
    
    elif "status" in question:
        # This part is a placeholder. To get status, the Flutter app
        # should subscribe to a status topic from the ESP32 directly.
        return jsonify({"answer": "Please check the app's dashboard for the latest status."})

    else:
        return jsonify({"answer": "Sorry, I can only understand commands to 'open' the safe or check the 'status'."})

# The Procfile will use Gunicorn to run the app

```
