pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./ManagerInterface.sol";

interface ERC20Interface {
  function transfer(address receiver, uint amount) external returns (bool);
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override 
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */

contract Crowdsale is Ownable {

  // Manager contract
  ManagerInterface public manager;

  // The token being sold
  ERC20Interface public token;

  // Address where funds are collected
  address public wallet;

  // USD price per token
  uint public price;

  // Amount of wei raised
  uint256 public weiRaised;
  // Amount of token sold
  uint256 public tokenSold;

  // Amount of wei raised before start current stage
  uint256 public weiRaisedInPrevStage;
  // Amount of token sold before start current stage
  uint256 public tokenSoldInPrevStage;

  // Stage information
  uint public openingTime;
  uint public closingTime;
  uint8 public stageNum;

  /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
    * Event for token allocate logging
    * @param beneficiary who got the tokens
    * @param amount amount of tokens allocated
    */
  event TokenAllocate(address indexed beneficiary, uint256 amount);

  /**
    * Contructor
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
  constructor(address _wallet, address _token, address _manager) public {
    require(_wallet != address(0));
    require(_token != address(0));
    require(_manager != address(0));

    wallet = _wallet;
    token = ERC20Interface(_token);
    
    manager = ManagerInterface(_manager);
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
  function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    _processPurchase(_beneficiary, tokens);

    // update state
    weiRaised += weiAmount;

    _forwardFunds();

    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
  }

  function stage(uint _openingTime, uint _closingTime, uint _price) onlyOwner external returns(uint8) {
    require(_price > 0 && _closingTime > now);
    openingTime = _openingTime;
    closingTime = _closingTime;
    price = _price;
    stageNum++;
    weiRaisedInPrevStage = weiRaised;
    tokenSoldInPrevStage = tokenSold;
    return stageNum;
  }

  function allocate(address _to, uint _amount) onlyOwner external {
    _processPurchase(_to, _amount);

    emit TokenAllocate(_to, _amount);
  }

  /* 
   * @dev Allow users to buy tokens for `_price` USD
   * @param _price price the users can sell to the contract
   */
  function setPrice(uint256 _price) onlyOwner external {
    require(_price > 0);
    price = _price;
  }

  /* 
   * @dev Update manager contract address
   * @param _manager address of new manager contract
   */
  function setManager(address _manager) onlyOwner external {
    require(_manager != address(0));
    manager = ManagerInterface(_manager);
  }

  function updateTime(uint _openingTime, uint _closingTime) onlyOwner external {
    require(_closingTime > now);
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
    * @dev Function to get wei raised in current stage
    * @return uint wei Raised in current stage
    */
  function weiRaisedInCurrentStage() view public returns(uint) {
    return weiRaised - weiRaisedInPrevStage;
  }

  /**
    * @dev Function to get wei raised in current stage
    * @return uint wei Raised in current stage
    */
  function tokenSoldInCurrentStage() view public returns(uint) {
    return tokenSold - tokenSoldInPrevStage;
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
    * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal {
    require(manager.isWhitelisted(_beneficiary));
    require(_weiAmount != 0);
    require(now >= openingTime && now < closingTime);
  }

  /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
    tokenSold += _tokenAmount;
  }

  /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
  function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
    return _weiAmount * manager.ethusd() / price;
  }

  /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}