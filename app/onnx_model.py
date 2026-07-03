import logging
import time

from transformers import AutoTokenizer
from optimum.onnxruntime import ORTModelForSeq2SeqLM

logger = logging.getLogger(__name__)


class SageOnnxCorrector:
    def __init__(
        self,
        model_dir: str,
        max_new_tokens_multiplier: float = 1.5,
        max_input_tokens: int = 512,
    ) -> None:
        self.max_new_tokens_multiplier = max_new_tokens_multiplier
        self.max_input_tokens = max_input_tokens
        self.tokenizer = AutoTokenizer.from_pretrained(model_dir)
        self.model = ORTModelForSeq2SeqLM.from_pretrained(
            model_dir, use_cache=True, provider="CPUExecutionProvider"
        )

    def correct(self, text: str) -> str:
        start = time.perf_counter()
        inputs = self.tokenizer(
            text,
            truncation=True,
            max_length=self.max_input_tokens,
            return_tensors="pt",
        )
        input_tokens = inputs["input_ids"].shape[1]
        max_new_tokens = int(input_tokens * self.max_new_tokens_multiplier) + 10
        outputs = self.model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            num_beams=1,
            do_sample=False,
        )
        result = self.tokenizer.batch_decode(outputs, skip_special_tokens=True)[0]
        logger.info(
            "grammar model inference done (input_tokens=%d, elapsed=%.3fs)",
            input_tokens, time.perf_counter() - start,
        )
        return result
