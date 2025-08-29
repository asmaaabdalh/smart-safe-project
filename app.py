from flask import Flask, request, jsonify
from flask_cors import CORS
import paho.mqtt.client as mqtt
from supabase import create_client, Client
from datetime import datetime
import os
import google.generativeai as genai   # <-- مكتبة جوجل Gemini

# --- Configuration ---
SUPABASE_URL = "https://cojyysahbrvpqtydwscz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
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

# --- Setup Google Gemini ---
genai.configure(api_key=GOOGLE_API_KEY)
model = genai.GenerativeModel("gemini-pro")  # موديل النصوص

# --- MQTT Client Logic ---
def setup_mqtt_client():
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    client.username_pw_set(USERNAME, PASSWORD)
    client.tls_set()

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
    client.loop_start()
    return client

mqtt_client = setup_mqtt_client()

# --- Chatbot Route ---
@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json()
    question = data.get("question", "")
    print(f"Received question: {question}")

    try:
        response = model.generate_content(question)
        answer = response.text.strip()
    except Exception as e:
        print(f"Error from Gemini: {e}")
        answer = "Sorry, I had trouble getting an answer from AI."

    return jsonify({"answer": answer})

# --- Test Route ---
@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Smart Safe API is running 🚀"})

# --- Run App ---
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
