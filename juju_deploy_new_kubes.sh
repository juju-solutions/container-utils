#!/bin/bash
set -e

if [ -z $1 ]; then
  echo "No model specified using `juju switch`"
else
  juju add-model $1
fi
juju model-defaults enable-os-refresh-update=false
juju model-defaults enable-os-upgrade=false

echo -n "Rebuild from layers? [y/n]: "
read USER_INPUT

if [ "${USER_INPUT}" == "y" || "${USER_INPUT}" == "Y" ]; then
  WORKDIR=$PWD
  cd $LAYER_PATH/easyrsa
  charm build -r 
  cd $LAYER_PATH/flannel
  charm build -r --no-local-layers
  cd $LAYER_PATH/etcd
  charm build -r
  cd $LAYER_PATH/kubeapi-load-balancer
  charm build -r
  cd $LAYER_PATH/kubernetes-master
  charm build -r 
  cd $LAYER_PATH/kubernetes-worker
  charm build -r
  cd $WORK_DIR
fi

echo -n "Deploy local Kubernetes charms? [y/n]: "
read USER_INPUT

if [ "${USER_INPUT}" == "y" || "${USER_INPUT}" == "Y" ]; then
  juju deploy $JUJU_REPOSITORY/builds/kubernetes-master
  juju deploy $JUJU_REPOSITORY/builds/kubernetes-worker
  juju deploy $JUJU_REPOSITORY/builds/etcd 
  juju deploy $JUJU_REPOSITORY/builds/flannel
  juju deploy $JUJU_REPOSITORY/builds/kubeapi-load-balancer
  juju deploy $JUJU_REPOSITORY/builds/easyrsa
fi

echo -n "Attach resources? [y/n]: "
read USER_INPUT

if [ "${USER_INPUT}" == "y" || "${USER_INPUT}" == "Y" ]; then
  echo "Attaching Resources...."
  juju attach easyrsa easyrsa=~/Downloads/resources/EasyRSA-3.0.1.tgz
  juju attach flannel flannel=~/Downloads/resources/flannel-v0.6.1-amd64.tar.gz
  juju attach kubernetes-master kubernetes=~/Downloads/resources/kubernetes-master-v1.4.4-amd64.tar.gz
  juju attach kubernetes-worker kubernetes=~/Downloads/resources/kubernetes-worker-v1.4.4-amd64.tar.gz
fi 

echo "Converging Relations..."
juju add-relation kubernetes-master:kube-api-endpoint kubeapi-load-balancer:apiserver
juju add-relation kubernetes-master:loadbalancer kubeapi-load-balancer:loadbalancer
juju add-relation kubernetes-master:cluster-dns kubernetes-worker:kube-dns
juju add-relation kubernetes-master easyrsa
juju add-relation kubernetes-master etcd
juju add-relation kubernetes-master flannel
juju add-relation kubernetes-worker easyrsa
juju add-relation kubernetes-worker flannel
juju add-relation kubernetes-worker kubeapi-load-balancer
juju add-relation flannel etcd
juju add-relation kubeapi-load-balancer easyrsa
juju expose kubeapi-load-balancer
