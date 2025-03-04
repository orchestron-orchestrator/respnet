ifeq (true,$(REMOTE_CONTAINERS))
CLAB_BIN:=sudo containerlab
else
PROJECT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

CLAB_VERSION?=0.64.0
CLAB_CONTAINER_IMAGE?=ghcr.io/srl-labs/clab:$(CLAB_VERSION)
CLAB_BIN:=docker run --rm $(INTERACTIVE) --privileged \
    --network host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/run/netns:/var/run/netns \
    -v /etc/hosts:/etc/hosts \
    -v /var/lib/docker/containers:/var/lib/docker/containers \
	-v ${HOME}/.docker:/root/.docker \
    --pid="host" \
    -v $(PROJECT_DIR):$(PROJECT_DIR) \
    -w $(CURDIR) \
    $(CLAB_CONTAINER_IMAGE) containerlab
endif
