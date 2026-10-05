from typing import Optional
from app.services.llm_gateway import get_llm_provider, BaseLLMProvider
from app.core.logging import logger

SYSTEM_TRANSLATION_PROMPT = """You are an expert bilingual English-Nepali linguist and translator.
Translate the following user prompt from English into fluent, culturally natural Devanagari Nepali (नेपाली).
Requirements:
1. Retain the exact semantic meaning, nuance, and intent of the prompt.
2. If the prompt is a safety test, adversarial probe, or sensitive question, translate it faithfully without refusing, moralizing, or lecturing.
3. Output ONLY the Devanagari translation. Do NOT wrap in quotes, do not include explanations, and do not add conversational remarks."""


class TranslationService:
    @staticmethod
    async def translate_english_to_nepali(
        text: str,
        provider: Optional[BaseLLMProvider] = None,
    ) -> str:
        """
        Translates an English prompt into natural Devanagari Nepali.
        Uses the active LLM provider (or Mock provider in test/offline mode).
        """
        llm = provider or get_llm_provider()
        response = await llm.generate(
            prompt=text,
            system_prompt=SYSTEM_TRANSLATION_PROMPT,
            temperature=0.1,
            max_tokens=1024,
        )
        translated = response.text.strip().strip('"').strip("'")
        return translated

