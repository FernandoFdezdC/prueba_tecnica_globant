# DB Migration API

DB Migration API made using FastAPI

## Local development using `docker`

This sections shows how to initiate the API with local development using `docker`.

### In order to run the container in development mode, execute:

```bash
docker-compose build --no-cache
docker-compose up
```

`docker-compose` lets the server be reloaded whenever a change is made to the code, so that the development experience is more smooth.

For doing development tests, in order to run a jupyter server inside the container, execute:

```bash
docker ps
```

, obtain container id and execute:
```bash
docker exec -it [container_id] bash
jupyter notebook --allow-root --ip=0.0.0.0 --no-browser
```

## Deploying to production using `docker`

This sections shows how to deploy the API to production using `docker` containers.

### In order to run the service in production mode, execute:

```bash
docker build --no-cache -t db-migration-api-image .
docker run -d --name db-migration-api-container -p 8000:8000 db-migration-api-image
```

To enter the container, run:
```bash
docker exec -it [container_id] bash
```
docker exec -it a2d7e5fbc837 bash

### Deploying to `Kubernetes`

To deploy this application to `Kubernetes`, follow the steps below.

#### 1. Push the Image to a Container Registry

Kubernetes needs access to your Docker image.

Tag and push the image to Docker Hub (or another registry):

```bash
docker tag db-migration-api-image <dockerhub-username>/db-migration-api:latest
docker push <dockerhub-username>/db-migration-api:latest
```

We can also use:

1. AWS ECR

2. Google Artifact Registry

3. Azure Container Registry

#### 2. Create a Deployment

Create a file called `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-migration-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: db-migration-api
  template:
    metadata:
      labels:
        app: db-migration-api
    spec:
      containers:
        - name: db-migration-api
          image: your-dockerhub-username/db-migration-api:latest
          ports:
            - containerPort: 8000
          env:
            - name: DB_MIGRATION_API_HOST
              value: "0.0.0.0"
            - name: DB_MIGRATION_API_PORT
              value: "8000"
```

#### 3. Create a Service

To expose the application inside the cluster, create `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-migration-api-service
spec:
  type: ClusterIP
  selector:
    app: db-migration-api
  ports:
    - port: 80
      targetPort: 8000
```

Apply it:

```bash
kubectl apply -f service.yaml
```

#### 4. Expose the Service Externally

##### Option A — NodePort (Simple testing)

Change the Service type:
```yaml
type: NodePort
```

Then check:
```bash
kubectl get svc
```

Access:
```bash
http://<node-ip>:<node-port>
```

##### Option B — LoadBalancer (Cloud environments)

```yaml
type: LoadBalancer
```

Then run:
```bash
kubectl get svc
```

Wait for an external IP to be assigned.

#### 5. Using Ingress (Recommended for Production)

For production-grade deployments, use an Ingress controller (like NGINX Ingress).

Example ingress.yaml:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: db-migration-api-ingress
spec:
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: db-migration-api-service
                port:
                  number: 80
```

Apply:
```bash
kubectl apply -f ingress.yaml
```

Make sure:
- DNS points `api.example.com` to your cluster
- An Ingress controller is installed


### Production Best Practices

- Use ConfigMap for non-sensitive configuration
- Use Secret for credentials
- Set resource limits:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```
- Enable readiness and liveness probes
- Use HTTPS via Ingress + Cert-Manager
- Use Horizontal Pod Autoscaler (HPA)

## Local development using uv

This sections shows how to initiate the API with local development using `uv`.

To install the minimum requirements and tools, run the following commands:

```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install nodejs npm python3 python3-pip
```

Create a virtual environment and install dependencies using `uv`:
```bash
cd api-bi

# Install uv (if not already installed)
pip install uv

# Create a virtual environment
uv venv

# Activate the virtual environment
source .venv/bin/activate

# Install project dependencies
uv pip install -r requirements.txt
```

To add a new library, use:
```bash
uv pip install <library-name>
```


### Use

In order to initiate the API, execute:

> uvicorn main:app --reload

