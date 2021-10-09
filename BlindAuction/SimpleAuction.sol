// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;
    bool ended;
 
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();

    constructor(uint biddingTime, address payable beneficiacryAddress) {
        beneficiary = beneficiacryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    // Bid on the auction with the value sent together with this transaction.
    function bid() external payable {
        if (block.timestamp > auctionEndTime) {revert AuctionAlreadyEnded();}
        if (msg.value <= highestBid) {revert BidNotHighEnough(highestBid);}
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // Withdraw a bid that was overbid.
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient can call this function 
            // again as part of the receiving call before `send` returns.
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // End the auction and send the highest bid.
    function auctionEnd() external {
        // 1. Conditions
        if (block.timestamp < auctionEndTime) {revert AuctionNotYetEnded();}
        if (ended) {revert AuctionAlreadyEnded();}

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}