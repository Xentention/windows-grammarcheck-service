import logging
import threading
import time

from .logging_config import start_request
from .pipeline import run_correction

logger = logging.getLogger(__name__)

_DUMMY_TEXT = "превет\nя прагриваю мадель"

class KeepAliveWarmer:
    def __init__(self, corrector, idle_seconds: float) -> None:
        self._corrector = corrector
        self._idle_seconds = idle_seconds
        self._last_activity = time.monotonic()
        self._active_requests = 0
        self._lock = threading.Lock()

    def touch(self) -> None:
        with self._lock:
            self._last_activity = time.monotonic()

    def request_started(self) -> None:
        with self._lock:
            self._active_requests += 1
            self._last_activity = time.monotonic()

    def request_finished(self) -> None:
        with self._lock:
            self._active_requests -= 1
            self._last_activity = time.monotonic()

    def _remaining_idle(self) -> float:
        with self._lock:
            return self._idle_seconds - (time.monotonic() - self._last_activity)

    def _should_warm_up(self) -> bool:
        with self._lock:
            return self._active_requests == 0

    def _run_loop(self) -> None:
        while True:
            remaining = self._remaining_idle()
            if remaining > 0:
                time.sleep(remaining)
                continue
            if self._should_warm_up():
                self._warm_up()
            else:
                time.sleep(self._idle_seconds)

    def _warm_up(self) -> None:
        start_request(_DUMMY_TEXT)
        logger.info("keep-alive warm-up starting")
        try:
            run_correction(self._corrector, _DUMMY_TEXT)
            logger.info("keep-alive warm-up completed")
        except Exception:
            logger.exception("keep-alive warm-up failed")
        finally:
            self.touch()

    def start(self) -> None:
        threading.Thread(target=self._run_loop, daemon=True).start()
