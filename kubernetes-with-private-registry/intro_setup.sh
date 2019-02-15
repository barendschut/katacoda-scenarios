alias ssh="ssh -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error";
alias scp="scp -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error";
REGISTRY_DOMAIN=registry.workshop.breda.local;
REGISTRY_IP=[[HOST_IP]];
CERTS_PATH=~/.certs;

echo "$REGISTRY_IP" > /registry-ip.txt
