/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('dotenv').config()
require('@nomiclabs/hardhat-ethers')
require('@openzeppelin/hardhat-upgrades')

const {API_URL, PRIVATE_KEY, MF_API_URL, MF_PRIVATE_KEY, MOONBEAM_MOONSCAN_API_KEY} = process.env

module.exports = {
    solidity: '0.8.7',
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {},
        moonbase: {
            url: API_URL,
            accounts: [`0x${PRIVATE_KEY}`],
        },
        moonbeam: {
            url: MF_API_URL,
            accounts: [`0x${MF_PRIVATE_KEY}`],
        },
    },
    etherscan: {
        apiKey: {
            moonbeam: MOONBEAM_MOONSCAN_API_KEY,
            moonbaseAlpha: MOONBEAM_MOONSCAN_API_KEY,
        }
    },
    mocha: {
        timeout: 40000
    }
}
