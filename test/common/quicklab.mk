build-otron-image:
	docker build -t respnet-otron-base -f ../common/Dockerfile.otron .

start: build-otron-image
	$(CLAB_BIN) deploy --topo $(TESTENV:respnet-%=%).clab.yml --log-level trace --reconfigure

stop:
	$(CLAB_BIN) destroy --topo $(TESTENV:respnet-%=%).clab.yml --log-level trace

.PHONY: wait $(addprefix wait-,$(ROUTERS_XR) $(ROUTERS_CRPD))
WAIT?=60
wait: $(addprefix platform-wait-,$(ROUTERS_XR) $(ROUTERS_CRPD))

copy:
	docker cp ../../out/bin/respnet $(TESTENV)-otron:/respnet
	docker cp l3vpn-svc.xml $(TESTENV)-otron:/l3vpn-svc.xml
	docker cp netinfra.xml $(TESTENV)-otron:/netinfra.xml

run:
	docker exec $(INTERACTIVE) $(TESTENV)-otron /respnet --rts-bt-dbg

ifndef CI
INTERACTIVE=-it
endif

run-and-configure:
	docker exec $(INTERACTIVE) -e EXIT_ON_DONE=$(CI) $(TESTENV)-otron /respnet netinfra.xml l3vpn-svc.xml --rts-bt-dbg

configure:
	$(MAKE) FILE="netinfra.xml" send-config
	$(MAKE) FILE="l3vpn-svc.xml" send-config

.PHONY: shell
shell:
	docker exec -it $(TESTENV)-otron bash -l

.PHONY: send-config
send-config:
	curl -X PUT -H "Content-Type: application/yang-data+xml" -d @$(FILE) http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/restconf

.PHONY: send-config-json
send-config-json:
	curl -X PUT -H "Content-Type: application/yang-data+json" -d @$(FILE) http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/restconf

.PHONY: send-config-tmf
send-config-tmf:
	curl -X POST -H "Content-Type: application/json" -d @$(FILE) http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/tmf-api/serviceOrdering/v4/serviceOrder

.PHONY: get-config-tmf
get-config-tmf:
	curl -X GET http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/tmf-api/serviceOrdering/v4/serviceOrder$(if $(ID),/$(ID),)

.PHONY: get-config0 get-config1 get-config2 get-config3
get-config0 get-config1 get-config2 get-config3:
	curl -H "Accept: application/yang-data+xml" http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/layer/$(subst get-config,,$@)

.PHONY: get-config-json0 get-config-json1 get-config-json2 get-config-json3
get-config-json0 get-config-json1 get-config-json2 get-config-json3:
	@curl -H "Accept: application/yang-data+json" http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/layer/$(subst get-config-json,,$@)

.PHONY: delete-config
delete-config:
	curl -X DELETE http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' $(TESTENV)-otron)/restconf/netinfra:netinfra/routers=STO-CORE-1

.PHONY: $(addprefix cli-,$(ROUTERS_XR) $(ROUTERS_CRPD))
$(addprefix cli-,$(ROUTERS_XR) $(ROUTERS_CRPD)): cli-%: platform-cli-%

.PHONY: $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD))
$(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD)):
	docker run $(INTERACTIVE) --rm --network container:$(TESTENV)-otron ghcr.io/notconf/notconf:debug netconf-console2 --host $(@:get-dev-config-%=%) --port 830 --user clab --pass clab@123 --get-config

.phony: test
test::
	$(MAKE) $(addprefix get-dev-config-,$(ROUTERS_XR) $(ROUTERS_CRPD))
