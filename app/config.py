import os
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent
_MODELS_DIR = _REPO_ROOT / "models"

MODEL_ID: str = os.environ.get("MODEL_ID", "ai-forever/sage-fredt5-large")
ONNX_MODEL_DIR: str = os.environ.get("ONNX_MODEL_DIR", str(_MODELS_DIR / "sage-fredt5-large-onnx-int4"))
PARAGRAPH_TIMEOUT_SECONDS: float = float(os.environ.get("PARAGRAPH_TIMEOUT_SECONDS", "30"))
MAX_NEW_TOKENS_MULTIPLIER: float = float(os.environ.get("MAX_NEW_TOKENS_MULTIPLIER", "1.5"))
MAX_INPUT_TOKENS: int = int(os.environ.get("MAX_INPUT_TOKENS", "512"))
PUNCT_MODEL_ID: str = os.environ.get("PUNCT_MODEL_ID", "RUPunct/RUPunct_big")
PUNCT_MODEL_DIR: str = os.environ.get("PUNCT_MODEL_DIR", str(_MODELS_DIR / "rupunct-big-onnx"))
HOST: str = os.environ.get("HOST", "0.0.0.0")
PORT: int = int(os.environ.get("PORT", "8501"))
KEEPALIVE_IDLE_SECONDS: float = float(os.environ.get("KEEPALIVE_IDLE_SECONDS", "240"))

BUILD_COMPLETE_MARKER: str = ".build_complete"
