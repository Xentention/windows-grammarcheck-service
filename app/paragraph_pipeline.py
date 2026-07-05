import concurrent.futures
import contextvars
import logging
import re

from . import punctuation

logger = logging.getLogger(__name__)

_PARAGRAPH_SPLIT_RE = re.compile(r"(\n{1,})")


def split_paragraphs(text: str) -> list[str]:
    return _PARAGRAPH_SPLIT_RE.split(text)


def _correct_line(corrector, line: str, timeout_seconds: float, line_label: str) -> str:
    if not line.strip():
        return line

    logger.info("%s: sending to grammar model (chars=%d)", line_label, len(line))
    ctx = contextvars.copy_context()
    executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)
    try:
        future = executor.submit(ctx.run, corrector.correct, line)
        result = future.result(timeout=timeout_seconds)
        logger.info("%s: grammar correction done", line_label)
        return result
    except concurrent.futures.TimeoutError:
        logger.warning(
            "%s: timed out after %.1fs (length=%d); returning original text",
            line_label, timeout_seconds, len(line),
        )
        return line
    except Exception:
        logger.exception(
            "%s: grammar correction failed (length=%d); returning original text",
            line_label, len(line),
        )
        return line
    finally:
        executor.shutdown(wait=False)


def correct_paragraph(corrector, paragraph: str, timeout_seconds: float, para_label: str) -> str:
    if not paragraph.strip():
        return paragraph

    lines = paragraph.split("\n")
    logger.info("%s: correcting %d line(s)", para_label, len(lines))
    corrected = "\n".join(
        _correct_line(corrector, line, timeout_seconds, f"{para_label} line {i}/{len(lines)}")
        for i, line in enumerate(lines, start=1)
    )

    logger.info("%s: applying punctuation model", para_label)
    result = punctuation.apply(corrected)
    logger.info("%s: done", para_label)
    return result


def correct_text(corrector, text: str, timeout_seconds: float) -> str:
    segments = split_paragraphs(text)
    total_paragraphs = sum(1 for segment in segments if segment.strip())
    logger.info("split into %d paragraph(s)", total_paragraphs)

    corrected = []
    para_num = 0
    for segment in segments:
        if not segment.strip():
            corrected.append(segment)
            continue
        para_num += 1
        para_label = f"paragraph {para_num}/{total_paragraphs}"
        corrected.append(correct_paragraph(corrector, segment, timeout_seconds, para_label))

    return "".join(corrected)
