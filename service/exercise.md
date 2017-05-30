Run a load-balanced web server in a cluster.

Requirements:

- There should be **five replicas** of your web server
- `curl host01:30080` should output “Hello Kubernetes!”

Hints:

- Create a **Deployment** of your web server
- Create a **Service of type NodePort** selecting the Deployment’s Pods
- The (single) **Node** of your cluster is reachable at `host01`
