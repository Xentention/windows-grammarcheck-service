FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir torch==2.3.1 --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

ENV HF_HOME=/root/.cache/huggingface
ENV PYTHONUNBUFFERED=1

COPY app/ ./app/

ARG PORT=8501
ENV PORT=${PORT}
ENV HOST=0.0.0.0
EXPOSE ${PORT}

CMD ["python", "-m", "app.server"]
