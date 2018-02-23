var manager = artifacts.require("Manager");
var token = artifacts.require("Token");

module.exports = function(deployer) {
    deployer.deploy(manager, "0xf17f52151EbEF6C7334FAD080c5704D77216b732", "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef");

    // deployer.deploy(token,
    //     "TestCoin",
    //     "TST",
    //     500000000,
    //     100,
    //     "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef",
    //     1518451520,
    //     20,
    //     10,
    //     5,
    //     1
    // );
};