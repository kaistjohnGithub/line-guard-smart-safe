import os
from pathlib import Path


class Settings:
    app_name = "Line Guard Backend"
    app_version = "0.1.0"

    # Database
    database_url: str = os.getenv("DATABASE_URL", "postgresql://ssg:ssg123@localhost:5432/ssg_db")

    # Media storage (images & videos from AI analysis)
    media_root: str = os.getenv("MEDIA_ROOT", str(Path(__file__).resolve().parents[1] / "media"))

    # CORS
    cors_origins: str = os.getenv("CORS_ORIGINS", "*")

    # Chat providers
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    gemini_model: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    ollama_base_url: str = os.getenv("OLLAMA_BASE_URL", "http://host.docker.internal:11434")
    ollama_model: str = os.getenv("OLLAMA_MODEL", "llama3.1:8b")


settings = Settings()
