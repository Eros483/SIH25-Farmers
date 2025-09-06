# app_full.py
import torch
from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from IndicTransToolkit.processor import IndicProcessor

# Initialize FastAPI app
app = FastAPI()

# Model details
MODEL_NAME = "prajdabre/rotary-indictrans2-en-indic-dist-200M"
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Language mapping (from Hugging Face docs)
LANGUAGE_MAP = {
    "english": "eng_Latn",
    "hindi": "hin_Deva",
    "bengali": "ben_Beng",
    "santali": "sat_Olck"
}

# Load processor + tokenizer + model once (not on every request)
ip = IndicProcessor(inference=True)
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(
    MODEL_NAME,
    torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
    trust_remote_code=True,
).to(DEVICE)

# Request schema
class TranslationRequest(BaseModel):
    text: str
    src_lang: str
    tgt_lang: str

class PageTranslationRequest(BaseModel):
    page_strings: dict
    src_lang: str
    tgt_lang: str

# Endpoint: translate single text
@app.post("/translate_text")
def translate_text(request: TranslationRequest):
    batch = ip.preprocess_batch(
        [request.text],
        src_lang=LANGUAGE_MAP[request.src_lang],
        tgt_lang=LANGUAGE_MAP[request.tgt_lang]
    )

    inputs = tokenizer(batch, padding="longest", truncation=True, max_length=2048, return_tensors="pt").to(DEVICE)

    with torch.inference_mode():
        outputs = model.generate(
            **inputs,
            num_beams=5,
            max_new_tokens=512,
            early_stopping=True
        )

    translations = tokenizer.batch_decode(outputs, skip_special_tokens=True)
    translations = ip.postprocess_batch(translations, lang=LANGUAGE_MAP[request.tgt_lang])
    return {"translation": translations[0]}

# Endpoint: translate whole page (dict of strings)
@app.post("/translate_page")
def translate_page(request: PageTranslationRequest):
    texts = list(request.page_strings.values())
    keys = list(request.page_strings.keys())

    batch = ip.preprocess_batch(
        texts,
        src_lang=LANGUAGE_MAP[request.src_lang],
        tgt_lang=LANGUAGE_MAP[request.tgt_lang]
    )

    inputs = tokenizer(batch, padding="longest", truncation=True, max_length=2048, return_tensors="pt").to(DEVICE)

    with torch.inference_mode():
        outputs = model.generate(
            **inputs,
            num_beams=5,
            max_new_tokens=512,
            early_stopping=True
        )

    translations = tokenizer.batch_decode(outputs, skip_special_tokens=True)
    translations = ip.postprocess_batch(translations, lang=LANGUAGE_MAP[request.tgt_lang])

    return {"translations": dict(zip(keys, translations))}
