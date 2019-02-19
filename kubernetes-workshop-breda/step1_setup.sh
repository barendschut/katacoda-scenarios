#!/bin/sh -eu

set +x

until [ -f /opt/hosts.env ]; do
    sleep 1;
done;

. /opt/hosts.env

REGISTRY_DOMAIN=registry.workshop.breda.local;
REGISTRY_IP=$HOST2_IP;
MASTER_IP=$HOST1_IP;
CERTS_PATH=~/.certs.src;

alias simple_date="date +'%H:%M:%S'"

sloppy_ssh() {
    /usr/bin/ssh -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error "$@";
}

sloppy_scp() {
    /usr/bin/scp -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error "$@";
}

waitForDockerRegistryLocal() {
    until
        2>&1 docker inspect -f '{{.ID}}' registry;
    do
        sleep 0.5;
        echo .;
    done
}

waitForDockerUpgrade() {
    until [ -e /opt/upgrade-docker-done ]; do
        sleep 1;
    done;
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
        2>&1 kubectl -v9 --request-timeout=1s version;
    do
        sleep 0.5;
    done
}

waitForWeave() {
    (
        2>&1 kubectl -v9 apply -f https://git.io/weave-kube
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
        2>&1 kubectl -v9 delete pods -lk8s-app=kube-proxy -n kube-system;
        until
            [ "$(kubectl get daemonset -n kube-system kube-proxy -o jsonpath='{.status.numberReady}')" = "2" ];
        do
            echo .;
            sleep 0.5;
        done;
    )
}

killKubeDNSPods() {
    2>&1 kubectl -v9 delete pods -lkubernetes.io/name=KubeDNS -n kube-system;
}

killCoreDNSPods() {
    (
        2>&1 kubectl -v9 delete pods -lk8s-app=coredns -n kube-system;
        2>&1 kubectl -v9 wait deployments/coredns -n kube-system --for condition=Available;
    )
}

deployIngressController() {
    (
        . /opt/hosts.env;
        curl -sSL https://gist.github.com/sgreben/2ba25294973c9e299d6770aea320f780/raw// |
            sed "s/HOST_IP/$HOST1_IP/" |
            2>&1 kubectl -v9 apply -f -;
    )
}

deployDashboard() {
    (
        2>&1 kubectl -v9 apply -f https://gist.github.com/sgreben/bd04d51eb2f683091ba62d7389a564a8/raw//;
        2>&1 kubectl -v9 wait deployments/kubernetes-dashboard -n kube-system --for condition=Available;
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

hideCursor() { printf "\033[?25l"; }
restoreCursor() { printf "\033[?25h"; }

main() {
    case "$(hostname)" in
        master)
            clear;
            echo "[$(simple_date)] Setting up... (~2 min)"
            hideCursor;
            installStdinSpinner;
            (
                installTools &
                (
                    configureGit;
                    upgradeCluster;
                    waitForKubernetes;
                    deployDashboard;
                    deployIngressController;
                    waitForDockerRegistryRemote;
                ) &
                wait;
            ) # | stdin-spinner
            echo "[$(simple_date)] done"
            restoreCursor;
            configureSSH;
            bash;
        ;;
        node01)
            clear;
            hideCursor;
            installStdinSpinner;
            echo "[$(simple_date)] Setting up... (~1 min)"
            (
                installStern;
                waitForDockerUpgrade;
                runDockerRegistry;
                waitForDockerRegistryLocal;
                waitForKubernetes;
            ) | stdin-spinner
            echo "[$(simple_date)] done"
            restoreCursor;
            echo '# log output from your apps will appear below'
            echo 'node01 $ stern ""'
            stern ""
        ;;
    esac
}

upgradeCluster() {
    exec 2>&1;
    killKubeDNSPods;
    setUpRegistryEtcHostsOn node01;
    setUpRegistryEtcHostsOn localhost;
    setUpMasterEtcHostsOn node01;
    copyKubeconfigTo node01;
    #upgradeKubernetesTo v1.12.1;
    #upgradeKubernetesTo v1.13.3;
    kubectl -v9 apply -f https://git.io/weave-kube;
    generateCertsIn "$CERTS_PATH";
    (
        kubernetesDrain node01;
        stopDockerOn node01;
        setUpCertsOn "$CERTS_PATH" node01;
        upgradeDockerOn node01;
        kubernetesUnDrain node01;
    ) &
    (
        kubernetesDrain master;
        stopDockerOn localhost;
        setUpCertsOn "$CERTS_PATH" localhost;
        upgradeDockerOn localhost;
        kubernetesUnDrain master;
    ) &
    wait;
    startDockerOn localhost &
    startDockerOn node01 &
    wait;
}

upgradeKubernetesTo() {
    VERSION="$1"
    upgradeKubeadm;
    (
        kubernetesDrain node01 &
        kubernetesDrain master &
        wait;
    );
    kubeadm upgrade apply -f "$VERSION";
    (
        aptGetUpdateOn node01 &
        aptGetUpdateOn localhost &
        wait;
    );
    upgradeKubeletOn master;
    upgradeKubeletConfigOn node01;
    upgradeKubeletOn node01;
    upgradeKubectlOn node01;
    upgradeKubectlOn master;
    kubernetesUnDrain node01;
    kubernetesUnDrain master;
}

