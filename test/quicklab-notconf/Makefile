include clab.mk

build-otron-image:
	docker build -t respnet-otron-base -f Dockerfile.otron .

start: build-otron-image
	$(CLAB_BIN) deploy --topo quicklab-notconf.clab.yml --log-level trace --reconfigure

stop:
	$(CLAB_BIN) destroy --topo quicklab-notconf.clab.yml --log-level trace

copy:
	docker cp ../../out/bin/respnet respnet-quicklab-notconf-otron:/respnet
	docker cp l3vpn-svc1.xml respnet-quicklab-notconf-otron:/l3vpn-svc1.xml
	docker cp l3vpn-svc2.xml respnet-quicklab-notconf-otron:/l3vpn-svc2.xml

run-xr-only:
	docker exec -it respnet-quicklab-notconf-otron /respnet l3vpn-svc1.xml --rts-bt-dbg

run:
	docker exec -it respnet-quicklab-notconf-otron /respnet l3vpn-svc2.xml --rts-bt-dbg

.PHONY: shell
shell:
	docker exec -it respnet-quicklab-notconf-otron bash -l

.PHONY: send-config
send-config:
	curl -X PUT -H "Content-Type: application/yang-data+xml" -d @$(FILE) http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' respnet-quicklab-notconf-otron)/restconf

.PHONY: send-config-json
send-config-json:
	curl -X PUT -H "Content-Type: application/yang-data+json" -d @$(FILE) http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' respnet-quicklab-notconf-otron)/restconf

.PHONY: get-config0 get-config1 get-config2 get-config3
get-config0 get-config1 get-config2 get-config3:
	curl -H "Accept: application/yang-data+xml" http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' respnet-quicklab-notconf-otron)/layer/$(subst get-config,,$@)

.PHONY: get-config-json0 get-config-json1 get-config-json2 get-config-json3
get-config-json0 get-config-json1 get-config-json2 get-config-json3:
	@curl -H "Accept: application/yang-data+json" http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' respnet-quicklab-notconf-otron)/layer/$(subst get-config-json,,$@)

.PHONY: delete-config
delete-config:
	curl -X DELETE http://localhost:$(shell docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' respnet-quicklab-notconf-otron)/restconf/netinfra:netinfra/routers=STO-CORE-1
