ssh root@master "rm -f /opt/hosts.env; echo 'HOST0_IP=[[HOST_IP]]' >> /opt/hosts.env; echo 'HOST1_IP=[[HOST1_IP]]' >> /opt/hosts.env; echo 'HOST2_IP=[[HOST2_IP]]' >> /opt/hosts.env;"
