Run load balanced web-servers in a cluster **with basic auth enabled**.

Requirements:

- Use image `nginx:1.13.0-alpine`
- `curl host01:30080` should yield HTTP status code 401
- `curl kubernaut:clusterfun@host01:30080` should output “Hello Kubernetes!”

Hints:

- Install **Secret** in cluster using `kubectl apply -f secret.yaml`
- Edit **nginx.conf** to configure basic auth.
- Adapt **Dockerfile** to include **nginx.conf**
- Adapt **deployment.yaml** to mount the **Secret** as a **Volume**
- Create Deployment and Service as in the previous exercise