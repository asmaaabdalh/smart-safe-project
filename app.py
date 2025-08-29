from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai
import os

# --- إعداد مفتاح Google Gemini API ---
GOOGLE_API_KEY = "AIzaSyDvVAbbleCffbB7MokYD2LCgCJAD9SJfgQ"  # حطي هنا الـ API Key اللي جبناه من Google AI Studio
genai.configure(api_key=GOOGLE_API_KEY)

# إنشاء موديل Gemini
model = genai.GenerativeModel("gemini-1.5-flash")

# --- Flask App ---
app = Flask(__name__)
CORS(app)

@app.route("/")
def home():
    return "Smart Safe Chatbot API is running with Gemini AI!"

@app.route("/ask", methods=["POST"])
def ask():
    try:
        data = request.json
        question = data.get("question", "")

        if not question:
            return jsonify({"answer": "Please provide a question."}), 400

        # استدعاء Gemini API
        response = model.generate_content(question)
        answer = response.text if response else "Sorry, I couldn’t get an answer."

        return jsonify({"answer": answer})

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"answer": "An error occurred while processing your request."}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
