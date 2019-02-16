#!/bin/sh -eu

set +x
REGISTRY_DOMAIN=registry.workshop.breda.local;

waitForDockerRegistryLocal() {
    echo "[$(date)] Waiting for Docker registry... (<1 min)"
    until
        >/dev/null 2>/dev/null docker inspect -f '{{.ID}}' registry;
    do
        sleep 1
    done
    echo "[$(date)] done"
}

waitForNetwork() {
    echo "[$(date)] Waiting for network connectivity... (<1 min)"
    until
        >/dev/null 2>/dev/null curl  --fail --connect-timeout 1 --head https://github.com/
    do
        sleep 1
    done
    echo "[$(date)] done"
}

waitForDockerRegistryRemote() {
    echo "[$(date)] Waiting for Docker registry... (<1 min)"
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

waitForWeave() {
    echo "[$(date)] Waiting for Weave... (~5 sec)"
    until
        [ "$(kubectl get daemonset -n kube-system weave-net -o jsonpath='{.status.numberReady}')" = "2" ];
    do
        sleep 1
    done
    echo "[$(date)] done"
}

killKubeProxyPods() {
    >/dev/null 2>/dev/null kubectl delete pods -lk8s-app=kube-proxy -n kube-system;
}

deployMetricsServer() {
    echo "[$(date)] Deploying metrics-server... (~3 sec)"
    >/dev/null 2>/dev/null git clone --single-branch --depth=1 https://github.com/kubernetes-incubator/metrics-server
    >/dev/null 2>/dev/null kubectl create -f metrics-server/deploy/1.8+/
    echo "[$(date)] done"
}

installKubebox() {
    echo "[$(date)] Installing kubebox... (~3 sec)"
    curl -Lo kubebox https://github.com/astefanutti/kubebox/releases/download/v0.4.0/kubebox-linux
    chmod +x kubebox
    mv kubebox /usr/bin/
    echo "[$(date)] done"
}

installKail() {
    echo "[$(date)] Installing kail... (~3 sec)"
    2>/dev/null curl -sSL https://github.com/boz/kail/releases/download/v0.7.0/kail_0.7.0_linux_amd64.tar.gz | tar xz
    chmod +x kail
    mv kail /usr/bin/
    echo "[$(date)] done"
}

installSSHKey() {
    >/dev/null 2>/dev/null chmod 400 ~/.ssh/k8s_workshop_breda;
    >/dev/null 2>/dev/null eval "$(ssh-agent)"
    >/dev/null 2>/dev/null ssh-add ~/.ssh/k8s_workshop_breda;
    echo "[$(date)] SSH public key:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7HCf/bOWHHV73rYHrP89vnPQJNkHitUo72jwuVyYg6/LeNWG4KwIhzs9BRHNqcZp90NjfbibKCchmVZnuylXkyE3YwfYCAt1lZ6zWBt2jcPGRCBDfaqlZEAXjgjOywMM1KMzf9SZAJBQTYsC893BImclg6wfORm/RZupakP7QYixPNjo94W9HGkMeO6fYdI2uk48/T+qKw0kdFdw3DTRXaxSFmof+4NdSxk8N5Hf9W2l2AWNkOZlRnhQgnwI++thfwbAhu4OjY17P8Fdazc+NhYO+OuOUMdBzVDs+88kD5jq5mS/NxUSK+ShywIpqlTnk98RyFTNoM3nnWGIX5uzh k8s-workshop@breda

    "
}

case "$(hostname)" in
    master)
        clear
        installKail
        waitForDockerRegistryRemote
        waitForKubernetes
        waitForWeave
        killKubeProxyPods
        deployMetricsServer
        installSSHKey
    ;;
    node01)
        clear
        installKail
        waitForDockerRegistryLocal
        waitForKubernetes
        waitForWeave
        kail
    ;;
esac
