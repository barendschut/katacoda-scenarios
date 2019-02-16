#!/bin/sh -eu

set +x
REGISTRY_DOMAIN=registry.workshop.breda.local;

waitForDockerRegistryLocal() {
    echo "Waiting for Docker registry..."
    until
        >/dev/null 2>/dev/null docker inspect -f '{{.ID}}' registry;
    do
        sleep 1
    done
    echo "done"
}

waitForDockerRegistryRemote() {
    echo "Waiting for Docker registry..."
    until
        >/dev/null 2>/dev/null curl -sSL https://"$REGISTRY_DOMAIN":5000/v2/
    do
        sleep 1
    done
    echo "done"
}

waitForKubernetes() {
    echo "Waiting for Kubernetes..."
    until
        >/dev/null 2>/dev/null kubectl version;
    do
        sleep 1
    done
    echo "done"
}

case "$(hostname)" in
    node01)
        clear
        waitForDockerRegistryLocal
        waitForKubernetes
    ;;
    master)
        clear
        waitForDockerRegistryRemote
        waitForKubernetes
    ;;
esac
