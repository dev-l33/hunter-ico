pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./oraclizeAPI_0.5.sol";

contract Manager is Ownable, usingOraclize {

  // whitelisted addresses
  mapping(address => bool) whitelist;

  // USD ETH rate 1 eth = x USD ether
  uint public ethusd = 53761;
  
  // Price update frequency.
  uint public updatePriceFreq = 6 hours;
  // on/off price update
  bool updatePriceEnabled = true;

  /**
  * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
  */
  function isWhitelisted(address _beneficiary) external view returns (bool) {
    return whitelist[_beneficiary];
  }

  /**
  * @dev Adds single address to whitelist.
  * @param _beneficiary Address to be added to the whitelist
  */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
  * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
  * @param _beneficiaries Addresses to be added to the whitelist
  */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
  * @dev Removes single address from whitelist.
  * @param _beneficiary Address to be removed to the whitelist
  */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function enablePriceUpdate(bool _updatePriceEnabled) onlyOwner external {
    updatePriceEnabled = _updatePriceEnabled;
  }
  function __callback(bytes32 myid, string result) public {
    require(msg.sender == oraclize_cbAddress());
    ethusd = parseInt(result, 2);
    updatePrice();
  }

  function updatePrice() public payable {
    if (updatePriceEnabled) {
      oraclize_query(updatePriceFreq, "URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice&apikey=YourApiKeyToken).result.ethusd");
    }
  }
}