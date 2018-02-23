pragma solidity ^0.4.18;

import './BasicToken.sol';
import './Ownable.sol';

contract Token is BasicToken, Ownable {

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    event Mint(address indexed to, uint256 amount);

    function Token (string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
}