ssh root@master "printf 'HOST0_IP=[[HOST_IP]];\nHOST1_IP=[[HOST1_IP]];\nHOST2_IP=[[HOST2_IP]];\n' > /opt/hosts.env; curl -sSLo /opt/setup.sh https://gist.githubusercontent.com/sgreben/ad6a970948642f251a9ecfc9366f618f/raw; chmod +x /opt/setup.sh; /opt/setup.sh"
