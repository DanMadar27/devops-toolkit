import os

import redis
from fastapi import FastAPI
from fastapi.responses import RedirectResponse, JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
Instrumentator().instrument(app).expose(app)

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/{code}")
def redirect(code: str):
    url = r.get(code)
    if url is None:
        return JSONResponse(status_code=404, content={"error": "not found"})
    return RedirectResponse(url=url, status_code=302)
