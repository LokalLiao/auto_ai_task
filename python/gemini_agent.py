import json
from pathlib import Path
from google import genai
from prompt_agent import PromptAgent


# 调用gemini
class GeminiAgent:

    def __init__(self):
        # 创建gemini client
        self.client = self._client()
        self.prompt_agent = PromptAgent()

    def _client(self):
        config_path = Path(__file__).resolve().parent / "config.json"
        if not config_path.exists():
            raise FileNotFoundError(
                f"Config file not found: {config_path}"
            )
        with open(config_path, "r", encoding="utf-8") as f:
            js = json.load(f)
            client = genai.Client(
                api_key = js["gemini_api_key"]
            )
            return client

    # 传入任务类型和自然语言理解
    def analyzer(self, key: str, message: str) -> dict:
        # 通过key找对应关键词
        prompt = self.prompt_agent.render(key, message)
        response = self.client.models.generate_content(
            #model="gemini-2.5-flash",
            model="gemini-3.5-flash",
            contents=prompt
        )
        text = response.text.strip()
        print("===== Gemini 原始返回 =====")
        print(text)
        start = text.find("{")
        end = text.rfind("}")
        # 解析json数据
        if start == -1 or end == -1:
            raise ValueError(
                f"Gemini 没有返回有效 JSON：\n{text}"
            )
        json_text = text[start:end + 1]
        try:
            result = json.loads(json_text)
            result["action"] = key
            return result
        except json.JSONDecodeError as e:
            raise ValueError(
                f"Gemini 返回的内容不是有效 JSON：\n{json_text}"
            ) from e
