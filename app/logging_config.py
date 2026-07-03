"""Central logging configuration.

Every log line carries a timestamp and the id of the request that produced
it, so the full lifecycle of one request can be found with a single grep --
even across the background keep-alive warm-ups. The id is generated once per
request/warm-up cycle and bound to a contextvar; a logging.Filter then stamps
every record with it automatically, so call sites just do `logger.info(...)`
without passing the id around.

Threads spawned via ThreadPoolExecutor do NOT inherit the caller's contextvars
by default -- callers that hop threads must propagate it explicitly with
`contextvars.copy_context().run(...)` (see paragraph_pipeline._correct_line).
"""
import contextvars
import logging
import logging.config
import re
import uuid

request_id_var: contextvars.ContextVar[str] = contextvars.ContextVar("request_id", default="-")

_WORD_RE = re.compile(r"\S+", re.UNICODE)
_NON_WORD_RE = re.compile(r"[^\w]+", re.UNICODE)
_SLUG_MAX_WORDS = 3
_SLUG_MAX_WORD_LEN = 20


class _RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_var.get()
        return True


LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "filters": {
        "request_id": {"()": _RequestIdFilter},
    },
    "formatters": {
        "default": {
            "format": "%(asctime)s | %(request_id)s | %(levelname)s | %(name)s: %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "default",
            "filters": ["request_id"],
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
}


def configure_logging() -> None:
    logging.config.dictConfig(LOGGING_CONFIG)


def new_request_id(text: str) -> str:
    """Builds a request id starting with up to 3 words of the input text, so a
    request can be found later by grepping logs for what was submitted."""
    words = _WORD_RE.findall(text.strip())[:_SLUG_MAX_WORDS]
    slug_parts = [_NON_WORD_RE.sub("", w)[:_SLUG_MAX_WORD_LEN] for w in words]
    slug = "_".join(part for part in slug_parts if part).lower()
    suffix = uuid.uuid4().hex[:8]
    return f"{slug}-{suffix}" if slug else suffix


def start_request(text: str) -> str:
    """Generates a request id for `text` and binds it to the current thread's
    logging context; every `logger.*` call made afterwards on this thread
    (or a thread that explicitly propagates this context) is tagged with it."""
    request_id = new_request_id(text)
    request_id_var.set(request_id)
    return request_id
