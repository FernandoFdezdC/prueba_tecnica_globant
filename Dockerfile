FROM python:3.12-slim
# Use light python image

# 1. Copy dependencies
COPY src/requirements.txt /tmp/requirements.txt

# 2. Install dependencies
RUN python3.12 -m pip install --no-cache-dir --upgrade pip setuptools
RUN python3.12 -m pip install --no-cache-dir --upgrade -r /tmp/requirements.txt

# 4. Copy API code
COPY src /code/app

# 5. Create platform logs folders with right execution permissions
RUN mkdir -p /var/log/platform-logs && chmod 777 /var/log/platform-logs

WORKDIR /code/app

# 5. Create a user with limited permissions
RUN addgroup --system appuser \
 && adduser  --system \
             --ingroup appuser \
             --no-create-home \
             --disabled-login \
             --gecos "" \
             appuser

# 6. Switch to user "appuser" before any subsequent build/run
USER appuser

EXPOSE 8000

# Run Gunicorn with Uvicorn workers
#    - 4 worker processes is usually a good starting point.
#    - timeout set to 30s, loglevel info, and logs to stdout/stderr.
CMD ["gunicorn", "--config", "/code/app/gunicorn_config.py", "main:app"]