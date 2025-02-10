// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }

    address public owner;
    address public ERC20Address;
    TicketNFT public nftContract;
    uint128 public currentEventId;
    mapping(uint128 => Event) public events;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }

    constructor(address _ERC20Address) {
        owner = msg.sender;
        ERC20Address = _ERC20Address;
        nftContract = new TicketNFT();
        currentEventId = 0;
    }

    function createEvent(
        uint128 maxTickets,
        uint256 pricePerTicket,
        uint256 pricePerTicketERC20
    ) external onlyOwner {
        events[currentEventId] = Event({
            nextTicketToSell: 0,
            maxTickets: maxTickets,
            pricePerTicket: pricePerTicket,
            pricePerTicketERC20: pricePerTicketERC20
        });
        emit EventCreated(
            currentEventId,
            maxTickets,
            pricePerTicket,
            pricePerTicketERC20
        );
        currentEventId++;
    }

    function setMaxTicketsForEvent(
        uint128 eventId,
        uint128 newMaxTickets
    ) external onlyOwner {
        require(
            events[eventId].maxTickets < newMaxTickets,
            "The new number of max tickets is too small!"
        );
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(
        uint128 eventId,
        uint256 price
    ) external onlyOwner {
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(
        uint128 eventId,
        uint256 price
    ) external onlyOwner {
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) external payable {
        // multiplication overflow
        (bool success, uint256 totalPrice) = Math.tryMul(
            events[eventId].pricePerTicket,
            ticketCount
        );
        require(
            success,
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets."
        );

        // no enough funds
        require(
            totalPrice <= msg.value,
            "Not enough funds supplied to buy the specified number of tickets."
        );

        // no enough tickets
        require(
            events[eventId].nextTicketToSell + ticketCount <
                events[eventId].maxTickets,
            "We don't have that many tickets left to sell!"
        );

        for (uint128 i = 0; i < ticketCount; ++i) {
            uint256 nftId = (uint256(eventId) << 128) +
                events[eventId].nextTicketToSell;
            events[eventId].nextTicketToSell++;
            nftContract.mintFromMarketPlace(msg.sender, nftId);
        }

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        // multiplication overflow
        (bool success, uint256 totalPrice) = Math.tryMul(
            events[eventId].pricePerTicketERC20,
            ticketCount
        );
        require(
            success,
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets."
        );


        // no enough funds
        require(
            IERC20(ERC20Address).transferFrom(
                msg.sender,
                address(this),
                totalPrice 
            ),
            "Not enough funds supplied to buy the specified number of tickets."
        );

        // no enough tickets
        require(
            events[eventId].nextTicketToSell + ticketCount <
                events[eventId].maxTickets,
            "We don't have that many tickets left to sell!"
        );

        for (uint128 i = 0; i < ticketCount; ++i) {
            uint256 nftId = (uint256(eventId) << 128) +
                events[eventId].nextTicketToSell;
            events[eventId].nextTicketToSell++;
            nftContract.mintFromMarketPlace(msg.sender, nftId);
        }

        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external onlyOwner {
        ERC20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }
}
