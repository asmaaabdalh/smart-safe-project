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

# Configuration (hardcoded as requested)
BROKER = "broker.hivemq.com"
PORT = 1883
SUPABASE_URL = "https://cojyysahbrvpqtydwscz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvanl5c2FoYnJ2cHF0eWR3c2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Njk3NDYsImV4cCI6MjA3MTM0NTc0Nn0.lHn2ZKH_C281H6wQXc-v3IndA9SK9r3rryglddnbHbk"
GOOGLE_API_KEY = "AIzaSyDcg_dCP3mEa0fxhEA8pZfvqoewQZUKclw"

# MQTT Setup
TOPIC_LED = "safe/led"
TOPIC_SERVO = "safe/servo"
TOPIC_IR = "safe/ir"
TOPIC_LDR = "safe/ldr"
TOPIC_PASSWORD = "safe/password"
TOPIC_BUZZER = "safe/buzzer"
TOPIC_REQUEST_UPDATE = "safe/request_update"

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
def log_to_supabase(message):
    data = {
        "message": message,
        "created_at": datetime.now().isoformat()
    }
    supabase.table("Chatbot").insert(data).execute()
    print(f"Logged to Supabase: {message}")

# Tool Functions - using the @tool decorator
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
    # Request latest sensor data
    mqtt_client.publish(TOPIC_REQUEST_UPDATE, "update")
    
    # Wait a moment for the ESP32 to respond
    time.sleep(0.5)
    
    status = ""
    if latest_ir is not None:
        status += f"IR: {'Motion detected' if latest_ir == 1 else 'No motion'}, "
    if latest_ldr is not None:
        light_status = "Bright" if latest_ldr > 1000 else "Dark"
        status += f"LDR: {light_status} ({latest_ldr})"
    
    result = status or "No sensor data available"
    log_to_supabase(f"System status requested: {result}")
    return result

@tool
def get_access_logs():
    """Get the 10 most recent access logs from the database."""
    response = supabase.table("Chatbot").select("*").order("created_at", desc=True).limit(10).execute()
    logs = response.data
    if logs:
        result = "Recent access logs:\n"
        for log in logs:
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

# Initialize the LLM
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=GOOGLE_API_KEY
)

# Initialize the agent
agent = initialize_agent(
    tools=tools,
    llm=llm,
    agent=AgentType.STRUCTURED_CHAT_ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,
    handle_parsing_errors=True
)

# Flask routes
@app.route('/')
def home():
    return "Safe Box IoT Assistant API is running!"

@app.route('/chat', methods=['POST'])
def chat():
    try:
        user_message = request.json.get('text', '')
        if not user_message:
            return jsonify({'reply': 'Please provide a message'})
        
        # Use the agent to process the message
        response = agent.run(system_prompt + "\nUser: " + user_message)
        return jsonify({'reply': response})
    
    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        return jsonify({'reply': 'Sorry, I encountered an error processing your request.'})

@app.route('/status', methods=['GET'])
def status():
    """Get current system status"""
    status = get_system_status()
    return jsonify({'status': status})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
