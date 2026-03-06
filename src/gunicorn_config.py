import os
import multiprocessing
from dotenv import load_dotenv

load_dotenv(dotenv_path="/code/app/.env.local", override=True)

workers = multiprocessing.cpu_count() * 2 + 1
worker_class = 'uvicorn.workers.UvicornWorker'

bind = [os.getenv('DB_MIGRATION_API_HOST', '127.0.0.1') + ':'+ os.getenv('DB_MIGRATION_API_PORT', '8000')]
limit_request_field_size = 32760
umask = 0o007
reload = False
timeout = 240

loglevel = 'debug'
accesslog = '/var/log/platform-logs/access_log.log'
errorlog = '/var/log/platform-logs/error_log.log'