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

## Code explanation

We do bulk data loading using the details given in https://dev.mysql.com/doc/refman/8.4/en/optimizing-innodb-bulk-data-loading.html, as the tables we use in our MySQL database are of InnoDB type (we use InnoDB because it is ACID compliant).
