FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir "faster-whisper>=1.0.0" "uvicorn>=0.23.0" "fastapi>=0.109.0" "pydantic>=2.5.0"

COPY app/ ./app/

EXPOSE 9001

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9001"]