# RESPNET

RESPNET, the REalistic Service Provider Network, is an example of network automation to automate a rather realistic looking SP network. This repository contains a RESPNET implementation POC based on Orchestron.

## Getting started

Set up your development environment using one of the methods outlined in the
[Preparing the Development Environment](#preparing-the-development-environment)
chapter. You should have the dependencies (Acton, Containerlab) installed and
the project source checked out.

### Building the RESPNET application

To compile the code (`make build`) and run unit tests (`make test`):

```shell
$ make build
acton build --dev
Building dependencies:
 - orchestron
 - yang
 - netconf
# this takes some time the first time, but later uses cached artifacts
#[ more compiler output]
  Final compilation step
   Finished final compilation step in   0.258 s
...

```shell
$ make test
# [ more compiler output ]
Tests - module respnet.cisco_vigenere:
  encrypt:               OK:  292 runs in 50.249ms
  decrypt:               OK:  286 runs in 50.938ms

Tests - module respnet.test_inter:
  inter_bblink:          OK:   84 runs in 50.026ms

Tests - module test_respnet:
  netinfra1:             OK:    2 runs in 51.708ms
  l3vpn_svc:             OK:    1 runs in 71.408ms

All 5 tests passed (5.589s)
```

The result of `make build` is a single binary `out/bin/respnet`. The
application uses the Orchestron framework to expose a northbound NETCONF /
RESTCONF interface with the CFS models, RFS transforms and the NETCONF client
to configure the devices.

### Running the RESPNET application

After building, you may run the application in one of the included testenvs.
All the testenvs share the same topology, a core network consisting of four PE
routers. Two of the PE routers are Juniper, two are Cisco:

Each PE router has a single CPE attached via a VLAN 100 access interface. All
four CPEs belong to a single customer and are then configured into a single
L3VPN MPLS VPN.

```
+-------------------+                                                                     +-------------------+   
|      cust-1       |                                                                     |      cust-3       |   
|    10.200.1.1     |                                                                     |    10.200.1.3     |   
|  (Cisco IOS XRd)  |                                                                     |  (Cisco IOS XRd)  |   
+----+--------------+                                                                     +--+----------------+   
     |Gi0/0/0/0.100                                                                          |Gi0/0/0/0.100       
     |                                                                                       |                    
     +-------------------+                                                                   |                    
                         |                                                                   |                    
                         |Gi0/0/0/2.100                                                      |                    
                      +--+----------------+                          +-------------------+   |                    
                      |    ams-core-1     |Gi0/0/0/1                 |    sto-core-1     |   |                    
                      |     10.0.0.1      +--------------------------+     10.0.0.3      +---+                    
                      |  (Cisco IOS XRd)  |                      eth1|  (Juniper cRPD)   |eth4.100                
                      +--+----------------+                          +--+--------------+-+                        
                         |Gi0/0/0/0                                     |eth2      eth3|                          
                         |                                              |              |                          
                         |                                              |              |                          
                         |                                              |              |                          
                         |                           +------------------+              |                          
                         |                           |                                 |                          
                         |                           |                                 |                          
                         |                           |                                 |                          
                         |                           |                                 |                          
                         |Gi0/0/0/1                  |                             eth2|                          
                      +--+----------------+Gi0/0/0/2 |               +-----------------+-+                        
                      |    fra-core-1     +----------+               |    lju-core-1     |                        
                      |     10.0.0.2      |Gi0/0/0/3             eth1|     10.0.0.4      |                        
                      |  (Cisco IOS XRd)  +--------------------------+   1Juniper cRPD)  |                        
                      +---+---------------+                          +--------+----------+                        
                          |Gi0/0/0/4.100                                      |eth3.100                           
                          |                                                   |                                   
 +-------------------+    |                                                   |              +-------------------+
 |      cust-2       |    |                                                   |              |      cust-44      |
 |    10.200.1.2     +----+                                                   |Gi0/0/0/0.100 |    10.200.1.4     |
 |  (Cisco IOS XRd)  |Gi0/0/0/0.100                                           +--------------+  (Cisco IOS XRd)  |
 +-------------------+                                                                       +-------------------+
 ```

The three testenvs are fully containerized and the topology is defined as a
Containerlab topology YAML (file `$TESTENV.clab.yml`)
- `test/quicklab`: fully functioning network using Juniper cRPD and Cisco IOS XRd
  for PE routers, Cisco IOS XRd for CPE. Requires x86_64.
- `test/quicklab-crpd`: fully functioning network using only Juniper cRPD for
  all devices ([runs native on ARM64](#running-on-arm64-like-apple-silicon))
- `test/quicklab-notconf`: simulated core network PE routers using [notconf](https://github.com/notconf/notconf)

All testenvs share a common interface for startup, using RESPNET to create an
L3VPN MPLS VPN service and verifying the configuration was applied to the
network.

To start the testenv, use the `start` recipe, then `run-and-configure` to start
RESPNET and apply the configuration immediately.

```shell
$ make -C test/quicklab-notconf start
# [ a lot of containerlab output ]
````

