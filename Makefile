#Load the environment variable
-include .env

.PHONY: all test deploy
#tells out Makefile,Hey now these are the targets

#These are the targets

build :; forge build

test :; forge test

install :; forge install Cyfrin/foundry-devops --no-commit && forge install smartcontractkit/chainlink-brownie-contracts --no-commit && forge install foundry-rs/forge-std@v1.8.2 --nocommit forge install transmissions11/solmate --no-commit

deploy:
	@forge script script/Raffle.s.sol:DeployRaffle $(NETWORK_ARGS)

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# if --network sepolia is used, then use sepolia stuff, otherwise anvil stuff
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) --legacy -vvvvv
endif


createSubscription:;	forge script script/Interaction.s.sol:CreateSubscription --rpc-url $(SEPOLIA_RPC_URL) --account defaultKey --broadcast

#firstly replace the subscription id in helper config to fund the correct subscription
fundSubscription:;	forge script script/Interaction.s.sol:FundSubscription --rpc-url $(SEPOLIA_RPC_URL) --account defaultKey --broadcast
