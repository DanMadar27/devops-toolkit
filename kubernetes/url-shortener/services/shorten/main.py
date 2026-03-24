import os
import random
import string

import redis
from fastapi import FastAPI
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
Instrumentator().instrument(app).expose(app)

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


class ShortenRequest(BaseModel):
    url: str


def generate_code(length: int = 6) -> str:
    chars = string.ascii_letters + string.digits
    return "".join(random.choices(chars, k=length))


@app.post("/shorten")
def shorten(req: ShortenRequest):
    code = generate_code()
    r.set(code, req.url)
    return {"short_code": code}


@app.get("/health")
def health():
    return {"status": "ok"}
