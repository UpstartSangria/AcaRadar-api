import os
import time
import logging
from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

# ---------- logging ----------
logging.basicConfig(
    level=os.environ.get("EMBED_LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s [embed_service] %(message)s",
)

log = logging.getLogger("embed_service")

app = Flask(__name__)

DEVICE = os.getenv("EMBED_DEVICE", "cpu")  # default cpu

MODEL_NAME = os.environ.get("EMBED_MODEL", "all-MiniLM-L6-v2")
CACHE_DIR = os.environ.get("TRANSFORMERS_CACHE") or os.environ.get("HF_HOME")

log.info("BOOT starting embed service...")
log.info("BOOT MODEL_NAME=%s", MODEL_NAME)
log.info("BOOT CACHE_DIR=%s", CACHE_DIR)
log.info("BOOT HF_HOME=%s", os.environ.get("HF_HOME"))
log.info("BOOT TRANSFORMERS_CACHE=%s", os.environ.get("TRANSFORMERS_CACHE"))
log.info("BOOT SENTENCE_TRANSFORMERS_HOME=%s", os.environ.get("SENTENCE_TRANSFORMERS_HOME"))
log.info("BOOT HF_HUB_CACHE=%s", os.environ.get("HF_HUB_CACHE"))

t0 = time.perf_counter()
model = SentenceTransformer(MODEL_NAME, cache_folder=CACHE_DIR, device=DEVICE)
log.info("BOOT model loaded in %.1f ms", (time.perf_counter() - t0) * 1000)


@app.get("/health")
def health():
    return jsonify({
        "ok": True,
        "model": MODEL_NAME,
        "cache_dir": CACHE_DIR,
    })


@app.post("/embed")
def embed():
    req_id = request.headers.get("X-Request-Id", "")
    t0 = time.perf_counter()

    data = request.get_json(silent=True) or {}
    text = (data.get("text") or "").strip()

    log.info("REQ /embed request_id=%s text_len=%d", req_id, len(text))

    if not text:
        return jsonify({"embedding": [], "ms": 0.0})

    t1 = time.perf_counter()
    emb = model.encode(text).tolist()
    ms = (time.perf_counter() - t1) * 1000
    total_ms = (time.perf_counter() - t0) * 1000

    log.info("RESP /embed request_id=%s emb_dim=%d encode_ms=%.1f total_ms=%.1f",
             req_id, len(emb), ms, total_ms)

    return jsonify({"embedding": emb, "ms": ms})