```shell
$ make -C test/quicklab-notconf run-and-configure
# [ a lot of Orchestron output ]
All config files applied
```

After RESPNET is done with applying the configuration (`All config files
applied`), you may verify the device config over NETCONF using the
`get-dev-config-<device>` recipe:

```shell
make -C test/quicklab-notconf get-dev-config-lju-core-1
# [ a lot of XML config output for L3VPN MPLS VPN ]
      <mpls>
        <interface>
          <name>eth1</name>
        </interface>
        <interface>
          <name>eth2</name>
        </interface>
      </mpls>
    </protocols>
  </configuration>
</data>
```

If you are using one of the testenvs with real containerized routers
(`test/quicklab` or `test/quicklab-crpd`) then you may also connect to any of
the devices CLI to examine the routing tables and verify connectivity. For
example, check the core routing table on *ams-core-1* (credentials
`clab/clab@123`):

```shell
$ make -C test/quicklab cli-ams-core-1
docker exec -it respnet-quicklab-ams-core-1 /pkg/bin/xr_cli.sh

User Access Verification

Username: clab
Password:


RP/0/RP0/CPU0:AMS-CORE-1#show route
Fri Mar  7 09:41:11.793 UTC

Codes: C - connected, S - static, R - RIP, B - BGP, (>) - Diversion path
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2, E - EGP
       i - ISIS, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, su - IS-IS summary null, * - candidate default
       U - per-user static route, o - ODR, L - local, G  - DAGR, l - LISP
       A - access/subscriber, a - Application route
       M - mobile route, r - RPL, t - Traffic Engineering, (!) - FRR Backup path

Gateway of last resort is 172.25.1.1 to network 0.0.0.0

S*   0.0.0.0/0 [1/0] via 172.25.1.1, 19:25:30, MgmtEth0/RP0/CPU0/0
L    10.0.0.1/32 is directly connected, 19:24:50, Loopback0
i L2 10.0.0.2/32 [115/5000] via 10.0.7.2, 19:24:40, GigabitEthernet0/0/0/0
i L2 10.0.0.3/32 [115/5000] via 10.0.20.2, 19:24:14, GigabitEthernet0/0/0/1
i L2 10.0.0.4/32 [115/10000] via 10.0.7.2, 19:24:13, GigabitEthernet0/0/0/0
                 [115/10000] via 10.0.20.2, 19:24:13, GigabitEthernet0/0/0/1
C    10.0.7.0/30 is directly connected, 19:24:50, GigabitEthernet0/0/0/0
L    10.0.7.1/32 is directly connected, 19:24:50, GigabitEthernet0/0/0/0
i L2 10.0.18.0/30 [115/10000] via 10.0.7.2, 19:24:40, GigabitEthernet0/0/0/0
C    10.0.20.0/30 is directly connected, 19:24:50, GigabitEthernet0/0/0/1
L    10.0.20.1/32 is directly connected, 19:24:50, GigabitEthernet0/0/0/1
i L2 10.0.25.0/30 [115/10000] via 10.0.7.2, 19:24:14, GigabitEthernet0/0/0/0
                  [115/10000] via 10.0.20.2, 19:24:14, GigabitEthernet0/0/0/1
i L2 10.0.31.0/30 [115/10000] via 10.0.20.2, 19:24:14, GigabitEthernet0/0/0/1
C    172.25.1.0/24 is directly connected, 19:25:30, MgmtEth0/RP0/CPU0/0
L    172.25.1.6/32 is directly connected, 19:25:30, MgmtEth0/RP0/CPU0/0
RP/0/RP0/CPU0:AMS-CORE-1#
```

Or ping the *cust-4* loopback from *cust-1* (credentials `clab/clab@123`):

```shell
$ make -C test/quicklab cli-cust-1
make: Entering directory '/home/mzagozen/orchestron/respnet/test/quicklab'
docker exec -it respnet-quicklab-cust-1 /pkg/bin/xr_cli.sh

User Access Verification

Username: clab
Password:


RP/0/RP0/CPU0:cust-1#ping 10.200.1.4
Fri Mar  7 09:43:16.164 UTC
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.200.1.4 timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 2/3/5 ms
RP/0/RP0/CPU0:cust-1#
```

A full-mesh ping test between all customer sites is also available in the
testenvs with real containerized routers:

```shell
$ make -C test/quicklab test-ping
# [ a lot of ping output ]
make[1]: Entering directory '/home/mzagozen/orchestron/respnet/test/quicklab'
timeout 10s bash -c "until docker exec -t respnet-quicklab-cust-1 ip netns exec global-vrf ping -c 1 -W 1 10.200.1.2; do sleep 1; done"
PING 10.200.1.2 (10.200.1.2) 56(84) bytes of data.
64 bytes from 10.200.1.2: icmp_seq=1 ttl=253 time=4.02 ms
```

### Modifying the RESPNET application

