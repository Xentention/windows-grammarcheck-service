import concurrent.futures
import logging
import sys
import time
from pathlib import Path

from flask import Flask, render_template, request

from . import config, punctuation
from .keepalive import KeepAliveWarmer
from .logging_config import configure_logging, start_request
from .onnx_model import SageOnnxCorrector
from .pipeline import run_correction

configure_logging()
logger = logging.getLogger(__name__)

app = Flask(__name__)

_REQUIRED_MODELS = {
    "grammar correction (sage)": config.ONNX_MODEL_DIR,
    "punctuation restoration (RUPunct)": config.PUNCT_MODEL_DIR,
}
_missing = [
    f"{name} -> {model_dir}"
    for name, model_dir in _REQUIRED_MODELS.items()
    if not Path(model_dir, config.BUILD_COMPLETE_MARKER).exists()
]
if _missing:
    logger.error(
        "Missing %s marker(s) for: %s -- run the model build steps first, "
        "e.g. `docker compose run --rm build-model` and `docker compose run --rm build-punct-model`.",
        config.BUILD_COMPLETE_MARKER,
        ", ".join(_missing),
    )
    sys.exit(1)

logger.info("Loading grammar and punctuation models...")
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as _startup_pool:
    _corrector_future = _startup_pool.submit(
        SageOnnxCorrector,
        config.ONNX_MODEL_DIR,
        max_new_tokens_multiplier=config.MAX_NEW_TOKENS_MULTIPLIER,
        max_input_tokens=config.MAX_INPUT_TOKENS,
    )
    _punct_future = _startup_pool.submit(punctuation.load)
    corrector = _corrector_future.result()
    _punct_future.result()
logger.info("Models loaded.")

warmer = KeepAliveWarmer(corrector, config.KEEPALIVE_IDLE_SECONDS)
warmer.start()


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/correct", methods=["POST"])
def correct():
    start = time.perf_counter()
    data = request.get_json(force=True, silent=True) or {}
    text = data.get("text") or ""
    start_request(text)
    logger.info("request received (chars=%d)", len(text))

    warmer.request_started()
    try:
        corrected, elapsed = run_correction(corrector, text)
        logger.info("request completed (elapsed=%.3fs)", elapsed)
    except Exception:
        logger.exception("request failed; returning last achieved result")
        corrected, elapsed = text, time.perf_counter() - start
    finally:
        warmer.request_finished()

    return {
        "corrected": corrected,
        "elapsed_seconds": round(elapsed, 3),
        "elapsed_seconds_str": f"{elapsed:.3f}s",
    }


@app.route("/health")
def health():
    return {"status": "ok"}, 200


def build_server():
    from waitress import create_server

    return create_server(app, host=config.HOST, port=config.PORT)


if __name__ == "__main__":
    build_server().run()
