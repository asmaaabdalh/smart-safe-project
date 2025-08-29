from flask import Flask, request, jsonify
from flask_cors import CORS
import paho.mqtt.client as mqtt
from supabase import create_client, Client
from datetime import datetime
import threading
import os

# --- Configuration ---
SUPABASE_URL = "https://cojyysahbrvpqtydwscz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvanl5c2FoYnJ2cHF0eWR3c2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Njk3NDYsImV4cCI6MjA3MTM0NTc0Nn0.lHn2ZKH_C281H6wQXc-v3IndA9SK9r3rryglddnbHbk"
GOOGLE_API_KEY = "AIzaSyAW72R-ccn0rqdDvzrDTMRlpmAB-3ZxZgU"

# MQTT Broker settings
BROKER = "dfc251f747a74e7f9c297471a17708ba.s1.eu.hivemq.cloud"
PORT = 8883
USERNAME = "IOTclaster"
PASSWORD = "4B&3.KpGQm28uZ>hczC!"

# Initialize Flask App
app = Flask(__name__)
CORS(app)

# --- Global Variables ---
latest_ir = "N/A"
latest_ldr = "N/A"

# --- Supabase Client ---
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- MQTT Client Logic ---
def setup_mqtt_client():
    """Sets up and returns the MQTT client."""
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    client.username_pw_set(USERNAME, PASSWORD)
    client.tls_set()  # Enable SSL/TLS

    def on_connect(client, userdata, flags, rc, properties=None):
        if rc == 0:
            print("MQTT: Connected to HiveMQ Broker!")
            client.subscribe("safe/ir")
            client.subscribe("safe/ldr")
        else:
            print(f"MQTT: Failed to connect, return code {rc}")

    def on_message(client, userdata, msg):
        global latest_ir, latest_ldr
        payload = msg.payload.decode()
        print(f"Received message on topic {msg.topic}: {payload}")
        if msg.topic == "safe/ir":
            latest_ir = payload
        elif msg.topic == "safe/ldr":
            latest_ldr = payload

    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(BROKER, PORT, 60)
    return client

# --- Flask Routes ---
@app.route("/")
def home():
    return jsonify({"message": "Smart Safe Chatbot running on Railway!"})

@app.route("/latest", methods=["GET"])
def get_latest():
    return jsonify({
        "ir": latest_ir,
        "ldr": latest_ldr,
        "timestamp": datetime.now().isoformat()
    })

# --- Entry Point ---
if __name__ == "__main__":
    # Setup MQTT client and run in background
    client = setup_mqtt_client()
    mqtt_thread = threading.Thread(target=client.loop_forever)
    mqtt_thread.daemon = True
    mqtt_thread.start()

    # Run Flask server on Railway-assigned port
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting Flask server on port {port}...")
    app.run(host="0.0.0.0", port=port)
