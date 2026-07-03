import time

from . import config, paragraph_pipeline


def run_correction(corrector, raw_text: str) -> tuple[str, float]:
    start = time.perf_counter()
    final_text = paragraph_pipeline.correct_text(
        corrector, raw_text, timeout_seconds=config.PARAGRAPH_TIMEOUT_SECONDS
    )
    elapsed = time.perf_counter() - start
    return final_text, elapsed
