pragma solidity ^0.4.21;

interface ManagerInterface {
    function ethusd() external view returns (uint);
    function isWhitelisted(address _beneficiary) external view returns (bool);
}