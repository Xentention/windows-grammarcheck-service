import logging
import re

from optimum.onnxruntime import ORTModelForTokenClassification
from transformers import AutoTokenizer, pipeline

from . import config

logger = logging.getLogger(__name__)

_CASE_PREFIXES = ["UPPER_TOTAL", "UPPER", "LOWER"]
_CASE_FNS = {
    "LOWER": lambda w: w,
    "UPPER": lambda w: w.capitalize(),
    "UPPER_TOTAL": lambda w: w.upper(),
}
_PUNCT_SUFFIXES = {
    "O": "",
    "PERIOD": ".",
    "COMMA": ",",
    "QUESTION": "?",
    "TIRE": "—",
    "DVOETOCHIE": ":",
    "VOSKL": "!",
    "PERIODCOMMA": ";",
    "DEFIS": "-",
    "MNOGOTOCHIE": "...",
    # QUESTIONVOSKL this token was removed due to frequent false positives (when the ?! is rarely used irl)
}
_TIRE_SPACE_CASES = {"UPPER", "UPPER_TOTAL"}

_PUNCT_NO_SPACE_BEFORE = {".", ",", "!", "?", ":", ";", "—", "..."}
_CLOSERS = {")", "]", "}", "»", "”", "’"}
_OPENERS = {"(", "[", "{", "«", "“", "‘"}
_AMBIGUOUS_QUOTES = {'"', "'"}
_NO_SPACE_BEFORE = _PUNCT_NO_SPACE_BEFORE | _CLOSERS

_MARK_END_CHARS = {".", ",", "!", "?", ":", ";", "-", "—"}

_escaped_end_chars = "".join([re.escape(c) for c in _MARK_END_CHARS])
_COLLAPSE_SAME_PATTERN = re.compile(rf"([{_escaped_end_chars}])\1+")
_MIXED_END_MARKS_PATTERN = re.compile(
    rf"([{_escaped_end_chars}])"  # first char (group 1)
    rf"([{_escaped_end_chars}]*)"  # following (group 2)
)

_DOUBLE_MARKS = {"?!", "!?"}
_QV_CHARS = {"?", "!"}


def _mirrored_combo(original: str, start: int, end: int) -> str:
    span = original[start:end]
    return span if span in _DOUBLE_MARKS else ""


_classifier = None


def _split_label(label: str) -> tuple[str, str]:
    for prefix in _CASE_PREFIXES:
        if label.startswith(prefix + "_"):
            return prefix, label[len(prefix) + 1:]
    raise ValueError(f"Unrecognized RUPunct label: {label}")


def _render_token(word: str, label: str, original: str, end: int) -> str:
    case, punct_key = _split_label(label)
    cased = _CASE_FNS[case](word)

    if punct_key == "QUESTIONVOSKL":
        suffix = _mirrored_combo(original, end, end + 2)
        if not suffix:
            next_char = original[end:end + 1]
            suffix = next_char if next_char in _QV_CHARS else "?"
    else:
        suffix = _PUNCT_SUFFIXES[punct_key]
        if suffix in _QV_CHARS and cased and cased[-1] in _QV_CHARS and cased[-1] != suffix:
            if _mirrored_combo(original, end - 1, end + 1) != cased[-1] + suffix:
                suffix = ""

    if suffix and (cased == suffix or cased.endswith(suffix)):
        suffix = ""

    if suffix and punct_key == "TIRE" and case in _TIRE_SPACE_CASES:
        return f"{cased} {suffix}"
    return cased + suffix


def _separator(prev_piece: str, next_piece: str, gap: str) -> str:
    if "\n" in gap:
        return "\n"
    if next_piece == "-" or prev_piece == "-":
        return " " if " " in gap else ""
    if next_piece and next_piece[0] in _NO_SPACE_BEFORE:
        return ""
    return " "


def _reconstruct(original: str, predictions: list[dict]) -> str:
    pieces: list[str] = []
    prev_end = 0
    for item in predictions:
        word = original[item["start"]:item["end"]].strip()
        if not word:
            continue
        rendered = _render_token(word, item["entity_group"], original, item["end"])
        if pieces:
            gap = original[prev_end:item["start"]]
            pieces.append(_separator(pieces[-1], rendered, gap))
        pieces.append(rendered)
        prev_end = item["end"]
    return "".join(pieces)


def _fix_bracket_spacing(text: str) -> str:
    quote_open = False
    skip_space = False
    out: list[str] = []
    for ch in text:
        is_ambiguous = ch in _AMBIGUOUS_QUOTES
        is_open = ch in _OPENERS or (is_ambiguous and not quote_open)
        is_close = ch in _CLOSERS or (is_ambiguous and quote_open)
        if is_ambiguous:
            quote_open = not quote_open

        if ch == " " and skip_space:
            continue
        if is_close:
            while out and out[-1] == " ":
                out.pop()

        out.append(ch)
        skip_space = is_open
    return "".join(out)

_ELLIPSIS_PATTERN = re.compile(r"\.{3,}")
_ELLIPSIS_PLACEHOLDER = "\u0000ELLIPSIS\u0000"
def _collapse_duplicates(text: str) -> str:
    result = _ELLIPSIS_PATTERN.sub(_ELLIPSIS_PLACEHOLDER, text)
    result = _COLLAPSE_SAME_PATTERN.sub(r"\1", result)

    def _keep_last(m: re.Match) -> str:
        full = m.group(0)
        return full[-1]

    result = _MIXED_END_MARKS_PATTERN.sub(_keep_last, result)
    return result.replace(_ELLIPSIS_PLACEHOLDER, "...")



def load() -> None:
    """Eagerly loads the model/tokenizer once so the first request isn't slowed down."""
    global _classifier
    if _classifier is None:
        tokenizer = AutoTokenizer.from_pretrained(
            config.PUNCT_MODEL_DIR, strip_accents=False, add_prefix_space=True
        )
        model = ORTModelForTokenClassification.from_pretrained(config.PUNCT_MODEL_DIR)
        _classifier = pipeline(
            "ner", model=model, tokenizer=tokenizer, aggregation_strategy="first"
        )


def apply(text: str) -> str:
    if not text.strip():
        return text

    try:
        load()
        predictions = _classifier(text)
        result = _reconstruct(text, predictions)
        result = _fix_bracket_spacing(result)
        result = _collapse_duplicates(result)
        return result
    except Exception:
        logger.exception("RUPunct postprocessing failed; returning input unchanged.")
        return text
