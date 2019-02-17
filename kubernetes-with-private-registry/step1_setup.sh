#!/bin/sh -eu

set +x
REGISTRY_DOMAIN=registry.workshop.breda.local;

alias simple_date="date +'%H:%M:%S'"

waitForDockerRegistryLocal() {
    echo "[$(simple_date)] Waiting for Docker registry... (<1 min)"
    until
        >/dev/null 2>/dev/null docker inspect -f '{{.ID}}' registry;
    do
        sleep 0.1;
        echo .;
    done | stdin-spinner;
    echo "[$(simple_date)] done"
}

waitForDockerUpgrade() {
    echo "[$(simple_date)] Waiting for Docker upgrade... (<1 min)"
    (
        until [ -e /opt/upgrade-docker ] || [ -e /opt/upgrade-docker-done ]; do
            sleep 1;
        done;
        2>&1 cat /opt/upgrade-docker || true;
        until 2>&1 docker version; do
            sleep 1;
        done;
    ) | stdin-spinner;
    echo "[$(simple_date)] done"
}

waitForDockerRegistryRemote() {
    echo "[$(simple_date)] Waiting for Docker registry... (<1 min)"
    until
        2>&1 curl -sSL https://"$REGISTRY_DOMAIN"/v2/
    do
        sleep 0.1;
    done | stdin-spinner;
    echo "[$(simple_date)] done"
}

waitForKubernetes() {
    echo "[$(simple_date)] Waiting for Kubernetes... (~5 sec)"
    until
        2>&1 kubectl version;
    do
        sleep 1;
    done | stdin-spinner;
    echo "[$(simple_date)] done"
}

waitForWeave() {
    echo "[$(simple_date)] Waiting for Weave... (~5 sec)"
    (
        until
            [ "$(2>&1 kubectl get daemonset -n kube-system weave-net -o jsonpath='{.status.numberReady}')" = "2" ];
        do
            echo .;
            sleep 1;
        done;
    ) | stdin-spinner
    echo "[$(simple_date)] done"
}

killKubeProxyPods() {
    echo "[$(simple_date)] Restarting kube-proxy... (~2 sec)"
    (
        2>&1 kubectl delete pods -lk8s-app=kube-proxy -n kube-system;
        until
            [ "$(kubectl get daemonset -n kube-system kube-proxy -o jsonpath='{.status.numberReady}')" = "2" ];
        do
            echo .;
            sleep 1;
        done;
    ) | stdin-spinner
    echo "[$(simple_date)] done"
}

killKubeDNSPods() {
    >/dev/null 2>/dev/null kubectl delete pods -lkubernetes.io/name=KubeDNS -n kube-system;
}

killCoreDNSPods() {
    echo "[$(simple_date)] Restarting coredns... (~2 sec)"
    (
        2>&1 kubectl delete pods -lk8s-app=coredns -n kube-system;
        2>&1 kubectl -v999 wait deployments/coredns -n kube-system --for condition=Available;
    ) | stdin-spinner
    echo "[$(simple_date)] done"
}

deployMetricsServer() {
    echo "[$(simple_date)] Deploying metrics-server... (~3 sec)"
    (
        2>&1 git clone --single-branch --depth=1 https://github.com/kubernetes-incubator/metrics-server
        2>&1 kubectl -v999 create -f metrics-server/deploy/1.8+/
    ) | stdin-spinner
    echo "[$(simple_date)] done"
}

deployDashboard() {
    echo "[$(simple_date)] Deploying Kubernetes dashboard... (~3 sec)"
    (
        2>&1 kubectl apply -f https://gist.github.com/sgreben/bd04d51eb2f683091ba62d7389a564a8/raw//;
        2>&1 kubectl -v999 wait deployments/kubernetes-dashboard -n kube-system --for condition=Available;
    ) | stdin-spinner
    echo "[$(simple_date)] done"
}

installKubebox() {
    echo "[$(simple_date)] Installing kubebox... (~3 sec)"
    (
        2>&1 curl -ksSLo kubebox https://github.com/astefanutti/kubebox/releases/download/v0.4.0/kubebox-linux
    ) | stdin-spinner
    chmod +x kubebox
    mv kubebox /usr/bin/
    echo "[$(simple_date)] done"
}

installKail() {
    echo "[$(simple_date)] Installing kail... (~3 sec)"
    (
        curl -ksSL https://github.com/boz/kail/releases/download/v0.7.0/kail_0.7.0_linux_amd64.tar.gz | tar xvz 2>&1
    ) | stdin-spinner
    chmod +x kail
    mv kail /usr/bin/
    echo "[$(simple_date)] done"
}

installStdinSpinner() {
    2>/dev/null curl -ksSL https://github.com/sgreben/stdin-spinner/releases/download/1.0.4/stdin-spinner_1.0.4_linux_x86_64.tar.gz | tar xz
    chmod +x stdin-spinner
    mv stdin-spinner /usr/bin/
}

installSSHKey() {
    >/dev/null 2>/dev/null chmod 400 ~/.ssh/k8s_workshop_breda;
    >/dev/null 2>/dev/null eval "$(ssh-agent)"
    >/dev/null 2>/dev/null ssh-add ~/.ssh/k8s_workshop_breda;
    echo "[$(simple_date)] SSH public key:


ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7HCf/bOWHHV73rYHrP89vnPQJNkHitUo72jwuVyYg6/LeNWG4KwIhzs9BRHNqcZp90NjfbibKCchmVZnuylXkyE3YwfYCAt1lZ6zWBt2jcPGRCBDfaqlZEAXjgjOywMM1KMzf9SZAJBQTYsC893BImclg6wfORm/RZupakP7QYixPNjo94W9HGkMeO6fYdI2uk48/T+qKw0kdFdw3DTRXaxSFmof+4NdSxk8N5Hf9W2l2AWNkOZlRnhQgnwI++thfwbAhu4OjY17P8Fdazc+NhYO+OuOUMdBzVDs+88kD5jq5mS/NxUSK+ShywIpqlTnk98RyFTNoM3nnWGIX5uzh k8s-workshop@breda

    "
}

runDockerRegistry() {
    echo "[$(simple_date)] Starting Docker registry... (~3 sec)"
    (
        2>&1 docker run -d -p 443:5000 \
            -v /root/.certs:/certs \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_DOMAIN.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_DOMAIN.key \
            -v /opt/registry/data:/var/lib/registry \
            --name registry registry:2;
    ) | stdin-spinner
    echo "[$(simple_date)] done"
}

case "$(hostname)" in
    master)
        clear
        installStdinSpinner
        installKail
        waitForDockerUpgrade
        killKubeDNSPods
        waitForDockerRegistryRemote
        waitForWeave
        deployDashboard
        killKubeProxyPods
        killCoreDNSPods
        installSSHKey
    ;;
    node01)
        clear
        installStdinSpinner
        installKail
        waitForDockerUpgrade
        runDockerRegistry
        waitForDockerRegistryLocal
        waitForKubernetes
        echo '$ kail -lapp.kubernetes.io/part-of=example-3tier-app'
        kail -lapp.kubernetes.io/part-of=example-3tier-app
    ;;
esac
