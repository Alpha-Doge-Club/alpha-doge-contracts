const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ethers = require('ethers');

const MockERC20 = artifacts.require('MockERC20');
const Pool = artifacts.require('Pool');

const decToHex = (x, decimal=18) => {
    if (x == 0) return '0x0';
    let str = x;
    for (var index = 0; index < decimal; index++) {
      str += "0";
    }

    let pos = str.indexOf(".");
    if (pos != -1) {
      str = str.substr(0, pos) + str.substr(pos + 1, decimal);
    }

    var dec = str.toString().split(''), sum = [], hex = [], i, s
    while (dec.length) {
      s = 1 * parseInt(dec.shift())
      for (i = 0; s || i < sum.length; i++) {
        s += (sum[i] || 0) * 10
        sum[i] = s % 16
        s = (s - sum[i]) / 16
      }
    }

    while (sum.length) {
      hex.push(sum.pop().toString(16));
    }

    return '0x' + hex.join('');
}

contract('Pool', ([owner, trader0, investor0, investor1, anyone]) => {

    beforeEach(async () => {
        this.DAI = await MockERC20.new(
            "DAI", "DAI", decToHex(5000), {from: owner});
        await this.DAI.transfer(trader0, decToHex(2000), {from: owner});
        await this.DAI.transfer(investor0, decToHex(2000), {from: owner});
        await this.DAI.transfer(investor1, decToHex(1000), {from: owner});

        this.Pool = await Pool.new({from: owner});
        await this.Pool.initialize(this.DAI.address, true, {from: owner});

        // Defines minimum floating-point calculation error.
        this.MIN_ERROR = 0.0001e18; // 0.0001 USDC
    });

    it('should work', async () => {
        // trader0 creates the club called 'ABC Club'.
        await this.Pool.createPool(27, 1, 2, 'ABC Club', {from: trader0});

        // trader0 deposits 2000, and investor0 deposits 1000.
        await this.DAI.approve(this.Pool.address, decToHex(2000), {from: trader0});
        await this.Pool.deposit(0, decToHex(2000), {from: trader0});
        await this.DAI.approve(this.Pool.address, decToHex(1000), {from: investor0});
        await this.Pool.deposit(0, decToHex(1000), {from: investor0});

        // trader0 starts the pool. Now the fund is in operation.
        await this.Pool.startPool({from: trader0});

        // Moves forward by 4 days.
        await this.Pool.setTimeExtra(3600 * 24 * 4);

        // Deposit should fail, but withdraw should work.
        await this.DAI.approve(this.Pool.address, decToHex(1000), {from: investor1});
        await expectRevert(
            this.Pool.deposit(0, decToHex(1000), {from: investor1}),
            "Should be in window"
        );

        const investor0Info = await this.Pool.userInfoMap(0, investor0, {from: anyone});
        const investor0Shares = +investor0Info.share.valueOf();
        const halfOfShares = Math.floor(investor0Shares / 2);
        await this.Pool.withdraw(0, decToHex(halfOfShares / 1e18), {from: investor0});

        // Move forward to the 27th day (come to the gap).
        await this.Pool.setTimeExtra(3600 * 24 * 27);

        // withdraw should fail now.
        await expectRevert(
            this.Pool.withdraw(0, decToHex(halfOfShares / 1e18), {from: investor0}),
            "Should be before gap"
        );
    });
});
