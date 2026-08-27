from pathlib import Path

class PromptAgent:

    def __init__(self):
        self.prompt_dir = Path(__file__).parent / "prompts"

    def render(self, key: str, user_msg: str) -> str:
        # 加载对应的提示词
        template = self.load(key)
        try:
            return template.format(USER_MESSAGE=user_msg)
        except KeyError as e:
            raise ValueError(
                f"Prompt 缺少参数: {e}"
            ) from e

    def load(self, prompt_name: str) -> str:
        prompt_file = self.prompt_dir / f"{prompt_name}.txt"
        if not prompt_file.exists():
            raise FileNotFoundError(
                f"Prompt 不存在: {prompt_file}"
            )
        return prompt_file.read_text(encoding="utf-8")