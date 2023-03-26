# setup kubernetes cluster

ref: [https://adamtheautomator.com/cri-o/](https://adamtheautomator.com/cri-o/)

---

## Enabling kernel modules (overlay and br_netfilter)

```
modprobe overlay
modprobe br_netfilter
```

## automatically load kernel modules via the config file

```
cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
EOF
```

## Checking kernel module status
```
lsmod | grep overlay
lsmod | grep br_netfilter
```

---

## setting up kernel parameters via config file

```
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```
```
sysctl --system
```
---

## Disabling SWAP
```
swapoff -a
```
### Only for Fedora
```
dnf remove zram-generator-defaults
```

## Check swap
```
cat /proc/swaps
free -m
```

---

## Firewall configuration

### Master node
```
# control plane
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379/tcp
firewall-cmd --permanent --add-port=2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10259/tcp
firewall-cmd --permanent --add-port=10257/tcp

# Calico CNI
firewall-cmd --permanent --add-port=179/tcp
firewall-cmd --permanent --add-port=4789/udp
firewall-cmd --permanent --add-port=4789/tcp
firewall-cmd --permanent --add-port=2379/tcp
```

### Worker node
```
# worker nodes
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp

# Calico CNI
firewall-cmd --permanent --add-port=179/tcp
firewall-cmd --permanent --add-port=4789/udp
firewall-cmd --permanent --add-port=4789/tcp
firewall-cmd --permanent --add-port=2379/tcp
```

### reload firewall
```
firewall-cmd --reload
```

```
FirewallBackend=iptables
```

---

## Install CRI-O

Ref: [Github](https://github.com/cri-o/cri-o/blob/main/install.md#fedora-31-or-later)

### Choosing module version
```
dnf module list | grep cri-o
```

### Install
```
dnf module enable cri-o:$VERSION
dnf install cri-o
```

### update
```
dnf update
```


### CRI-O config

1. edit `/etc/crio/crio.conf`, uncomment `network_dir` and `plugin_dirs`

2. edit `/etc/cni/net.d/100-crio-bridge.conf` and define network subnet IP address for pods (ipam->ranges)

3. restart CRI-O service
  ```
  systemctl restart crio
  ```

### enable CRI-O

```
systemctl enable crio
```

---

## Install Kubeadm

Ref: [kubernetes.io](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl)

### Installation

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
```

### exclude from auto update

edit `/etc/dnf/dnf.conf`
add the following line to the end
```
exclude=kubelet kubeadm kubectl
```

### Pull container images for Kubernetes
```
kubeadm config images pull
```
---

## kubeadm init

```
kubeadm init --pod-network-cidr=[pod_subnet] \
--apiserver-advertise-address=[node_internal_ip] \
--cri-socket=unix:///var/run/crio/crio.sock
--node-name=[node_name]
```
#### e.g. 
```kubeadm init --pod-network-cidr=192.168.107.0/24 \
--apiserver-advertise-address=192.168.7.6 \
--cri-socket=unix:///var/run/crio/crio.sock
```

```
export KUBECONFIG=/etc/kubernetes/admin.conf
```
```
# add to environment
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
```

### Fixing internal ip (for virtualMachines)

Ref: (kubeadm should make the --node-ip option available)[https://github.com/kubernetes/kubeadm/issues/203#issuecomment-478206793]

1. edit `/var/lib/kubelet/kubeadm-flags.env` add --node-ip
2. restart kubelet
```
systemctl daemon-reload && systemctl restart kubelet
```
3. check if it works
```
kubectl get node -o wide
```
---

## Deploy Calico Networking

### Downloading Calico YAML manifest file
```
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
```

### Edit YAML file
Add pods subnet under CALICO_IPV4POOL_CIDR

### Apply YAML file
```
kubectl apply -f calico.yaml
```
---
## Add worker nodes

### show join command
```
# run on master node
kubeadm token create --print-join-command
```

### modify `/etc/hosts` on worker node (add node_name for internal ip)
```
[internal_ip] [node_name]
```
#### e.g.
```
192.168.7.7 worker1
```

### add node
```
kubeadm join [master_ip] --token [token] --discovery-token-ca-cert-hash [hash] --node-name=[node_name]
```

---

# <h1>Common problem</h1>


## <h2>kubernetes dashboard with kubectl proxy shows Error </h2>
```
error trying to reach service: dial tcp [pod_ip] i/o timeout
```

## It seems that this error is related to iptables backend

## Method 1:
Ref: [Mihail Milev](https://mihail-milev.medium.com/no-pod-to-pod-communication-on-centos-8-kubernetes-with-calico-56d694d2a6f4)

```
echo "blacklist ip_tables" >> /etc/modprobe.d/10-blacklist-iptables.conf
dracut -f
```
And then reboot

## METHOD 2: switch to iptables (legacy)
### edit /etc/firewalld/firewalld.conf, change `FirewallBackend` from `nftables` to `iptables`

---

