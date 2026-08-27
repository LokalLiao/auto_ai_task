# 将AI解析出来的
from local_searcher import LocalSearcher

class ActionDispatcher:

    def __init__(self):
        self.local_search = LocalSearcher()

    def dispatch(self, action: dict):
        action_name = action.get("action")
        if not action_name:
            raise ValueError("缺少 action")
        if action_name == "local_search":
            filename = action["filename"]
            result = self.local_search.search_files(filename)
            return result

        raise ValueError(f"未知 action: {action_name}")