#!/bin/sh -eu

set +x
REGISTRY_DOMAIN=registry.workshop.breda.local;

waitForDockerRegistryLocal() {
    echo "[$(date)] Waiting for Docker registry... (<1 min)"
    until
        >/dev/null 2>/dev/null docker inspect -f '{{.ID}}' registry;
    do
        sleep 1
        echo .;
    done | stdin-spinner;
    echo "[$(date)] done"
}

waitForNetwork() {
    echo "[$(date)] Waiting for network connectivity... (<1 min)"
    until
        >/dev/null 2>/dev/null curl  --fail --connect-timeout 1 --head https://github.com/
    do
        sleep 1
        echo .;
    done | stdin-spinner;
    echo "[$(date)] done"
}

waitForDockerRegistryRemote() {
    echo "[$(date)] Waiting for Docker registry... (<1 min)"
    until
        2>&1 curl -sSL https://"$REGISTRY_DOMAIN"/v2/
    do
        sleep 1
    done | stdin-spinner;
    echo "[$(date)] done"
}

waitForKubernetes() {
    echo "[$(date)] Waiting for Kubernetes... (~5 sec)"
    until
        2>&1 kubectl version;
    do
        sleep 1;
    done | stdin-spinner;
    echo "[$(date)] done"
}

waitForWeave() {
    echo "[$(date)] Waiting for Weave... (~5 sec)"
    until
        [ "$(kubectl get daemonset -n kube-system weave-net -o jsonpath='{.status.numberReady}')" = "2" ];
    do
        sleep 1;
        echo .;
    done | stdin-spinner;
    echo "[$(date)] done"
}

killKubeProxyPods() {
    echo "[$(date)] Restarting kube-proxy... (~2 sec)"
    (
        2>&1 kubectl delete pods -lk8s-app=kube-proxy -n kube-system;
    ) | stdin-spinner
    echo "[$(date)] done"
}

deployMetricsServer() {
    echo "[$(date)] Deploying metrics-server... (~3 sec)"
    (
        2>&1 git clone --single-branch --depth=1 https://github.com/kubernetes-incubator/metrics-server
        2>&1 kubectl create -f metrics-server/deploy/1.8+/
    ) | stdin-spinner
    echo "[$(date)] done"
}

installKubebox() {
    echo "[$(date)] Installing kubebox... (~3 sec)"
    (
        2>&1 curl -Lo kubebox https://github.com/astefanutti/kubebox/releases/download/v0.4.0/kubebox-linux
    ) | stdin-spinner
    chmod +x kubebox
    mv kubebox /usr/bin/
    echo "[$(date)] done"
}

installKail() {
    echo "[$(date)] Installing kail... (~3 sec)"
    (
        curl -sSL https://github.com/boz/kail/releases/download/v0.7.0/kail_0.7.0_linux_amd64.tar.gz | tar xvz 2>&1
    ) | stdin-spinner
    chmod +x kail
    mv kail /usr/bin/
    echo "[$(date)] done"
}

installStdinSpinner() {
    2>/dev/null curl -sSL https://github.com/sgreben/stdin-spinner/releases/download/1.0.4/stdin-spinner_1.0.4_linux_x86_64.tar.gz | tar xz
    chmod +x stdin-spinner
    mv stdin-spinner /usr/bin/
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
        installStdinSpinner
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
        installStdinSpinner
        installKail
        waitForDockerRegistryLocal
        waitForKubernetes
        waitForWeave
        kail
    ;;
esac
