#!/bin/sh

open_manager_ports() {
    # Kubernetes API server
    ufw allow 6443/tcp
    # etcd server client API
    ufw allow 2379:2380/tcp
    # Kubelet API
    ufw allow 10250/tcp
    # kube-scheduler
    ufw allow 10259/tcp
    # kube-controller-manager
    ufw allow 10257/tcp
}

open_worker_ports() {
    # Kubelet API
    ufw allow 10250/tcp
    # NodePort Services
    ufw allow 30000:32767/tcp
}

disable_swap() {
    swapoff -a
}

install_kube() {
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    sudo apt-get install -y build-essential

    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
}

install_cri_dockerd() {
    # taken from https://github.com/Mirantis/cri-dockerd

    wget https://storage.googleapis.com/golang/getgo/installer_linux
    chmod +x ./installer_linux
    ./installer_linux

    source ~/.bash_profile

    git clone https://github.com/Mirantis/cri-dockerd.git

    cd cri-dockerd || return
    mkdir bin
    go get && go build -o bin/cri-dockerd
    mkdir -p /usr/local/bin
    install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
    cp -a packaging/systemd/* /etc/systemd/system
    sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
    systemctl daemon-reload
    systemctl enable cri-docker.service
    systemctl enable --now cri-docker.socket
    cd ../
}

verify_br_netfilter_loaded() {
    if lsmod | grep br_netfilter; then
        return 1
    else
        echo "ERROR: br_netfilter is not loaded"
        return 0
    fi
}

verify_iptables_is_1() {
    if sysctl -a | grep "net.bridge.bridge-nf-call-iptables = 1"; then
        return 1
    else
        echo "ERROR: net.bridge.bridge-nf-call-iptables is not set to 1"
        return 0
    fi
}

kubadm_init() {
    kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock

    export KUBECONFIG=/etc/kubernetes/admin.conf
}

join_cluster() {
    kubeadm join 167.71.68.72:6443 --token d3wgfd.rgr3m143mpoikuii \
        --discovery-token-ca-cert-hash sha256:b0de10d9ddcee769954c139c2f27394b76b058324967ada610243238907c612a \
        --cri-socket unix:///var/run/cri-dockerd.sock
}

setup_worker_node() {
    # Open the needed ports
    open_worker_ports

    install_kube

    install_cri_dockerd

    join_cluster
}
