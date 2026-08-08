import os
import httpx
from typing import Optional

class TranslationProviderAdapter:
    """
    Plug-and-play adapter for Real Machine Translation APIs.
    Supports Google Cloud Translation API v2/v3 and DeepL API v2.
    """
    def __init__(self):
        self.api_key = os.getenv("TRANSLATION_API_KEY", "").strip()
        self.provider = os.getenv("TRANSLATION_PROVIDER", "GOOGLE").strip().upper()

    async def translate_text(self, text: str, target_locale: str, source_locale: Optional[str] = None) -> str:
        if not self.api_key:
            raise ValueError("TRANSLATION_API_KEY is not configured on server. Please set TRANSLATION_API_KEY in Railway secrets.")
        
        if self.provider == "DEEPL":
            return await self._translate_deepl(text, target_locale, source_locale)
        else:
            return await self._translate_google(text, target_locale, source_locale)

    async def _translate_google(self, text: str, target_locale: str, source_locale: Optional[str]) -> str:
        loc_lower = target_locale.lower()
        if "zh" in loc_lower:
            target = "zh-CN"
        elif loc_lower.startswith("en"):
            target = "en"
        elif loc_lower.startswith("ja"):
            target = "ja"
        elif loc_lower.startswith("ko"):
            target = "ko"
        else:
            target = target_locale

        url = f"https://translation.googleapis.com/language/translate/v2?key={self.api_key}"
        payload = {
            "q": text,
            "target": target,
            "format": "text"
        }
        if source_locale:
            payload["source"] = source_locale

        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(url, json=payload)
            if res.status_code == 200:
                data = res.json()
                return data["data"]["translations"][0]["translatedText"]
            else:
                raise RuntimeError(f"Google Translate API Error ({res.status_code}): {res.text}")

    async def _translate_deepl(self, text: str, target_locale: str, source_locale: Optional[str]) -> str:
        target = "ZH" if target_locale.lower() in ["zh_hans", "zh-hans", "zh"] else target_locale.upper()
        url = "https://api-free.deepl.com/v2/translate" if "free" in self.api_key or ":fx" in self.api_key else "https://api.deepl.com/v2/translate"
        headers = {
            "Authorization": f"DeepL-Auth-Key {self.api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "text": [text],
            "target_lang": target
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(url, json=payload, headers=headers)
            if res.status_code == 200:
                data = res.json()
                return data["translations"][0]["text"]
            else:
                raise RuntimeError(f"DeepL API Error ({res.status_code}): {res.text}")
