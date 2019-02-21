Please wait for the initial tasks to finish (i.e. the shell prompt to be ready) before doing anything :)

## Web UI Links

- [Kubernetes Dashboard](https://[[HOST_SUBDOMAIN]]-30080-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (Web)](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/)

- [App (API)](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/api)

- [App (DB)](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/redis)

## Docker registry

The Docker registry `registry.workshop.breda.local`{{copy}} is reachable from both nodes (and only from them). Example usage:

- **Push an image to the registry**
  ```
  docker pull nginx
  docker tag nginx registry.workshop.breda.local/my-nginx-image
  docker push registry.workshop.breda.local/my-nginx-image
  ```{{execute}}
- **Run it in the cluster**
  ```
  kubectl run nginx-test -lapp.kubernetes.io/part-of=example-3tier-app --image=registry.workshop.breda.local/my-nginx-image
  kubectl expose deployment nginx-test --type=NodePort --port=30099 --target-port=80
  kubectl patch svc nginx-test --type='json' -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":30099}]'
  ```{{execute}}

- **View it** [in the browser](https://[[HOST_SUBDOMAIN]]-30099-[[KATACODA_HOST]].environments.katacoda.com/)
