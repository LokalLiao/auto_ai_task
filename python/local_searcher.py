import os
import shutil
from difflib import SequenceMatcher
from typing import Optional, List
from send2trash import send2trash
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

"""
本地文件管理模块 (File Management Module)
【设计模式与优势】
- 高内聚模块化：集中管理数据模型(Schema)、底层文件操作(LocalSearcher)与 API 路由(APIRouter)，修改与调试无需跨文件跳转。
- 即插即用：仅对外暴露 APIRouter，在 main.py 中通过 include_router 单行即可插拔接入。
- 双模复用：LocalSearcher 底层类既可作为 HTTP 接口直接调用，也可被 Agent/CLI 脚本直接作为纯 Python 模块独立引用。
"""

#导出 APIRouter直接给main调用
router = APIRouter(prefix="/files", tags=["File Management"])

class LocalSearcher:

    #直接获取并返回当前系统中存在的所有盘符列表
    def get_available_drives(self):
        drives = []
        for letter in "CDEFGHIJKLMNOPQRSTUVWXYZ":
            drive = f"{letter}:\\"
            if os.path.exists(drive):
                drives.append(drive)
        return drives

    def search_files(self, query: str, drives: Optional[List[str]] = None):
        #在指定盘符或全盘中搜索文件
        #:param query: 搜索关键词
        #:param drives: 可选，指定盘符列表，如 ['C:\\', 'D:\\'] 或 ['C', 'D:']。默认搜索所有可用盘符
        # 未指定盘符时，默认获取所有可用盘符
        if drives is None:
            target_drives = self.get_available_drives()
        else:
            # 格式化盘符输入（支持传入 'D'、'D:'、'D:\\' 等各种写法）并过滤不存在的路径
            target_drives = []
            for d in drives:
                clean_drive = d.rstrip("\\/").rstrip(":") + ":\\"
                if os.path.exists(clean_drive):
                    target_drives.append(clean_drive)
        results = []
        for drive in target_drives:
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

    #将指定路径的文件或文件夹丢入回收站
    def move_to_trash(self, file_path: str) -> bool:
        if not os.path.exists(file_path):
            print(f"路径不存在: {file_path}")
            return False
        try:
            # 转换为系统标准绝对路径后送入回收站
            norm_path = os.path.normpath(file_path)
            send2trash(norm_path)
            return True
        except Exception as e:
            print(f"移入回收站失败: {e}")
            return False

    #永久直接删除指定路径的文件或文件夹（不可从回收站恢复）
    def delete_permanently(self, file_path: str) -> bool:
        if not os.path.exists(file_path):
            print(f"路径不存在: {file_path}")
            return False
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.remove(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
            return True
        except Exception as e:
            print(f"删除失败: {e}")
            return False

# 定义请求模型
class SearchRequest(BaseModel):
    query: str
    drives: Optional[List[str]] = None

class FilePathRequest(BaseModel):
    file_path: str

#实例化底层服务
searcher = LocalSearcher()

#获取当前主机设备存在的盘符
@router.get("/drives")
def get_drives():
    return {"code": 200, "data": {"drives": searcher.get_available_drives()}}

#搜索指定名称文件，可指定盘符
@router.post("/search")
def search_files_api(req: SearchRequest):
    results = searcher.search_files(req.query, req.drives)
    return {"code": 200, "data": {"total": len(results), "results": results}}

#把对应路径文件放回收站
@router.post("/trash")
def move_to_trash_api(req: FilePathRequest):
    if not searcher.move_to_trash(req.file_path):
        raise HTTPException(
            status_code=400, detail="文件不存在或移入回收站失败"
        )
    return {"code": 200, "message": f"已将 {req.file_path} 移入回收站"}

#直接删除对应文件
@router.delete("/delete")
def delete_permanently_api(req: FilePathRequest):
    if not searcher.delete_permanently(req.file_path):
        raise HTTPException(status_code=400, detail="文件不存在或删除失败")
    return {"code": 200, "message": f"已永久删除 {req.file_path}"}