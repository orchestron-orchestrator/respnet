# RESPNET

RESPNET, the REalistic Service Provider Network, is an example of network automation to automate a rather realistic looking SP network. This repository contains a RESPNET implementation POC based on Orchestron.


## Getting started
- You need Acton installed, most likely the tip release, see https://acton.guide/install_tip.html
- `git clone git@github.com:orchestron-orchestrator/respnet.git` (if you haven't already)
- `acton build`
- `cd test/quicklab`
- `make start`
- `make copy run`- this will copy over a fresh version of the orchestron/respnet app and run it in the container part of the quicklab dev environment

So typical REPL loop is like 
- edit code
- in test/quicklab: `(cd ../../ && acton build ) && make copy run` and see the code run interactively

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/orchestron-orchestrator/respnet/tree/notconf?quickstart=1&devcontainer_path=.devcontainer%2Fdocker-in-docker%2Fdevcontainer.json)