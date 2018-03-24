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
    ) onlyOwner public returns(address)
    {
        require(_artistAddress != address(0));
        Token token = new Token(_name, _symbol);

        Crowdsale sale = new Crowdsale(wallet, token);

        token.mint(_artistAddress, _artistAllocation);
        token.mint(FounderAddress, _hcrAllocation);

        icos[_artistAddress] = ArtistICO(address(sale), address(token), 0);
        artistIndex[icoCount] = _artistAddress;
        icoCount++;
        
        emit TokenIssue(_artistAddress, address(sale),  address(token));

        return icos[_artistAddress].crowdsale;
    }

    function setStage(address _artist, uint _openingTime, uint _closingTime, uint256 _amount, uint _usdPrice) onlyOwner public {
        require(_amount > 0 && _usdPrice > 0);
        require(icos[_artist].crowdsale != address(0));

        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        Token token = Token(icos[_artist].token);
        token.mint(icos[_artist].crowdsale, _amount * 1 ether);
        uint rate = ethusd / _usdPrice;
        sale.stage(_openingTime, _closingTime, rate);

        icos[_artist].price = _usdPrice;
    }

    function updateCrowdsaleTime(address _artist, uint _openingTime, uint _closingTime) onlyOwner public {
        require(icos[_artist].crowdsale != address(0));
        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        sale.updateTime(_openingTime, _closingTime);
    }

    function allocate(address _artist, address _to, uint _amount) onlyOwner public {
        require(icos[_artist].crowdsale != address(0));
        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        sale.allocate(_to, _amount * 1 ether);
    }

    function setPrice(address _artist, uint256 _usdPrice) onlyOwner public {
        require(icos[_artist].crowdsale != address(0));
        Crowdsale sale = Crowdsale(icos[_artist].crowdsale);
        uint rate = ethusd / _usdPrice;
        sale.setRate(rate);
        icos[_artist].price = _usdPrice;
    }
    
    function setPriceUpdateFreq(uint _freq) onlyOwner public {
        updatePriceFreq = _freq;
    }

    function enablePriceUpdate(bool _updatePriceEnabled) onlyOwner public {
        updatePriceEnabled = _updatePriceEnabled;
    }

    function getCrowdsale(address _artist) view public returns (address) {
        return icos[_artist].crowdsale;
    }

    function getToken(address _artist) view public returns (address) {
        return icos[_artist].token;
    }

    function __callback(bytes32 myid, string result) {
        require(msg.sender == oraclize_cbAddress());
        ethusd = parseInt(result, 2);
        _updateICOPrice();
        updatePrice();
    }

    function updatePrice() public payable {
        if (updatePriceEnabled) {
            oraclize_query(updatePriceFreq, "URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice&apikey=YourApiKeyToken).result.ethusd");
        }
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------
    function _updateICOPrice() internal {
        for (uint i = 0; i < icoCount; i++) {
            if (icos[artistIndex[i]].price > 0) {
                Crowdsale sale = Crowdsale(icos[artistIndex[i]].crowdsale);
                sale.setRate(ethusd / icos[artistIndex[i]].price);
            }
        }
    }
}