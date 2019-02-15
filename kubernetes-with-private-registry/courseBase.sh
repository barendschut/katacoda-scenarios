ssh root@master "curl -H 'Cache-Control: no-cache' -sSL https://gist.githubusercontent.com/sgreben/ad6a970948642f251a9ecfc9366f618f/raw | sed 's/HOST0_IP/[[HOST_IP]]/g;s/HOST1_IP/[[HOST1_IP]]/g;s/HOST2_IP/[[HOST2_IP]]/g;' > /opt/setup.sh; chmod +x /opt/setup.sh; /opt/setup.sh"
true
true
true
true
true
true
true
true
true
true
true
true
