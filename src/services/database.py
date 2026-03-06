from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from urllib.parse import quote_from_bytes
import time
import logging

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Read environment variables
user = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")
host = os.getenv("DB_HOST")
db_name = os.getenv("DB_NAME")

logger.info(f"DB User: {user}")
# Do not print DB password for security
logger.info(f"DB Host: {host}")
logger.info(f"DB Name: {db_name}")

# Escape user/password
def safe_quote(s):
    if not isinstance(s, bytes):
        s = str(s).encode("utf-8")
    return quote_from_bytes(s)

DATABASE_URL = f"mysql+mysqlconnector://{safe_quote(user)}:{safe_quote(password)}@{host}/{db_name}"

# Retry loop for ensuring connection
MAX_RETRIES = 10
SLEEP_SECONDS = 3

engine = None
for attempt in range(1, MAX_RETRIES + 1):
    try:
        engine = create_engine(
            DATABASE_URL,
            pool_pre_ping=True,
            pool_recycle=3600,
            pool_size=10,
            max_overflow=5,
            pool_timeout=30
        )
        # Test connection
        conn = engine.connect()
        conn.close()
        logger.info("✅ Successful MySQL connection")
        break
    except Exception as e:
        logger.warning(f"Failed attempt {attempt} to connect to MySQL: {e}")
        time.sleep(SLEEP_SECONDS)
else:
    raise RuntimeError("❌ Could not connect to MySQL after several attempts")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()