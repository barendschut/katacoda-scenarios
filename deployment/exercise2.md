Scale up your deployment of web servers.

Requirements:
- **Reuse deployment spec** file from previous step
- **Four** instances
- `kubectl get pods` should show you **two new pods**


Hints:
- Edit the deployment spec file
- Use `kubectl apply -f <deployment spec file>`