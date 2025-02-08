
.PHONY: build
build:
	acton build --dev $(DEP_OVERRIDES)

.PHONY: build-ldep
build-ldep:
	$(MAKE) build DEP_OVERRIDES="--dep netconf=../netconf --dep orchestron=../orchestron --dep yang=../acton-yang"

.PHONY: test
test:
	acton test $(DEP_OVERRIDES)

test-ldep:
	$(MAKE) test DEP_OVERRIDES="--dep netconf=../netconf --dep orchestron=../orchestron --dep yang=../acton-yang"

.PHONY: gen
gen:
	cd gen && acton build --dev $(DEP_OVERRIDES) && out/bin/respnet_gen

.PHONY: gen-ldep
gen-ldep:
	$(MAKE) gen DEP_OVERRIDES="--dep netconf=../../netconf --dep orchestron=../../orchestron --dep yang=../../acton-yang"

build-junos:
	acton --dev src/respnet/devices/JuniperCRPD_23_4R1_9.act
