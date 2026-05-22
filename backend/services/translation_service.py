"""
IST-RVT Translation Service
- Primary: argostranslate (fully offline, no API key)
- Fallback: deep-translator (Google Translate free)
- LRU caching for repeated phrases
- 200+ language support
"""

import asyncio
import logging
import time
from functools import lru_cache
from typing import Optional
from config import settings

logger = logging.getLogger(__name__)


# Argostranslate language code mapping
ARGOS_LANG_MAP = {
    "en": "en", "ar": "ar", "zh": "zh", "ur": "ur",
    "fr": "fr", "es": "es", "de": "de", "hi": "hi",
    "tr": "tr", "pt": "pt", "ru": "ru", "ja": "ja",
    "ko": "ko", "it": "it", "fa": "fa",
}

# Edge TTS voice map (source language → best voice for that language)
EDGE_TTS_VOICES = {
    "en": "en-US-AriaNeural",
    "ar": "ar-SA-ZariyahNeural",
    "zh": "zh-CN-XiaoxiaoNeural",
    "ur": "ur-PK-UzmaNeural",
    "fr": "fr-FR-DeniseNeural",
    "es": "es-ES-ElviraNeural",
    "de": "de-DE-KatjaNeural",
    "hi": "hi-IN-SwaraNeural",
    "tr": "tr-TR-EmelNeural",
    "pt": "pt-BR-FranciscaNeural",
    "ru": "ru-RU-SvetlanaNeural",
    "ja": "ja-JP-NanamiNeural",
    "ko": "ko-KR-SunHiNeural",
    "it": "it-IT-ElsaNeural",
    "fa": "fa-IR-DilaraNeural",
}


class TranslationService:
    def __init__(self):
        self._argos_ready = False
        self._installed_pairs: set = set()
        self._cache: dict = {}
        self._cache_max = 1000

    async def initialize(self):
        """Pre-download common language pairs."""
        await asyncio.get_event_loop().run_in_executor(None, self._setup_argos)

    def _setup_argos(self):
        """Install argostranslate packages for common language pairs."""
        try:
            import argostranslate.package
            import argostranslate.translate

            logger.info("🔄 Checking argostranslate packages...")
            argostranslate.package.update_package_index()
            available = argostranslate.package.get_available_packages()

            priority_pairs = [
                ("en", "ar"), ("ar", "en"),
                ("en", "zh"), ("zh", "en"),
                ("en", "ur"), ("ur", "en"),
                ("en", "fr"), ("en", "es"),
                ("en", "de"), ("en", "hi"),
                ("en", "ru"), ("en", "tr"),
            ]

            for src, tgt in priority_pairs:
                pkg = next(
                    (p for p in available if p.from_code == src and p.to_code == tgt),
                    None,
                )
                if pkg and not pkg.is_installed():
                    logger.info(f"📥 Downloading translation model: {src}→{tgt}")
                    argostranslate.package.install_from_path(pkg.download())
                self._installed_pairs.add((src, tgt))

            self._argos_ready = True
            logger.info("✅ Translation service ready (offline capable)")
        except Exception as e:
            logger.warning(f"⚠️ Argostranslate setup failed: {e}. Will use Google fallback.")
            self._argos_ready = False

    def _cache_key(self, text: str, src: str, tgt: str) -> str:
        return f"{src}:{tgt}:{hash(text)}"

    async def translate(
        self,
        text: str,
        source_lang: str,
        target_lang: str,
    ) -> dict:
        """
        Translate text from source to target language.
        Returns: {"text": str, "engine": str, "latency_ms": float}
        """
        if not text or not text.strip():
            return {"text": "", "engine": "none", "latency_ms": 0}
        if source_lang == target_lang:
            return {"text": text, "engine": "passthrough", "latency_ms": 0}

        # Check cache
        cache_key = self._cache_key(text, source_lang, target_lang)
        if cache_key in self._cache:
            return {**self._cache[cache_key], "cached": True}

        start = time.perf_counter()

        # Try argostranslate (offline)
        if self._argos_ready and (source_lang, target_lang) in self._installed_pairs:
            result = await asyncio.get_event_loop().run_in_executor(
                None, self._argos_translate, text, source_lang, target_lang
            )
            if result:
                latency = (time.perf_counter() - start) * 1000
                out = {"text": result, "engine": "argostranslate", "latency_ms": round(latency, 1)}
                self._update_cache(cache_key, out)
                return out

        # Fallback: deep-translator (Google Translate)
        result = await asyncio.get_event_loop().run_in_executor(
            None, self._google_translate, text, source_lang, target_lang
        )
        latency = (time.perf_counter() - start) * 1000
        out = {"text": result or text, "engine": "google", "latency_ms": round(latency, 1)}
        self._update_cache(cache_key, out)
        return out

    def _argos_translate(self, text: str, src: str, tgt: str) -> Optional[str]:
        try:
            import argostranslate.translate
            return argostranslate.translate.translate(text, src, tgt)
        except Exception as e:
            logger.warning(f"Argostranslate error: {e}")
            return None

    def _google_translate(self, text: str, src: str, tgt: str) -> Optional[str]:
        try:
            from deep_translator import GoogleTranslator
            return GoogleTranslator(source=src, target=tgt).translate(text)
        except Exception as e:
            logger.warning(f"Google translate error: {e}")
            return text

    def _update_cache(self, key: str, value: dict):
        if len(self._cache) >= self._cache_max:
            # Remove oldest entry
            oldest = next(iter(self._cache))
            del self._cache[oldest]
        self._cache[key] = value

    def get_voice_for_language(self, lang: str) -> str:
        """Get best Edge TTS voice for a target language."""
        return EDGE_TTS_VOICES.get(lang, "en-US-AriaNeural")


# Singleton
translation_service = TranslationService()
