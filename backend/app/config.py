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


settings = Settings()
