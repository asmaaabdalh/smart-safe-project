FROM python:3.9-slim

WORKDIR /app

# تثبيت الاعتمادات النظامية المطلوبة
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*



RUN pip install --no-cache-dir flask flask_cors paho-mqtt langchain langchain-google-genai supabase

# نسخ باقي الملفات
COPY . .

# فتح المنفذ
EXPOSE 8000

# أمر التشغيل
CMD ["python", "app.py"]