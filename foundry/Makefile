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

coverage :; forge coverage --report debug > coverage.txt

deploy CrossChainNFT on optimism:
	@forge script script/DeployCrossChainNFT.s.sol:DeployCrossChainNFT --rpc-url $(OP_GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(OP_ETHERSCAN_API_KEY) -vvvv

deploy CrossChainNFT on base:
	@forge script script/DeployCrossChainNFT.s.sol:DeployCrossChainNFT --rpc-url $(BASE_GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(BASE_ETHERSCAN_API_KEY) -vvvv

deploy CrossChainNFT on zora:
	@forge script script/DeployCrossChainNFT.s.sol:DeployCrossChainNFT --rpc-url $(ZORA_GOERLI_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout --verifier-url https://testnet.explorer.zora.energy/api\? -vvvv
