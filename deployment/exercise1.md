Create a deployment of web servers.

Requirements:
- Image: `nginx:1.12.0-alpine`
- **Two** instances
- Pods labeled `app: nginx`
- Exposes container **port 80**
- `kubectl get pods` should show you **two new pods**

Hints:
- Edit the deployment spec file
- Use `kubectl apply -f <object-spec-file>`