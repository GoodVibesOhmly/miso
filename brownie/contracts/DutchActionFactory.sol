pragma solidity 0.6.12;

import "./Auctions/DutchAuction.sol";

contract DutchAuctionFactory {
    function deployAuction() external returns (address) {
        return address(new DutchAuction());
    }
}
