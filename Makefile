#Load the environment variable
-include .env

.PHONY: all test deploy
#tells out Makefile,Hey now these are the targets

#These are the targets

build :; forge build

test :; forge test

install :; forge install Cyfrin/foundry-devops --no-commit && forge install smartcontractkit/chainlink-brownie-contracts --no-commit && forge install foundry-rs/forge-std@v1.8.2 --nocommit forge install transmissions11/solmate --no-commit

#keystore password private
deploy-sepolia :
	@forge script script/Raffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account defaultkey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
