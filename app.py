from flask import Flask, request, jsonify
from flask_cors import CORS
import paho.mqtt.client as mqtt

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














































