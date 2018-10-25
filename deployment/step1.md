
Save our Docker registry in `$REGISTRY` (so we don't have to type it over and over): `export REGISTRY=[[HOST_SUBDOMAIN]]-5000-[[KATACODA_HOST]].environments.katacoda.com`{{execute}}


Build and tag our image: `docker build -t $REGISTRY/web-server:1.0`{{excecute}}

Push our image to our registry: `docker push $REGISTRY/web-server:1.0`{{excecute}}
