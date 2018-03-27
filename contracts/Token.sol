pragma solidity ^0.4.21;


import "./ERC20Basic.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ManagerInterface.sol";

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract Token is ERC20Basic, Ownable {
    using SafeMath for uint256;

    // Manager contract
    ManagerInterface public manager;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    event Mint(address indexed to, uint256 amount);

    /**
    * @dev Constructor
    */
    function Token (string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
        manager = ManagerInterface(msg.sender);
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(manager.isWhitelisted(_to));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
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
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}