Changing the application typically involves modifying the RFS transforms to
modify the output configuration and optionally modifying the models.
If you just change the RFS or any other transform without needing to change the
YANG models, run `make build` and restart the RESPNET application. To stop a
previously running instance Press *Ctrl+C* in the terminal window where it is
running.

```shell
$ make build
# [ build output ]

$ make -C test/<your-testenv> copy run-and-configure
```

This will copy over a fresh version of the orchestron/respnet app and run it in
the container part of the quicklab dev environment.

So the typical REPL loop is like:
- edit code
- in `test/quicklab`: `(cd ../../ && make build ) && make copy run-and-configure` and see the code run interactively

If you also modified the YANG models in `respnet_gen.act`, then you also need
to regenerate the layer dataclasses with `make gen` and then run `make build`
and restart the application.

```shell
$ make gen
# [ compiler output ]
Generating model 1
Generating model 2
+ Device type JuniperCRPD_23_4R1_9 adata unchanged
Generating app layers.act
+ App layers.act changed

$ make build
# [ more compiler output ]
```

## Preparing the Development Environment

You have a choice for how to run your development environment:
- [locally installed dependencies on your machine](#local-development)
  - on Linux or MacOS on x86_64
  - on Linux or MacOS on arm64 (Apple Silicon)
- [Dev Containers](#dev-container)
- [GitHub Codespaces](#github-codespaces)

### Local development

Install dependencies:
- Acton tip: https://acton.guide/install_tip.html
- Docker
  - See MacOS instructions below, see MacOS instructions below
- For native Linux, make sure you have *vrf* and *mpls_iptunnel* kernel modules
  loaded for cRPD to function properly
- Follow the [Getting started guide](#getting-started)

#### MacOS

For MacOS, you need a runtime for Docker, like Colima. By default Colima uses a
minimal Ubuntu VM that lacks extra kernel modules.. For cRPD to properly forward
MPLS traffic, we need the *vrf* and *mpls_iptunnel* kernel modules in the VM.

``` shell
# brew.sh to install Homebrew if you don't have it
brew install colima docker
colima start
colima list
colima ssh
# Now you are inside the Colima VM where we will add kernel modules necessary for MPLS to work
sudo apt update
sudo apt install linux-modules-extra-$(uname -r)
# exit from colima VM
exit
# Now we are ready to run containers!
```

#### Running on ARM64 (like Apple silicon)

The default `quicklab` testenv uses a mix of Juniper cRPD and Cisco IOS XRd
containers for the core PE routers and Cisco IOS XRd for the CPE devices. This
works well on x86_64, but not so much on ARM64. Juniper cRPD runs on arm64,
including in the colima VM if you are using MacOS whereas Cisco XRd does not.

To that end, the `quicklab-crpd` testenv contains only Juniper cRPD devices for
both PE and CPE. To run the containers natively on ARM64 make sure to download
the ARM64 container images from Juniper. Note how the `quicklab-crpd` testenv
contains no references to ARM64 - the container image referenced is a
[multi-arch manifest](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/).
The docker client will pick up the image matching the runtime platform when
pulling images.

Then in your [favorite terminal emulator](https://ghostty.org) on MacOS:

```shell
make build-aarch64  # We're cross-compiling for aarch64 running in the Linux VM
make -C test/quicklab-crpd start
make -C test/quicklab-crpd copy run-and-configure
```

### Dev Container

This repository includes a [Development Container](https://containers.dev)
configuration. The container image includes everything you need to get started,
apart from the licensed containerized router images. Use VS Code to open this
project and it will detect the dev container configuration automatically.

TL;DR: use:
- `.devcontainer/docker-in-docker/devcontainer.json` for GitHub Codespaces
- `.devcontainer/devcontainer.json` for local development

There are two flavors of the container:

1. *docker-outside-of-docker*: This is the default for local development.
   containerlab and other tools will run inside the dev container and will use
   the hosts Docker daemon for new containers. This means your dev container is
   a sibling to the testenv containers and you can also interact with the new
   containers from your host OS.
2. *docker-in-docker*: This is the default for Codespaces. The dev container
   runs its own nested Docker daemon so the containers you start for testenvs
   are only visible to the dev container.

If you're using GitHub Codespaces, use the *docker-in-docker* flavor.

### GitHub Codespaces

GitHub Codespaces is a VM managed by GitHub that runs the Dev Container (part
of this project) and VS Code that is made available in your browser or as a
Remote environment you connect to from your local VS Code.

To start your codespace you will need a free GitHub account. Your GitHub
account includes a free monthly quota of compute hours (120 at the time of
writing). We recommend using a 4-core VM for development, which means you
effectively get 30 hours per month.

Start your Codespace here:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/orchestron-orchestrator/respnet/tree/notconf?quickstart=1&devcontainer_path=.devcontainer%2Fdocker-in-docker%2Fdevcontainer.json)

Setting up a fresh VM will take a couple of minutes. After is it done you have
access to VS Code running in Dev Container with all the tools and source code
available in your browser. There is no need to clone the project repository,
just follow the Getting started guide.
