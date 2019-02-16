## Docker registry

The Docker registry `registry.workshop.breda.local`{{copy}} is reachable from both nodes (and only from them).

Example usage:
`docker pull nginx`{{execute}}
`docker tag nginx registry.workshop.breda.local/my-nginx-image`{{execute}}
`docker push registry.workshop.breda.local/my-nginx-image`{{execute}}
`kubectl run nginx-test --image=registry.workshop.breda.local/my-nginx-image`{{execute}}
`kubectl expose deployment nginx-test --type=NodePort --port=30099 --target-port=80`{{execute}}

- [Example NodePort 30099](https://[[HOST_SUBDOMAIN]]-30099-[[KATACODA_HOST]].environments.katacoda.com/)


## Web UI Links

- [Kubernetes Dashboard](https://[[HOST_SUBDOMAIN]]-30080-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (Web) on NodePort 30001](https://[[HOST_SUBDOMAIN]]-30001-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (API) on NodePort 30002](https://[[HOST_SUBDOMAIN]]-30002-[[KATACODA_HOST]].environments.katacoda.com/)
