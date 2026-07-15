import os
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR: str = os.environ.get("MODELS_DIR", str(_REPO_ROOT / "models"))
# sage-fredt5 quantization: "int8" (default, higher quality) or "int4" (smaller/faster).
SAGE_QUANT: str = os.environ.get("SAGE_QUANT", "int8")

ONNX_MODEL_DIR: str = os.environ.get("ONNX_MODEL_DIR", str(Path(MODELS_DIR) / f"sage-fredt5-large-onnx-{SAGE_QUANT}"))
PARAGRAPH_TIMEOUT_SECONDS: float = float(os.environ.get("PARAGRAPH_TIMEOUT_SECONDS", "30"))
MAX_NEW_TOKENS_MULTIPLIER: float = float(os.environ.get("MAX_NEW_TOKENS_MULTIPLIER", "1.5"))
MAX_INPUT_TOKENS: int = int(os.environ.get("MAX_INPUT_TOKENS", "512"))
PUNCT_MODEL_DIR: str = os.environ.get("PUNCT_MODEL_DIR", str(Path(MODELS_DIR) / "rupunct-big-onnx"))
HOST: str = os.environ.get("HOST", "127.0.0.1") 
PORT: int = int(os.environ.get("PORT", "8501"))
KEEPALIVE_IDLE_SECONDS: float = float(os.environ.get("KEEPALIVE_IDLE_SECONDS", "240"))
