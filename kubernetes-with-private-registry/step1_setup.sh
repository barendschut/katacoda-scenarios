#!/bin/sh -eu

set +x
REGISTRY_DOMAIN=registry.workshop.breda.local;

waitForDockerRegistryLocal() {
    echo "[$(date)] Waiting for Docker registry... (~20 sec)"
    until
        >/dev/null 2>/dev/null docker inspect -f '{{.ID}}' registry;
    do
        sleep 1
    done
    echo "[$(date)] done"
}

waitForDockerRegistryRemote() {
    echo "[$(date)] Waiting for Docker registry... (~20 sec)"
    until
        >/dev/null 2>/dev/null curl -sSL https://"$REGISTRY_DOMAIN"/v2/
    do
        sleep 1
    done
    echo "[$(date)] done"
}

waitForKubernetes() {
    echo "[$(date)] Waiting for Kubernetes... (~5 sec)"
    until
        >/dev/null 2>/dev/null kubectl version;
    do
        sleep 1
    done
    echo "[$(date)] done"
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
