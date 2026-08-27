from fastapi import FastAPI
from pydantic import BaseModel
from gemini_agent import GeminiAgent
from action_dispatcher import ActionDispatcher
import uvicorn

app = FastAPI()
#
class TaskRequest(BaseModel):
    key: str
    message: str

class ChatRequest(BaseModel):
    message: str
#
gemini = GeminiAgent()
dispatcher = ActionDispatcher()

@app.post("/task")
def task_chat(request: TaskRequest):
    _action = gemini.analyzer(request.key, request.message)
    action_name = _action["action"]
    _result = dispatcher.dispatch(_action)
    #
    return {
        "code": 200,
        "action": action_name,
        "result": _result
    }

if __name__ == "__main__":
    action = gemini.analyzer("local_search", "查找XXX文件")
    result = dispatcher.dispatch(action)
    print(result)
    # uvicorn.run(
    #     app,
    #     host="0.0.0.0",
    #     port=8000
    # )
