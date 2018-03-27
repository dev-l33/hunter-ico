pragma solidity ^0.4.21;

import "./Token.sol";
import "./Crowdsale.sol";
import "./oraclizeAPI_0.5.sol";

contract Manager is Ownable, usingOraclize {

    struct ArtistICO {
        address crowdsale;
        address token;
        uint price; // USD price i.e, 1 token = 70 ($0.7)
    }

    // whitelisted addresses
    mapping(address => bool) whitelist;

    // USD ETH rate 1 eth = x USD ether
    uint public ethusd = 53761;
    
    // Price update frequency.
    uint public updatePriceFreq = 6 hours;
    // on/off price update
    bool updatePriceEnabled = true;

    mapping (address => ArtistICO) public icos;
    mapping (uint => address) public artistIndex;
    uint public icoCount;

    /// address of hunter coporation
    address FounderAddress;

    /// address of wallet for funds
    address wallet;

    event TokenIssue(address indexed artist, address indexed crowdsale, address indexed token);

    function Manager(address _wallet, address _hcrAddress) public {
        require(_wallet != address(0) && _hcrAddress != address(0));
        wallet = _wallet;
        FounderAddress = _hcrAddress;
        whitelist[FounderAddress] = true;
    }

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

    /*
    * create new token and return address
    * @return address address of token
    */
    function createToken(
        address _artistAddress,
        string _name,
        string _symbol,
        uint256 _hcrAllocation,
        uint256 _artistAllocation
    ) onlyOwner external returns(address)
    {
        require(_artistAddress != address(0));
        Token token = new Token(_name, _symbol);

        Crowdsale sale = new Crowdsale(wallet, token);

        token.mint(_artistAddress, _artistAllocation);
        token.mint(FounderAddress, _hcrAllocation);

        icos[_artistAddress] = ArtistICO(address(sale), address(token), 0);
        artistIndex[icoCount] = _artistAddress;
        icoCount++;

        whitelist[sale] = true;
        
        emit TokenIssue(_artistAddress, address(sale),  address(token));

        return icos[_artistAddress].crowdsale;
    }

    function setStage(address _artist, uint _openingTime, uint _closingTime, uint256 _amount, uint _usdPrice) onlyOwner external {
        require(_amount > 0 && _usdPrice > 0);
        require(icos[_artist].crowdsale != address(0));

        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        Token token = Token(icos[_artist].token);
        token.mint(icos[_artist].crowdsale, _amount * 1 ether);
        sale.stage(_openingTime, _closingTime, _usdPrice);

        icos[_artist].price = _usdPrice;
    }

    function updateCrowdsaleTime(address _artist, uint _openingTime, uint _closingTime) onlyOwner external {
        require(icos[_artist].crowdsale != address(0));
        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        sale.updateTime(_openingTime, _closingTime);
    }

    function allocate(address _artist, address _to, uint _amount) onlyOwner external {
        require(icos[_artist].crowdsale != address(0));
        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        sale.allocate(_to, _amount * 1 ether);
    }

    function setPrice(address _artist, uint256 _usdPrice) onlyOwner external {
        require(icos[_artist].crowdsale != address(0));
        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        sale.setPrice(_usdPrice);
        icos[_artist].price = _usdPrice;
    }
    
    function setPriceUpdateFreq(uint _freq) onlyOwner external {
        updatePriceFreq = _freq;
    }

    function enablePriceUpdate(bool _updatePriceEnabled) onlyOwner external {
        updatePriceEnabled = _updatePriceEnabled;
    }

    function getCrowdsale(address _artist) view external returns (address) {
        return icos[_artist].crowdsale;
    }

    function getToken(address _artist) view external returns (address) {
        return icos[_artist].token;
    }

    function __callback(bytes32 myid, string result) {
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