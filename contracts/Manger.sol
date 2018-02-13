pragma solidity ^0.4.18;

import "./Token.sol";

contract Manager is Ownable {

    struct ArtistToken {
        address artistAddress;
        address contractAddress;
    }

    uint8 constant public DECIMALS = 18;

    /// allocate 50 million tokens to the artist
    uint256 constant public ALLOCATION_ARTIST = 50000000 * 10 ** uint256(DECIMALS);
    
    /// allocate 50 million tokens to HCR
    uint256 constant public ALLOCATION_HCR = 50000000 * 10 ** uint256(DECIMALS);

    ArtistToken[] public tokens;

    /// address of hunter coporation
    address HCRAddress;

    /// address of wallet for funds
    address wallet;

    function Manager(address _wallet, address _hcrAddress) public {
        require(_wallet != address(0) && _hcrAddress != address(0));
        wallet = _wallet;
        HCRAddress = _hcrAddress;
    }

    /*
    * create new token and return address
    * @return address address of token
    */
    function createToken(
        address _artistAddress,
        string _name,
        string _symbol,
        uint256 _tokenSaleHardCap,
        uint256 _price,
        uint256 _saleStartDate,
        uint _saleStageBonus1,
        uint _saleStageBonus2,
        uint _saleStageBonus3,
        uint _saleStageBonus4
    ) onlyOwner public returns(address)
    {
        require(_artistAddress != address(0));
        Token token = new Token(_name, _symbol, _tokenSaleHardCap, _price, wallet, _saleStartDate, _saleStageBonus1, _saleStageBonus2, _saleStageBonus3, _saleStageBonus4);

        token.mint(_artistAddress, ALLOCATION_ARTIST);
        token.mint(HCRAddress, ALLOCATION_HCR);

        address tokenAddress = address(token);

        ArtistToken memory artistToken = ArtistToken(_artistAddress, tokenAddress);
        tokens.push(artistToken);

        return tokenAddress;
    }

    function countTokens() view public returns (uint) {
        return tokens.length;
    }

    function setRate(address _tokenAddress, uint256 _rate) public {
        require(_tokenAddress != address(0));
        Token token = Token(_tokenAddress);
        token.setRate(_rate);
    }

    function addAffiliate(address _tokenAddress, address _userAddress) onlyOwner public {
        require(_tokenAddress != address(0));
        Token token = Token(_tokenAddress);
        token.addAffiliate(_userAddress);
    }

    function addReviewer(address _tokenAddress, address _userAddress) onlyOwner public {
        require(_tokenAddress != address(0));
        Token token = Token(_tokenAddress);
        token.addReviewer(_userAddress);
    }

}
