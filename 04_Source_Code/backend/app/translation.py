import os
import json
import urllib.request
import urllib.error
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

        data_bytes = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=data_bytes,
            headers={"Content-Type": "application/json", "User-Agent": "NampoGoGo-Backend/1.0"},
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=10.0) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                return res_data["data"]["translations"][0]["translatedText"]
        except urllib.error.HTTPError as he:
            err_body = he.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"Google Translate API Error ({he.code}): {err_body}")
        except Exception as e:
            raise RuntimeError(f"Google Translate Connection Error: {str(e)}")

    async def _translate_deepl(self, text: str, target_locale: str, source_locale: Optional[str]) -> str:
        loc_lower = target_locale.lower()
        if "zh" in loc_lower:
            target = "ZH"
        elif loc_lower.startswith("en"):
            target = "EN"
        elif loc_lower.startswith("ja"):
            target = "JA"
        elif loc_lower.startswith("ko"):
            target = "KO"
        else:
            target = target_locale.upper()

        url = "https://api-free.deepl.com/v2/translate" if "free" in self.api_key or ":fx" in self.api_key else "https://api.deepl.com/v2/translate"
        headers = {
            "Authorization": f"DeepL-Auth-Key {self.api_key}",
            "Content-Type": "application/json",
            "User-Agent": "NampoGoGo-Backend/1.0"
        }
        payload = {
            "text": [text],
            "target_lang": target
        }
        data_bytes = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=data_bytes,
            headers=headers,
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=10.0) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                return res_data["translations"][0]["text"]
        except urllib.error.HTTPError as he:
            err_body = he.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"DeepL API Error ({he.code}): {err_body}")
        except Exception as e:
            raise RuntimeError(f"DeepL Connection Error: {str(e)}")
