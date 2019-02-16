Please wait for the initial tasks to finish (i.e. the shell prompt to be ready) before doing anything :)

## Docker registry

The Docker registry `registry.workshop.breda.local`{{copy}} is reachable from both nodes (and only from them). Example usage:

```shell
docker pull nginx
docker tag nginx registry.workshop.breda.local/my-nginx-image
docker push registry.workshop.breda.local/my-nginx-image
kubectl run nginx-test --image=registry.workshop.breda.local/my-nginx-image
kubectl expose deployment nginx-test --type=NodePort --port=30099 --target-port=80 && kubectl patch svc nginx-test --type='json' -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30099}]'
```
{{execute}}

### Get an image

`docker pull nginx`{{execute}}

### Tag it using the registry host

`docker tag nginx registry.workshop.breda.local/my-nginx-image`{{execute}}

### Push it to the registry

`docker push registry.workshop.breda.local/my-nginx-image`{{execute}}

### Run it in the cluster

`kubectl run nginx-test --image=registry.workshop.breda.local/my-nginx-image`{{execute}}

### Expose it

`kubectl expose deployment nginx-test --type=NodePort --port=30099 --target-port=80 && kubectl patch svc nginx-test --type='json' -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30099}]'`{{execute}}

### View it in the browser

[View NodePort 30099](https://[[HOST_SUBDOMAIN]]-30099-[[KATACODA_HOST]].environments.katacoda.com/)


## Web UI Links

- [Kubernetes Dashboard](https://[[HOST_SUBDOMAIN]]-30080-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (Web) on NodePort 30001](https://[[HOST_SUBDOMAIN]]-30001-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (API) on NodePort 30002](https://[[HOST_SUBDOMAIN]]-30002-[[KATACODA_HOST]].environments.katacoda.com/)