The application starts at [http://localhost:8000](http://localhost:8000).

🔹 1. Interactive Documentation (Swagger UI)
If you open the following URL in your browser [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs), you will see the Swagger UI interface, where you can directly test your endpoints.

🔹 2. Alternative Documentation (ReDoc)
You can also access another version at [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc).



## Production Deployment using uv

To deploy the application to production, you must configure a WSGI server such as Gunicorn and a web server such as Nginx or Apache.

You will need to install Gunicorn and the production dependencies:

```bash
pip install gunicorn
pip install -r requirements.txt
```

### Gunicorn Configuration

You can test that it works correctly with the following command:

```bash
# main is the name of the main application file without the .py extension
gunicorn --bind 0.0.0.0:8000 main:app -k uvicorn.workers.UvicornWorker
```

Next, create a Gunicorn configuration file in the project root called gunicorn_config.py with the following content:

```python
import os
import multiprocessing
from dotenv import load_dotenv

dotenv_path = os.path.join('/ABSOLUTE_PATH_TO_THE_PROJECT/api-bi', '.env')
load_dotenv(dotenv_path)

workers = multiprocessing.cpu_count() * 2 + 1
worker_class = 'uvicorn.workers.UvicornWorker'

bind = [os.getenv('DB_MIGRATION_API_HOST', '127.0.0.1') + ':'+ os.getenv('DB_MIGRATION_API_PORT', '8000')]
limit_request_field_size = 32760
umask = 0o007
reload = True

# Logging options
loglevel = 'debug'
accesslog = '/PATH_FOR_YOUR_LOGS/access_log'
errorlog = '/PATH_FOR_YOUR_LOGS/error_log'
```

Then, to verify that the configuration file is correctly defined, run:

```bash
# main is the name of the main application file without the .py extension
gunicorn -c /ABSOLUTE_PATH_TO_THE_CONFIG_FILE/gunicorn_config.py main:app 
```


### systemd Configuration
If you want to configure Gunicorn to run as a system service, first create a service file at `systemd/system/db-migration-api.service` with the following content:

```bash
[Unit]
Description=Gunicorn instance to serve api-bi
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/ABSOLUTE_PATH_TO_THE_PROJECT/api-bi
Environment="PATH=/ABSOLUTE_PATH_TO_THE_PROJECT/api-bi/myvenv/bin"
ExecStart=/ABSOLUTE_PATH_TO_THE_PROJECT/api-bi/myvenv/bin/gunicorn --config /ABSOLUTE_PATH_TO_THE_PROJECT/api-bi/gunicorn_config.py wsgi:app

[Install]
WantedBy=multi-user.target
```

To start and enable the service:
```bash
sudo systemctl start api-bi
sudo systemctl enable api-bi
```

### Apache Configuration

Now configure the Apache server. First, install Apache and the Apache WSGI module:

```bash
sudo apt-get install apache2 libapache2-mod-wsgi-py3
sudo a2enmod wsgi
```
Configure the Apache proxy configuration file at `/etc/apache2/sites-available/api-bi.conf` with the following content:

```bash
<VirtualHost *:80>
    ServerAdmin web@example.com
    ServerName example.com
    ServerAlias www.example.com 

    ProxyRequests off
    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>

    <Location />
        ProxyPass http://localhost:YOUR_APP_PORT/
        ProxyPassReverse http://localhost:YOUR_APP_PORT/
    </Location>
    
    ErrorLog ${APACHE_LOG_DIR}/api-bi-error.log
    CustomLog ${APACHE_LOG_DIR}/api-bi-access.log combined
    
</VirtualHost>
```

To enable the site and reload the Apache configuration:

```bash
sudo a2ensite api-bi
# O creando un enlace simbólico
sudo ln -s /etc/apache2/sites-available/api-bi.conf /etc/apache2/sites-enabled/api-bi.conf
# Recargar la configuración
sudo systemctl reload apache2
```

With this, the application should now be running in production.


## Use API

In order to use the API, take the following example that takes the data stored in CSV files in the folder `data` and stores it in the MySQL database:

```powershell
curl -X POST http://localhost:8000/departments -H "accept: application/json" -F "file=@data\departments.csv"
```
```powershell
curl -X POST http://localhost:8000/jobs -H "accept: application/json" -F "file=@data\jobs.csv"
```
```powershell
curl -X POST http://localhost:8000/employees -H "accept: application/json" -F "file=@data\hired_employees.csv"
```

The following endpoints retrieve basic metrics about the data stored:

```powershell
curl -X GET http://localhost:8000/metrics/hires-by-quarter -H "accept: application/json"
```
```powershell
curl -X GET http://localhost:8000/metrics/departments-above-mean -H "accept: application/json"
```


## Code explanation

We do bulk data loading using the details given in https://dev.mysql.com/doc/refman/8.4/en/optimizing-innodb-bulk-data-loading.html, as the tables we use in our MySQL database are of InnoDB type (we use InnoDB because it is ACID compliant).

## Testing

To perform local testing with Docker (`docker-compose up` must have been executed):

```bash
docker exec -e PYTHONPATH=/code -it prueba_tecnica_globant-dev-1 pytest /code/tests -v
```

In general it will be:
```bash
docker exec -e PYTHONPATH=/code -it <container_name> pytest /code/tests -v
```