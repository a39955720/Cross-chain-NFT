-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

coverage :; forge coverage --ir-minimum --report debug > coverage.txt

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(NETWORK),goerli)
	NETWORK_ARGS := --rpc-url $(GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(GOERLI_ETHERSCAN_API_KEY) -vvvv
else ifeq ($(NETWORK),optimism)
	NETWORK_ARGS := --rpc-url $(OP_GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(OP_ETHERSCAN_API_KEY) -vvvv
else ifeq ($(NETWORK),base)
	NETWORK_ARGS := --rpc-url $(BASE_GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(BASE_ETHERSCAN_API_KEY) -vvvv
else ifeq ($(NETWORK),zora)
	NETWORK_ARGS := --rpc-url $(ZORA_GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout --verifier-url https://testnet.explorer.zora.energy/api\? -vvvv
endif

# make CrossChainNFT NETWORK=<network>
CrossChainNFT:
	@forge script script/DeployCrossChainNFT.s.sol:DeployCrossChainNFT $(NETWORK_ARGS)

FromL1ControlL2:
	@forge script script/DeployFromL1ControlL2.s.sol:DeployFromL1ControlL2 $(NETWORK_ARGS)
