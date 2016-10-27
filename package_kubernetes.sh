#!/bin/bash

# This script takes a release package of kubernetes and creates charm resources.

#set -e
SCRIPT_DIR=$PWD

if [ -z $1 ]; then
  echo -n "Provide a full path to the source tar file: "
  read RELEASE_TAR
else
  RELEASE_TAR=$1
fi

TEMPORARY_KUBERNETES_DIR=/tmp/kubernetes
mkdir -p $TEMPORARY_KUBERNETES_DIR
echo "Expanding ${RELEASE_TAR} to ${TEMPORARY_KUBERNETES_DIR}"

ARCHITECTURES="amd64 arm64 ppc64le s390x"
for ARCH in ${ARCHITECTURES}; do
  ARCH_DIR=$TEMPORARY_KUBERNETES_DIR/$ARCH
  mkdir -p $ARCH_DIR
  TARGET_SERVER_FILE=kubernetes/server/kubernetes-server-linux-$ARCH.tar.gz
  if ! tar -tzf $RELEASE_TAR $TARGET_SERVER_FILE 2>/dev/null; then
    echo "Could not find ${ARCH} in ${RELEASE_TAR}"
    continue
  fi
  TARGET_FILES="$TARGET_SERVER_FILE kubernetes/version"
  tar -xvzf $RELEASE_TAR -C $ARCH_DIR $TARGET_FILES

  VERSION=`cat ${ARCH_DIR}/kubernetes/version`
  TEMPORARY_SERVER_DIR=$ARCH_DIR/server
  mkdir -p $TEMPORARY_SERVER_DIR
  echo "Expanding ${TARGET_SERVER_FILE} to ${TEMPORARY_SERVER_DIR}"
  tar -xvzf $ARCH_DIR/$TARGET_SERVER_FILE -C $TEMPORARY_SERVER_DIR

  cd $ARCH_DIR/server/kubernetes/server/bin
  echo "Creating the ${SCRIPT_DIR}/kubernetes-master-${VERSION}-${ARCH}.tar.gz file."
  MASTER_BINS="kube-apiserver kube-controller-manager kubectl kube-dns kube-scheduler"
  tar -cvzf $SCRIPT_DIR/kubernetes-master-$VERSION-$ARCH.tar.gz $MASTER_BINS
  echo "Creating the ${SCRIPT_DIR}/kubernetes-worker-${VERSION}-${ARCH}.tar.gz file."
  WORKER_BINS="kubectl kubelet kube-proxy"
  tar -cvzf $SCRIPT_DIR/kubernetes-worker-$VERSION-$ARCH.tar.gz $WORKER_BINS
done
echo Finished
cd $SCRIPT_DIR

rm -rf $TEMPORARY_KUBERNETES_DIR
