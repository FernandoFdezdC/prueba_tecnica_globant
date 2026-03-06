if __name__ == "__main__":
    from dotenv import load_dotenv
    import uvicorn
    import os
    load_dotenv(dotenv_path="/code/app/.env.local", override=True)

    # Read PORT from .env or use 8000 by default
    port = int(os.getenv("DB_MIGRATION_API_PORT", "8000"))
    host = os.getenv("DB_MIGRATION_API_HOST", "0.0.0.0")
    raw = os.getenv("PRODUCTION_ENV", "").lower()
    is_prod = raw in ("true", "1", "yes")
    reload = not is_prod
    uvicorn.run(
        "main:app",
        host=host,        # listens in all interfaces
        port=port,        # API port
        reload=reload     # reload for development
    )