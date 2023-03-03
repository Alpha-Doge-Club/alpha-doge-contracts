/*module.exports = function(deployer) {};*/

const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Pool = artifacts.require('Pool');

module.exports = async function (deployer) {
  await deployProxy(Pool, ['0x04B2A6E51272c82932ecaB31A5Ab5aC32AE168C3', false], { initializer: 'initialize' });
};
