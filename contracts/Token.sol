pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/BasicToken.sol';
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Token is BasicToken, Ownable {

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    // how many token units a buyer gets per wei
    uint256 public rate;

    /// Maximum tokens to be sold
    uint256 public tokenSaleHardCap;

    /// amount of raised money in wei
    uint256 public amountRaised;

    /// addresses
    address public wallet;

    /// Crowdsale Stages
    uint256 public saleStageDate1;
    uint256 public saleStageDate2;
    uint256 public saleStageDate3;
    uint256 public saleStageDate4;
    uint256 public saleStageDateEnd;

    uint public saleStageBonus1;
    uint public saleStageBonus2;
    uint public saleStageBonus3;
    uint public saleStageBonus4;

    /// List of Affiliates user address
    mapping (address => bool) public affiliates;
    mapping (address => bool) public reviewers;

    event Mint(address indexed to, uint256 amount);

    function Token (
        string _name,
        string _symbol,
        uint256 _tokenSaleHardCap,
        uint256 _rate,
        address _wallet,
        uint256 _saleStartDate,
        uint _saleStageBonus1,
        uint _saleStageBonus2,
        uint _saleStageBonus3,
        uint _saleStageBonus4
    ) public
    {
        require(_wallet != address(0));
        require(_rate > 0);
        require(_tokenSaleHardCap > 0);

        name = _name;
        symbol = _symbol;
        tokenSaleHardCap = _tokenSaleHardCap * 1 ether;
        rate = _rate;
        wallet = _wallet;

        saleStageDate1 = _saleStartDate;
        saleStageDate2 = _saleStartDate + 15 days;
        saleStageDate3 = saleStageDate2 + 15 days;
        saleStageDate4 = saleStageDate3 + 15 days;
        saleStageDateEnd = saleStageDate4 + 15 days;

        saleStageBonus1 = _saleStageBonus1;
        saleStageBonus2 = _saleStageBonus2;
        saleStageBonus3 = _saleStageBonus3;
        saleStageBonus4 = _saleStageBonus4;
    }

    // low level token purchase function
    function () payable public {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        // calculate bonus for current stage
        uint256 bonus = getBonusAmount(msg.sender, tokens);

        // update state
        balances[msg.sender] += tokens + bonus;
        amountRaised += weiAmount;
        totalSupply_ += tokens + bonus;
        forwardFunds();
        Transfer(this, msg.sender, tokens + bonus);
    }

    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        uint256 tokens = weiAmount * rate;
        return tokens;
    }

    function getBonusAmount(address beneficiary, uint256 tokenAmount) internal view returns(uint256) {
        // send bonus for each ICO Stage
        uint256 bonus;
        if (now >= saleStageDate1 && now < saleStageDate2) {
            bonus = tokenAmount * saleStageBonus1 / 100;

            // calculate reviewer's bonus
            if (reviewers[beneficiary]) {
                bonus += tokenAmount; // 100% discount for reviewers at Stage1
            }
        } else if (now >= saleStageDate2 && now < saleStageDate3) {
            bonus = tokenAmount * saleStageBonus2 / 100;
        } else if (now >= saleStageDate3 && now < saleStageDate4) {
            bonus = tokenAmount * saleStageBonus3 / 100;
        } else if (now >= saleStageDate4 && now < saleStageDateEnd) {
            bonus = tokenAmount * saleStageBonus4 / 100;
        }

        // calculate bonus for Affiliates
        if (affiliates[beneficiary]) {
            bonus += tokenAmount / 10; // 10% discount for affiliates
        }

        return bonus;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ += _amount;
        balances[_to] += _amount;
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

   /**
    * @dev Function to register affiliates
    * @param _affiliate The address of affiliate user
    */
    function addAffiliate(address _affiliate) onlyOwner public {
        require(_affiliate != address(0));
        affiliates[_affiliate] = true;
    }

   /**
    * @dev Function to register reviewers
    * @param _reviewer The address of affiliate user
    */
    function addReviewer(address _reviewer) onlyOwner public {
        require(_reviewer != address(0));
        reviewers[_reviewer] = true;
    }

    /**
    * @dev Function to remove affiliates
    * @param _affiliate The address of affiliate user
    */
    function removeAffiliate(address _affiliate) onlyOwner public {
        require(_affiliate != address(0));
        affiliates[_affiliate] = false;
    }

   /**
    * @dev Function to remove reviewers
    * @param _reviewer The address of affiliate user
    */
    function removeReviewer(address _reviewer) onlyOwner public {
        require(_reviewer != address(0));
        reviewers[_reviewer] = false;
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= saleStageDate1 && now <= saleStageDateEnd;
        bool nonZeroPurchase = msg.value != 0;
        bool overCap = (totalSupply_ + getTokenAmount(msg.value)) <= tokenSaleHardCap;
        return withinPeriod && nonZeroPurchase && overCap;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /// @notice Allow users to buy tokens for `newRate` eth
    /// @param newRate rate the users can sell to the contract
    function setRate(uint256 newRate) onlyOwner public {
        rate = newRate;
    }
}