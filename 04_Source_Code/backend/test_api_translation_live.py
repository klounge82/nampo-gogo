import asyncio
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.translation import TranslationProviderAdapter

async def test_live_translation():
    os.environ["TRANSLATION_PROVIDER"] = "GOOGLE"
    os.environ["TRANSLATION_API_KEY"] = "AIzaSyCvsP7_xDfIHWSwQwWhWWL8Jx_-eknpJX8"

    adapter = TranslationProviderAdapter()

    sample_reviews = [
        "마사지가 생각보다 시원했고 직원분도 친절했어요. 다음에 부산에 오면 다시 방문하고 싶습니다.",
        "시장 안이라 찾기가 조금 어려웠지만 음식은 정말 맛있었습니다.",
        "아이와 함께 갔는데 야경이 예쁘고 사진 찍기 좋았어요.",
        "가격은 조금 비쌌지만 서비스가 좋아서 만족했습니다.",
        "비가 와서 오래 구경하지 못했지만 다음 여행에 다시 와보고 싶어요."
    ]

    print("=== LIVE GOOGLE CLOUD TRANSLATION API TEST ===")

    locales = ["en", "ja", "zh_Hans"]

    for idx, rev in enumerate(sample_reviews, 1):
        print(f"\n[Review #{idx} Original (KO)]: {rev}")
        for loc in locales:
            try:
                translated = await adapter.translate_text(rev, target_locale=loc)
                print(f" -> [{loc.upper()}]: {translated}")
            except Exception as e:
                print(f" -> [{loc.upper()} ERROR]: {e}")

if __name__ == "__main__":
    asyncio.run(test_live_translation())
