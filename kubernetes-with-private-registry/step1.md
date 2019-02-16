## Docker registry

The Docker registry `registry.workshop.breda.local`{{copy}} is reachable from both nodes (and only from them).

Example usage:
1. `docker pull nginx`{{execute}}
1. `docker tag nginx registry.workshop.breda.local/my-nginx-image`{{execute}}
1. `docker push registry.workshop.breda.local/my-nginx-image`{{execute}}
1. `kubectl run nginx-test --image=registry.workshop.breda.local/my-nginx-image`{{execute}}
2. `kubectl expose deployment nginx-test --type=NodePort --port=30099 --target-port=80 && kubectl patch svc nginx-test --type='json' -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30099}]'`{{execute}}
3. [View NodePort 30099](https://[[HOST_SUBDOMAIN]]-30099-[[KATACODA_HOST]].environments.katacoda.com/)


## Web UI Links

- [Kubernetes Dashboard](https://[[HOST_SUBDOMAIN]]-30080-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (Web) on NodePort 30001](https://[[HOST_SUBDOMAIN]]-30001-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (API) on NodePort 30002](https://[[HOST_SUBDOMAIN]]-30002-[[KATACODA_HOST]].environments.katacoda.com/)
