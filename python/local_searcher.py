import os
from difflib import SequenceMatcher

class LocalSearcher:

    def search_files(self, query: str):
        results = []
        for drive in self._get_drives():
            for root, dirs, files in os.walk(drive):
                for filename in files:
                    score = self._similarity(query, filename)
                    if score >= 0.4:
                        results.append({
                            "name": filename,
                            "path": os.path.join(root, filename),
                            "score": score
                        })
        results.sort(
            key=lambda item: item["score"],
            reverse=True
        )
        return results

    def _get_drives(self):
        drives = []
        for letter in "CDEFGHIJKLMNOPQRSTUVWXYZ":
            drive = f"{letter}:\\"
            if os.path.exists(drive):
                drives.append(drive)
        return drives

    def _similarity(self, query: str, filename: str):
        if not query:
            return 0.0
        # 直接包含：最高优先级
        if query in filename:
            return 1.0
        # 模糊匹配
        return SequenceMatcher(
            None,
            query.lower(),
            filename.lower()
        ).ratio()