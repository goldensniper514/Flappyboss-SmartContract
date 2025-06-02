const quais = require('quais')
const FlappyJson = require('../artifacts/contracts/FlappyStaking.sol/FlappyStaking.json')
const { deployMetadata } = require('hardhat')
require('dotenv').config()

// Pull contract arguments from .env
const tokenArgs = [process.env.BOSS_TOKEN, process.env.FEE_WALLET]

async function deployFlappyStaking() {
  const provider = new quais.JsonRpcProvider(hre.network.config.url, undefined, { usePathing: true })
  const wallet = new quais.Wallet(hre.network.config.accounts[0], provider)
  const ipfsHash = await deployMetadata.pushMetadataToIPFS('FlappyStaking')

  const FlappyFactory = new quais.ContractFactory(FlappyJson.abi, FlappyJson.bytecode, wallet, ipfsHash)

  const staking = await FlappyFactory.deploy(...tokenArgs)
  console.log('Transaction broadcasted:', staking.deploymentTransaction().hash)

  await staking.waitForDeployment()
  console.log('Contract deployed to:', await staking.getAddress())
}

deployFlappyStaking()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
