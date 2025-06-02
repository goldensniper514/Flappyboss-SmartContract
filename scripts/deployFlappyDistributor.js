const quais = require('quais')
const FlappyJson = require('../artifacts/contracts/FlappyDistributor.sol/FlappyDistributor.json')
const { deployMetadata } = require('hardhat')
require('dotenv').config()

// Pull contract arguments from .env
const tokenArgs = [process.env.BOSS_TOKEN]

async function deployFlappyDistributor() {
  const provider = new quais.JsonRpcProvider(hre.network.config.url, undefined, { usePathing: true })
  const wallet = new quais.Wallet(hre.network.config.accounts[0], provider)
  const ipfsHash = await deployMetadata.pushMetadataToIPFS('FlappyDistributor')

  const FlappyFactory = new quais.ContractFactory(FlappyJson.abi, FlappyJson.bytecode, wallet, ipfsHash)

  const distributor = await FlappyFactory.deploy(...tokenArgs)
  console.log('Transaction broadcasted:', distributor.deploymentTransaction().hash)

  await distributor.waitForDeployment()
  console.log('Contract deployed to:', await distributor.getAddress())
}

deployFlappyDistributor()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
