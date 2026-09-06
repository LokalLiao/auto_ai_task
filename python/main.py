from fastapi import FastAPI
from local_searcher import router as files_router
import uvicorn

app = FastAPI(title="Host Agent Service")

#挂载 local_searcher 里的所有接口
app.include_router(files_router)

if __name__ == "__main__":
    #reload=True
    uvicorn.run("main:app", host="0.0.0.0", port=8000)
    # uvicorn.run(
    #     app,
    #     host="0.0.0.0",
    #     port=8000
    # )
