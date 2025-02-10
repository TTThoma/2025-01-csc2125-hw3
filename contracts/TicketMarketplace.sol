// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external;

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external;

    function setPriceForTicketETH(uint128 eventId, uint256 price) external;

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external;

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external;

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external;

    function setERC20Address(address newERC20Address) external;
}