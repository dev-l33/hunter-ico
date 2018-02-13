var manager = artifacts.require("Manager");
var token = artifacts.require("Token");

module.exports = function(deployer) {
    deployer.deploy(manager, "0x29206D36B147B00A4592D5D9154Ac32ab4830fB0", "0xe0014f07625ae3ef38050B28339b0203DDCdf045");

    deployer.deploy(token,
        "TestCoin",
        "TST",
        500000000,
        100,
        "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef",
        1518451520,
        20,
        10,
        5,
        1
    );
};