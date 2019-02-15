set -eu;
alias ssh="ssh -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error";
alias scp="scp -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error";
REGISTRY_DOMAIN=registry.workshop.breda.local;
REGISTRY_IP=[[HOST_IP]];
CERTS_PATH=~/.certs;

main() {
    getKubeconfigFrom master;
    generateCertsIn "$CERTS_PATH"
    runDockerRegistry "$REGISTRY_IP";
    setUpCertsOn "$CERTS_PATH" master;
    setUpCertsOn "$CERTS_PATH" node01;
    setUpEtcHostsOn master;
    setUpEtcHostsOn node01;
}

getKubeconfigFrom() {
    MASTER_HOST="$1";
    scp root@"$MASTER_HOST":/root/.kube/config ~/.kube/;
}

setUpEtcHostsOn() {
    ssh root@"$MASTER_HOST" "
        echo '${REGISTRY_IP}' '${REGISTRY_DOMAIN}' >> /etc/hosts
    "
}

runDockerRegistry() {
    MASTER_HOST="$1";
    ssh root@"$MASTER_HOST" "
        docker run -d -p 5000:5000 \
            -v /root/certs:/certs \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_DOMAIN.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_DOMAIN.key \
            -v /opt/registry/data:/var/lib/registry \
            --name registry registry:2;
    ";
}

generateCertsIn() {
    export REGISTRY_DOMAIN;
    CERTS_PATH="$1";
    mkdir -p "$CERTS_PATH";
    (
        set -eu;
        cd "$CERTS_PATH"
        # Generate a root key
        openssl genrsa -out rootCA.key;
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
    MASTER_HOST="$2";
    ssh root@"$MASTER_HOST" "
        mkdir -p /usr/local/share/ca-certificates/${REGISTRY_DOMAIN}
        mkdir -p /etc/docker/certs.d/${REGISTRY_DOMAIN}
    "
    scp "$CERTS_PATH"/rootCA.crt root@"$MASTER_HOST":/usr/local/share/ca-certificates/${REGISTRY_DOMAIN}
    scp "$CERTS_PATH"/rootCA.crt root@"$MASTER_HOST":/etc/docker/certs.d/${REGISTRY_DOMAIN}/ca.crt
    scp -r "$CERTS_PATH" root@"$MASTER_HOST":/root/certs
    ssh root@"$MASTER_HOST" "
        update-ca-certificates
        sudo service docker restart
    "
}

main;