aptGetUpdateOn() {
    HOST="$1"
    2>&1 sloppy_ssh root@"$HOST" "
        export DEBIAN_FRONTEND=noninteractive;
        apt-get -y update;
    ";
}

kubernetesDrain() {
    NODENAME="$1"
    kubectl drain "$NODENAME" --ignore-daemonsets
}

kubernetesUnDrain() {
    NODENAME="$1"
    kubectl uncordon "$NODENAME"
}


upgradeKubeadm() {
    export DEBIAN_FRONTEND=noninteractive;
    apt-mark unhold kubeadm && \
    apt-get install --no-install-recommends -y kubeadm && \
    apt-mark hold kubeadm
}

upgradeKubeletOn() {
    HOST="$1";

    2>&1 sloppy_ssh root@"$HOST" "
        export DEBIAN_FRONTEND=noninteractive;
        apt-get install --no-install-recommends -y kubelet kubeadm;
    ";
}

upgradeKubectlOn() {
    HOST="$1";

    2>&1 sloppy_ssh root@"$HOST" "
        export DEBIAN_FRONTEND=noninteractive;
        apt-get install --no-install-recommends -y kubectl;
    ";
}

upgradeKubeletConfigOn() {
    HOST="$1";

    2>&1 sloppy_ssh root@"$HOST" "
        kubeadm upgrade node config --kubelet-version=\"$(kubelet --version | cut -d ' ' -f 2)\";
        systemctl restart kubelet;
    ";
}

stopDockerOn() {
    HOST="$1"
    2>&1 sloppy_ssh root@"$HOST" "
        service docker stop;
    ";
}

startDockerOn() {
    HOST="$1"
    2>&1 sloppy_ssh root@"$HOST" "
        systemctl daemon-reload;
        service docker start;
    ";
}

upgradeDockerOn() {
    HOST="$1";

    2>&1 sloppy_ssh root@"$HOST" "
        mkdir -p /etc/systemd/system/docker.service.d;
    ";
    2>&1 sloppy_ssh root@"$HOST" "
        cat > /etc/systemd/system/docker.service.d/docker.conf;
    " <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF
    2>&1 sloppy_ssh root@"$HOST" "
        export DEBIAN_FRONTEND=noninteractive;
        apt-get install --no-install-recommends -y docker.io;
        touch /opt/upgrade-docker-done;
    ";
}

killKubeDNSPods() {
    kubectl delete pods -lkubernetes.io/name=KubeDNS -n kube-system || true
}

copyKubeconfigTo() {
    HOST="$1";
    until [ -f /root/.kube/config ]; do
        sleep 1;
    done;
    2>&1 sloppy_ssh root@"$HOST" "
        mkdir -p /root/.kube/;
    ";
    sloppy_scp /root/.kube/config root@"$HOST":/root/.kube/
}

setUpRegistryEtcHostsOn() {
    HOST="$1";
    2>&1 sloppy_ssh root@"$HOST" "
        echo '${REGISTRY_IP}' '${REGISTRY_DOMAIN}' >> /etc/hosts
    "
}

setUpMasterEtcHostsOn() {
    HOST="$1";
    2>&1 sloppy_ssh root@"$HOST" "
        echo '${MASTER_IP}' master >> /etc/hosts
    "
}

generateCertsIn() {
    export REGISTRY_DOMAIN;
    CERTS_PATH="$1";
    mkdir -p "$CERTS_PATH";
    (
        set -eu;
        cd "$CERTS_PATH"
        # Generate a root key
        openssl genrsa -out rootCA.key 512;
        # Generate a root certificate
        openssl req -x509 -new -nodes -key rootCA.key -days 365 \
            -subj "/C=UK/ST=TEST/L=TEST/O=TEST/CN=${REGISTRY_DOMAIN}" \
            -out rootCA.crt;
        # Generate key for host
        openssl genrsa -out ${REGISTRY_DOMAIN}.key;
        # Generate CSR
        openssl req -new -key ${REGISTRY_DOMAIN}.key \
            -subj "/C=UK/ST=TEST/L=TEST/O=TEST/CN=${REGISTRY_DOMAIN}" \
            -out ${REGISTRY_DOMAIN}.csr;
        # Sign certificate request
        openssl x509 -req -in ${REGISTRY_DOMAIN}.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -days 365 -out ${REGISTRY_DOMAIN}.crt;
    )
}

setUpCertsOn() {
    export REGISTRY_DOMAIN;
    CERTS_PATH="$1";
    HOST="$2";
    2>&1 sloppy_ssh root@"$HOST" "
        mkdir -p /root/.certs;
        mkdir -p /usr/local/share/ca-certificates/${REGISTRY_DOMAIN};
        mkdir -p /etc/docker/certs.d/${REGISTRY_DOMAIN};
    ";
    sloppy_scp "$CERTS_PATH"/rootCA.crt root@"$HOST":/usr/local/share/ca-certificates/${REGISTRY_DOMAIN};
    sloppy_scp "$CERTS_PATH"/rootCA.crt root@"$HOST":/etc/docker/certs.d/${REGISTRY_DOMAIN}/ca.crt;
    sloppy_scp -r "$CERTS_PATH"/* root@"$HOST":/root/.certs/;
    2>&1 sloppy_ssh root@"$HOST" "
        update-ca-certificates;
    ";
}

main;
