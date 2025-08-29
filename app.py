# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
import paho.mqtt.client as mqtt
from langchain.agents import initialize_agent, AgentType
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.tools import tool
import threading
import time
from supabase import create_client, Client
from datetime import datetime
import os

# --- Configuration (Hardcoded as requested for now) ---
SUPABASE_URL = "https://cojyysahbrvpqtydwscz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvanl5c2FoYnJ2cHF0eWR3c2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Njk3NDYsImV4cCI6MjA3MTM0NTc0Nn0.lHn2ZKH_C281H6wQXc-v3IndA9SK9r3rryglddnbHbk"
GOOGLE_API_KEY = "AIzaSyAW72R-ccn0rqdDvzrDTMRlpmAB-3ZxZgU"

# MQTT Broker settings
BROKER = "dfc251f747a74e7f9c297471a17708ba.s1.eu.hivemq.cloud"
PORT = 8883
USERNAME = "IOTclaster"
PASSWORD = "4B&3.KpGQm28uZ>hczC!" # <-- IMPORTANT: REPLACE WITH YOUR HIVEMQ PASSWORD

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
    """Sets up and runs the MQTT client in a separate thread."""
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    client.username_pw_set(USERNAME, PASSWORD)
    client.tls_set() # Enable SSL/TLS

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

    try:
        client.connect(BROKER, PORT, 60)
        client.loop_forever() # Keeps the connection alive in the background
    except Exception as e:
        print(f"MQTT connection error: {e}")

# Start the MQTT client in a background thread
mqtt_thread = threading.Thread(target=setup_mqtt_client)
mqtt_thread.daemon = True
mqtt_thread.start()

# --- Tool Functions ---
@tool
def get_system_status():
    """Gets the current status of the safe's sensors (IR and LDR)."""
    return f"Current IR reading is {latest_ir}. Current LDR reading is {latest_ldr}."

@tool
def open_door():
    """Sends the command to open the safe door."""
    # This is a temporary client instance for publishing, as the main client runs in a thread
    pub_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    pub_client.username_pw_set(USERNAME, PASSWORD)
    pub_client.tls_set()
    pub_client.connect(BROKER, PORT, 60)
    pub_client.publish("safe/password", "1234")
    pub_client.disconnect()
    return "Unlock command sent to the safe."

# --- Agent Setup ---
llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash", google_api_key=GOOGLE_API_KEY)
tools = [get_system_status, open_door]
agent = initialize_agent(
    tools=tools,
    llm=llm,
    agent=AgentType.STRUCTURED_CHAT_ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,
    handle_parsing_errors=True
)

# --- Flask Routes ---
@app.route('/')
def home():
    return "Smart Safe API is running!"

@app.route('/ask', methods=['POST'])
def ask():
    question = request.json.get('question')
    if not question:
        return jsonify({"answer": "Please provide a question."}), 400
        
    try:
        answer = agent.run(question)
        return jsonify({"answer": answer})
    except Exception as e:
        print(f"Agent error: {e}")
        return jsonify({"answer": "Sorry, an error occurred."}), 500
