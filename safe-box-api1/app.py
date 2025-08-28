from flask import Flask, request, jsonify
from flask_cors import CORS
import paho.mqtt.client as mqtt
from langchain.agents import initialize_agent, AgentType
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.tools import tool
import threading
import time
import os
from supabase import create_client, Client
from datetime import datetime

# NOTE: Environment variables are hardcoded for demonstration.
# This is a bad practice for security and maintainability.
BROKER = "broker.hivemq.com"
PORT = 1883
SUPABASE_URL = "https://cojyysahbrvpqtydwscz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvanl5c2FoYnJ2cHF0eWR3c2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Njk3NDYsImV4cCI6MjA3MTM0NTc0Nn0.lHn2ZKH_C281H6wQXc-v3IndA9SK9r3rryglddnbHbk"
GOOGLE_API_KEY = "AIzaSyAW72R-ccn0rqdDvzrDTMRlpmAB-3ZxZgU"

# MQTT Setup
TOPIC_LED = "safe/led"
TOPIC_SERVO = "safe/servo"
TOPIC_IR = "safe/ir"
TOPIC_LDR = "safe/ldr"
TOPIC_PASSWORD = "safe/password"
TOPIC_BUZZER = "safe/buzzer"

# Supabase Setup
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

app = Flask(__name__)
CORS(app)

# Global state variables
latest_ir = None
latest_ldr = None

# MQTT Client setup with fixed callback signature
mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)

def on_connect(client, userdata, flags, rc, properties=None):
    print("Connected with result code", rc)
    client.subscribe(TOPIC_IR)
    client.subscribe(TOPIC_LDR)

def on_message(client, userdata, msg):
    global latest_ir, latest_ldr
    
    if msg.topic == TOPIC_IR:
        latest_ir = int(msg.payload.decode())
        log_to_supabase(f"IR sensor reading: {latest_ir}")
    
    elif msg.topic == TOPIC_LDR:
        latest_ldr = int(msg.payload.decode())
        log_to_supabase(f"LDR sensor reading: {latest_ldr}")

mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message
mqtt_client.connect(BROKER, PORT, 60)
mqtt_client.loop_start()

# Function to log messages to Supabase
# MODIFIED: Changed table name to "Chatbot"
def log_to_supabase(message):
    data = {
        "message": message,
        "created_at": datetime.now().isoformat()
    }
    # Changed table name to match the Supabase schema
    supabase.table("Chatbot").insert(data).execute()
    print(f"Logged to Supabase: {message}")

# Tool Functions - now using the @tool decorator
@tool
def get_ir_reading():
    """Get the latest IR sensor reading. Returns "IR reading not available" if no data."""
    result = str(latest_ir) if latest_ir is not None else "IR reading not available"
    log_to_supabase(f"IR reading requested: {result}")
    return result

@tool
def get_ldr_reading():
    """Get the latest LDR sensor reading. Returns "LDR reading not available" if no data."""
    result = str(latest_ldr) if latest_ldr is not None else "LDR reading not available"
    log_to_supabase(f"LDR reading requested: {result}")
    return result

@tool
def turn_led_on():
    """Turn the LED on."""
    mqtt_client.publish(TOPIC_LED, "on")
    log_to_supabase("LED turned on")
    return "LED turned on"

@tool
def turn_led_off():
    """Turn the LED off."""
    mqtt_client.publish(TOPIC_LED, "off")
    log_to_supabase("LED turned off")
    return "LED turned off"

@tool
def open_door():
    """Open the safe door. This action sends a password to the safe."""
    mqtt_client.publish(TOPIC_PASSWORD, "1234")
    log_to_supabase("Door opening command sent")
    return "Door opening command sent"

@tool
def close_door():
    """Close the safe door."""
    mqtt_client.publish(TOPIC_SERVO, "0")
    log_to_supabase("Door closing command sent")
    return "Door closing command sent"

@tool
def activate_buzzer():
    """Activate the buzzer alarm."""
    mqtt_client.publish(TOPIC_BUZZER, "on")
    log_to_supabase("Buzzer activated")
    return "Buzzer activated"

@tool
def deactivate_buzzer():
    """Deactivate the buzzer alarm."""
    mqtt_client.publish(TOPIC_BUZZER, "off")
    log_to_supabase("Buzzer deactivated")
    return "Buzzer deactivated"

