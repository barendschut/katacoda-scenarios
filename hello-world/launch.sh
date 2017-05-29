echo "Starting Kubernetes v1.2.2..."
docker run -d --net=host gcr.io/google_containers/etcd:2.2.1 /usr/local/bin/etcd --listen-client-urls=http://0.0.0.0:4001 --advertise-client-urls=http://0.0.0.0:4001 --data-dir=/var/etcd/data
docker run -d --name=api --net=host --pid=host --privileged=true gcr.io/google_containers/hyperkube:v1.2.2 /hyperkube apiserver --insecure-bind-address=0.0.0.0 --service-cluster-ip-range=10.0.0.1/24 --etcd_servers=http://127.0.0.1:4001 --v=2
docker run -d --name=kubs --volume=/:/rootfs:ro --volume=/sys:/sys:ro --volume=/dev:/dev --volume=/var/lib/docker/:/var/lib/docker:rw --volume=/var/lib/kubelet/:/var/lib/kubelet:rw --volume=/var/run:/var/run:rw --net=host --pid=host --privileged=true gcr.io/google_containers/hyperkube:v1.2.2 /hyperkube kubelet --allow-privileged=true --containerized --enable-server --hostname-override="127.0.0.1" --address="0.0.0.0" --api-servers=http://0.0.0.0:8080 --cluster_dns=10.0.0.10 --cluster_domain=cluster.local --config=/etc/kubernetes/manifests-multi
echo "Downloading Kubectl..."
curl -o ~/.bin/kubectl http://storage.googleapis.com/kubernetes-release/release/v1.2.2/bin/linux/amd64/kubectl
chmod u+x ~/.bin/kubectl
export KUBERNETES_MASTER=http://host01:8080
echo "Waiting for Kubernetes to start..."
until $(kubectl cluster-info &> /dev/null); do
  sleep 1
done
echo "Starting Kubernetes Proxy..."
docker run -d --name=proxy --net=host --privileged gcr.io/google_containers/hyperkube:v1.2.2 /hyperkube proxy --proxy-mode=userspace --master=http://0.0.0.0:8080 --v=2
echo "Kubernetes started"
echo "Starting Kubernetes DNS..."
kubectl -s http://host01:8080 create -f ~/kube-system.json
kubectl -s http://host01:8080 create -f ~/skydns-rc.yaml
kubectl -s http://host01:8080 create -f ~/skydns-svc.yaml
echo "Starting Kubernetes UI..."
kubectl -s http://host01:8080 create -f ~/dashboard.yaml
kubectl -s http://host01:8080 cluster-info

