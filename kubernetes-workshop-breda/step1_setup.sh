#!/bin/sh -eu

set +x
REGISTRY_DOMAIN=registry.workshop.breda.local;

alias simple_date="date +'%H:%M:%S'"

waitForDockerRegistryLocal() {
    until
        2>&1 docker inspect -f '{{.ID}}' registry;
    do
        sleep 0.5;
        echo .;
    done
}

waitForDockerUpgrade() {
    (
        until [ -e /opt/upgrade-docker ] || [ -e /opt/upgrade-docker-done ]; do
            sleep 1;
        done;
        2>&1 cat /opt/upgrade-docker || true;
        until 2>&1 docker version; do
            echo .;
            sleep 0.5;
        done;
    )
}

waitForDockerRegistryRemote() {
    until
        2>&1 curl --fail -L https://"$REGISTRY_DOMAIN"/v2/
    do
        sleep 0.5;
    done;
}

waitForKubernetes() {
    until
        2>&1 kubectl -v999 --request-timeout=1s version;
    do
        sleep 0.5;
    done
}

waitForWeave() {
    (
        until
            [ "$(2>&1 kubectl get daemonset -n kube-system weave-net -o jsonpath='{.status.numberReady}')" = "2" ];
        do
            echo .;
            sleep 0.5;
        done;
    )
}

killKubeProxyPods() {
    (
        2>&1 kubectl -v999 delete pods -lk8s-app=kube-proxy -n kube-system;
        until
            [ "$(kubectl get daemonset -n kube-system kube-proxy -o jsonpath='{.status.numberReady}')" = "2" ];
        do
            echo .;
            sleep 0.5;
        done;
    )
}

killKubeDNSPods() {
    2>&1 kubectl -v999 delete pods -lkubernetes.io/name=KubeDNS -n kube-system;
}

killCoreDNSPods() {
    (
        2>&1 kubectl -v999 delete pods -lk8s-app=coredns -n kube-system;
        2>&1 kubectl -v999 wait deployments/coredns -n kube-system --for condition=Available;
    )
}

deployDashboard() {
    (
        2>&1 kubectl -v999 apply -f https://gist.github.com/sgreben/bd04d51eb2f683091ba62d7389a564a8/raw//;
        2>&1 kubectl -v999 wait deployments/kubernetes-dashboard -n kube-system --for condition=Available;
    )
}

installTools() {
    (
        exec 2>&1
        installKustomize &
        installDockerCompose &
        installStern &
        wait
    )
}

installKustomize() {
    until
        2>&1 curl --fail -kLo /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v2.0.1/kustomize_2.0.1_linux_amd64;
    do
        sleep 0.5;
    done;
    chmod +x /usr/local/bin/kustomize;
}

installDockerCompose() {
    until
        2>&1 curl --fail -kLo /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/1.24.0-rc1/docker-compose-"$(uname -s)"-"$(uname -m)";
    do
        sleep 0.5;
    done;
    chmod +x /usr/local/bin/docker-compose;
}

installStern() {
    (
        until
            2>&1 curl --fail -Lo /usr/local/bin/stern https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64;
        do
            sleep 0.5;
        done;
        chmod +x /usr/local/bin/stern;
    )
}

installStdinSpinner() {
    until
        2>/dev/null curl --fail -ksSL https://github.com/sgreben/stdin-spinner/releases/download/1.0.4/stdin-spinner_1.0.4_linux_x86_64.tar.gz | tar xz;
    do
        sleep 0.5;
    done;
    chmod +x stdin-spinner
    mv stdin-spinner /usr/bin/
}

configureGit() {
    (
        ssh-keyscan github.com >> ~/.ssh/known_hosts
        git config --global user.email "mail@example.com"
        git config --global user.name "name"
    ) 2>&1
}

configureSSH() {
    >/dev/null 2>/dev/null chmod 400 ~/.ssh/k8s_workshop_breda;
    cat >> ~/.bashrc <<EOF
        >/dev/null 2>/dev/null eval "\$(ssh-agent)";
        >/dev/null 2>/dev/null ssh-add ~/.ssh/k8s_workshop_breda;
        alias g=git;
EOF
    cat <<EOF
$(simple_date)] SSH public key:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7HCf/bOWHHV73rYHrP89vnPQJNkHitUo72jwuVyYg6/LeNWG4KwIhzs9BRHNqcZp90NjfbibKCchmVZnuylXkyE3YwfYCAt1lZ6zWBt2jcPGRCBDfaqlZEAXjgjOywMM1KMzf9SZAJBQTYsC893BImclg6wfORm/RZupakP7QYixPNjo94W9HGkMeO6fYdI2uk48/T+qKw0kdFdw3DTRXaxSFmof+4NdSxk8N5Hf9W2l2AWNkOZlRnhQgnwI++thfwbAhu4OjY17P8Fdazc+NhYO+OuOUMdBzVDs+88kD5jq5mS/NxUSK+ShywIpqlTnk98RyFTNoM3nnWGIX5uzh k8s-workshop@breda

EOF
}

runDockerRegistry() {
    (
        2>&1 docker run -d -p 443:5000 \
            -v /root/.certs:/certs \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_DOMAIN.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_DOMAIN.key \
            -v /opt/registry/data:/var/lib/registry \
            --name registry registry:2;
    )
}

case "$(hostname)" in
    master)
        clear
        printf "\033[?25l"
        installStdinSpinner
        echo "[$(simple_date)] Setting up... (~2 min)"
        (
            configureGit
            installTools
            waitForDockerUpgrade
            killKubeDNSPods
            waitForDockerRegistryRemote
            waitForKubernetes
            deployDashboard
            waitForWeave
            killKubeProxyPods
            killCoreDNSPods
        ) | stdin-spinner
        echo "[$(simple_date)] done"
        printf "\033[?25h"
        configureSSH
        chmod +x /usr/local/bin/tiny-cd
        bash
    ;;
    node01)
        clear
        printf "\033[?25l"
        installStdinSpinner
        echo "[$(simple_date)] Setting up... (~1 min)"
        (
            installStern
            waitForDockerUpgrade
            runDockerRegistry
            waitForDockerRegistryLocal
            waitForKubernetes
        ) | stdin-spinner
        echo "[$(simple_date)] done"
        printf "\033[?25h"
        echo '# log output from your apps will appear below'
        echo 'node01 $ stern ""'
        stern ""
    ;;
esac
