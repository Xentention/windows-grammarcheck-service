FROM python:3.11-slim

WORKDIR /app

# Build tools needed by some packages' native extensions (e.g. sentencepiece).
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# CPU-only torch wheel, installed before requirements.txt so it's already
# satisfied when pip processes that file -- prevents pulling the default
# multi-GB CUDA-bundled wheel, which this CPU-only image never uses.
RUN pip install --no-cache-dir torch==2.3.1 --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# HF cache location for any tokenizer/config lookups at runtime.
ENV HF_HOME=/root/.cache/huggingface
ENV PYTHONUNBUFFERED=1

COPY app/ ./app/
COPY scripts/ ./scripts/

EXPOSE 8501

CMD ["python", "-m", "app.server"]
