from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=False,
    allow_methods=["*"],  # Allow all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)

# Health endpoint
@app.get("/health")
def health():
    return {"message": "Status OK."}


# Routers

from routers import db_migration
from routers import metrics

app.include_router(db_migration.router)
app.include_router(metrics.router)