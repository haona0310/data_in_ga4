import os

from dotenv import load_dotenv
from google import genai

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
model = os.getenv("GEMINI_MODEL")
if not api_key:
    raise ValueError("Thiếu GEMINI_API_KEY trong file .env")

client = genai.Client(api_key=api_key)

# Liệt kê các model dùng được để sinh văn bản
print("Các model khả dụng:")
for m in client.models.list():
    actions = getattr(m, "supported_actions", None) or []
    if "generateContent" in actions:
        print(" ", m.name)

# Nếu đã chọn model trong .env thì gọi thử
if model:
    response = client.models.generate_content(
        model=model,
        contents="Trả lời đúng một câu: 1 + 1 bằng mấy?",
    )
    print("\nPhản hồi:", response.text)