@tool
def get_system_status():
    """Get the current status of all system components, including IR and LDR readings."""
    status = ""
    if latest_ir is not None:
        status += f"IR: {latest_ir}, "
    if latest_ldr is not None:
        status += f"LDR: {latest_ldr}"
    result = status or "No sensor data available"
    log_to_supabase(f"System status requested: {result}")
    return result

@tool
def get_access_logs():
    """Get the 10 most recent access logs from the database."""
    # MODIFIED: Changed table name to "Chatbot"
    response = supabase.table("Chatbot").select("*").order("created_at", desc=True).limit(10).execute()
    logs = response.data
    if logs:
        result = "Recent access logs:\n"
        for log in logs:
            # Assumes the column in 'Chatbot' is also named 'message'
            result += f"{log['created_at']}: {log['message']}\n"
        return result
    else:
        return "No access logs found"

# Collect all decorated tool functions
tools = [
    get_ir_reading,
    get_ldr_reading,
    turn_led_on,
    turn_led_off,
    open_door,
    close_door,
    activate_buzzer,
    deactivate_buzzer,
    get_system_status,
    get_access_logs,
]

system_prompt = """
You are an IoT safe system assistant. You control a secure safe with the following components:
- IR sensor: detects motion near the safe
- LDR sensor: measures light levels
- LED: indicates status
- Servo motor: opens and closes the safe door
- Buzzer: sounds an alarm
- Database: stores access logs with timestamps

Available tools:
- get_ir_reading -> returns latest IR sensor value
- get_ldr_reading -> returns latest LDR sensor value
- turn_led_on -> turns the LED on
- turn_led_off -> turns the LED off
- open_door -> opens the safe door
- close_door -> closes the safe door
- activate_buzzer -> activates the buzzer alarm
- deactivate_buzzer -> deactivates the buzzer alarm
- get_system_status -> returns current status of all components
- get_access_logs -> returns recent access logs from the database

Rules:
1. ALWAYS use the tools - just call the appropriate tool.
2. For security reasons, you can only open the door with the correct password.
3. All actions are automatically logged to the database.
4. None of the tools require any parameters - just call them by name.
"""

# Get API key from environment
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=GOOGLE_API_KEY
)

agent = initialize_agent(
    tools=tools,
    llm=llm,
    agent=AgentType.STRUCTURED_CHAT_ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,
    handle_parsing_errors=True,
    return_only_outputs=True
)

# Flask Routes
@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_input = data.get('text', '')
    
    log_to_supabase(f"User query: {user_input}")
    
    try:
        reply = agent.invoke({
            "input": user_input,
            "chat_history": [{"role": "system", "content": system_prompt}]
        })
        assistant_response = reply.get('output', '')
    except Exception as e:
        print(f"Error during agent invocation: {e}")
        assistant_response = "An internal error occurred. Please try again."
    
    log_to_supabase(f"Assistant response: {assistant_response}")
    
    return jsonify({'reply': assistant_response})

@app.route('/status', methods=['GET'])
def status():
    return jsonify({
        'ir_sensor': latest_ir,
        'ldr_sensor': latest_ldr
    })

@app.route('/logs', methods=['GET'])
def get_logs():
    limit = request.args.get('limit', 10, type=int)
    # MODIFIED: Changed table name to "Chatbot"
    response = supabase.table("Chatbot").select("*").order("created_at", desc=True).limit(limit).execute()
    return jsonify(response.data)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Docker"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'services': {
            'mqtt': mqtt_client.is_connected(),
            'supabase': SUPABASE_URL is not None
        }
    })

# Background thread to periodically request sensor updates
def sensor_update_loop():
    while True:
        # This topic is for the ESP32 to know when to send updates.
        # It's okay if it's not connected yet, the message will just be ignored.
        mqtt_client.publish("safe/request_update", "1") 
        time.sleep(5)

# Start the sensor update thread
sensor_thread = threading.Thread(target=sensor_update_loop, daemon=True)
sensor_thread.start()

if __name__ == '__main__':
    # NOTE: Debug mode is also hardcoded here
    debug_mode = True
    app.run(host='0.0.0.0', port=8000, debug=debug_mode)