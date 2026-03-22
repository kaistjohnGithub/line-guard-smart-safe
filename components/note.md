

## backend (fastAPI)

```
import os
from typing import Optional
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI

load_dotenv()

app = FastAPI(title="Denso Chat API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    message: str
    context: Optional[dict] = None

class ChatResponse(BaseModel):
    response: str

client = OpenAI(
    base_url=os.getenv("OPENAI_API_BASE", "https://generativelanguage.googleapis.com/v1beta"),
    api_key=os.getenv("OPENAI_API_KEY"),
)

client = OpenAI(
    base_url=os.getenv("OPENAI_API_BASE", "https://generativelanguage.googleapis.com/v1beta"),
    api_key=os.getenv("OPENAI_API_KEY"),
)

def build_system_prompt(context: Optional[dict]) -> str:
    if not context:
        return "You are a helpful assistant."

    content = context.get("content", "")[:10000]  # Limit context size

    return f"""You are a helpful assistant answering questions about the current webpage. Page Content: {content}

Answer the user's question based on the page content above. If the answer is not in the content, say so clearly."""

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        system_prompt = build_system_prompt(request.context)
        print("system_prompt",system_prompt)
        print("request.message",request.message)
        response = client.chat.completions.create(
            model=os.getenv("MODEL", "gemini-2.0-flash-exp"),
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.message},
            ],
            temperature=0.7,
            max_tokens=1024,
        )

        return ChatResponse(response=response.choices[0].message.content)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```