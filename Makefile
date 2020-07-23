SHELL=/usr/bin/env bash


###########################
## UPDATE YOUR DATA HERE ##
# Don't put the MNEM here, add that by command line only.
DATA_PATH = ~/libra/my_configs/
# TODO: namespace and account will be the same data. Testing with human readable names.
NAME = lucas
ACC = 5e7891b719c305941e62867ffe730f48
IP = 104.131.20.59

###########################

compile : all-bins

# pipelines for genesis ceremony
register: init mining keys register
# > make register MNEM='owner city siege lamp code utility humor inherit plug tuna orchard lion various hill arrow hold venture biology aisle talent desert expand nose city' NAME=lucas ACC=5e7891b719c305941e62867ffe730f48 IP=104.131.20.59
genesis: build-genesis waypoint toml


# Add other binaries later.
install:
	cp -f target/release/ol_miner /usr/local/bin/ol_miner
	cp -f target/release/libra-management /usr/local/bin/libra-management

all-bins:
	cargo build --all --bins --release --exclude cluster-test

deps:
	sudo apt-get update
	sudo apt-get install build-essential cmake clang llvm libgmp-dev

#GENESIS CEREMONY
init:
	cargo run -p libra-management initialize \
	--mnemonic '${MNEM}' \
	--path=${DATA_PATH} \
	--namespace=${NAME}

mining:
	cargo run -p libra-management mining \
	--path-to-genesis-pow ${DATA_PATH}/block_0.json \
	--backend 'backend=github;owner=OLSF;repository=test-genesis;token=${DATA_PATH}/github_token.txt;namespace=${NAME}'

keys:
	cargo run -p libra-management operator-key \
	--local 'backend=disk;path=${DATA_PATH}/key_store.json;namespace=${NAME}' \
	--remote 'backend=github;owner=OLSF;repository=test-genesis;token=${DATA_PATH}/github_token.txt;namespace=${NAME}'

register:
	cargo run -p libra-management validator-config \
	--owner-address ${ACC} \
	--validator-address "/ip4/${IP}/tcp/6180" \
	--fullnode-address "/ip4/${IP}/tcp/6179" \
	--local 'backend=disk;path=${DATA_PATH}/key_store.json;namespace=${NAME}' \
	--remote 'backend=github;owner=OLSF;repository=test-genesis;token=${DATA_PATH}/github_token.txt;namespace=${NAME}'

build-genesis:
	cargo run -p libra-management genesis \
	--backend 'backend=github;owner=OLSF;repository=test-genesis;token=${DATA_PATH}/github_token.txt' \
	--path ${DATA_PATH}/genesis.blob

waypoint:
	cargo run -p libra-management create-waypoint \
	--remote 'backend=github;owner=OLSF;repository=test-genesis;token=${DATA_PATH}/github_token.txt;namespace=common' \
	--local 'backend=disk;path=${DATA_PATH}/key_store.json;namespace=${NAME}'

toml:
	cargo run -p libra-management config \
	--validator-address \
	"/ip4/${IP}/tcp/6180" \
	--validator-listen-address "/ip4/0.0.0.0/tcp/6180" \
	--backend 'backend=disk;path=${DATA_PATH}/key_store.json;namespace=${NAME}' \
	--fullnode-address "/ip4/${IP}/tcp/6179" \
	--fullnode-listen-address "/ip4/0.0.0.0/tcp/6179"

start:
	cargo run -p libra-node -- --config ${DATA_PATH}/node.configs.toml