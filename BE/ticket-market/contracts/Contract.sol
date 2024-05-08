// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TicketMarket {
    uint public nextTicketId;

    struct Event {
        string name;
        string description;
        uint date;
    }
    
    struct Ticket {
        address owner;
        uint price;
        string name;
        Event event_data;
    }

    mapping(uint => Ticket) public tickets;
    mapping(address => uint[]) public ownedTickets;

    event TicketCreated(uint ticketId, uint price);
    event TicketTransferred(uint ticketId, address from, address to, uint price);
    event TicketPriceUpdated(uint ticketId, uint price);

    constructor() {
        nextTicketId = 1;
    }

    function createTicket(uint price) public {
        require(price > 0, "Price must be greater than zero.");
        uint ticketId = nextTicketId++;
        tickets[ticketId].owner = msg.sender;
        tickets[ticketId].price = price;
        emit TicketCreated(ticketId, price);
    }

    // create multiple tickets for event

    function buyTicket(uint ticketId) public payable {
        require(tickets[ticketId].price > 0, "Ticket does not exist.");
        require(msg.value >= tickets[ticketId].price, "Not enough ether sent.");
        require(tickets[ticketId].owner != msg.sender, "You cannot buy your own ticket.");
        address seller = tickets[ticketId].owner;
        address buyer = msg.sender;
        uint price = tickets[ticketId].price;

        payable(seller).transfer(msg.value);
        tickets[ticketId].owner = buyer;

        emit TicketTransferred(ticketId, seller, buyer, price);
    }

    function setTicketPrice(uint ticketId, uint price) public {
        require(tickets[ticketId].owner == msg.sender, "You are not the owner.");
        require(price > 0, "Price must be greater than zero.");

        tickets[ticketId].price = price;
        emit TicketPriceUpdated(ticketId, price);
    }

    function getTicketOwner(uint ticketId) public view returns (address) {
        return tickets[ticketId].owner;
    }

    function getTicketPrice(uint ticketId) public view returns (uint) {
        return tickets[ticketId].price;
    }

    function getTicketsForEvent(string memory e) public view returns (uint[] memory) {
        uint count = 0;
        for (uint i = 1; i < nextTicketId; i++) {
            if (keccak256(abi.encodePacked(tickets[i].event_data.name)) == keccak256(abi.encodePacked(e))) {
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        count = 0;
        for (uint i = 1; i < nextTicketId; i++) {
            if (keccak256(abi.encodePacked(tickets[i].event_data.name)) == keccak256(abi.encodePacked(e))) {
                result[count++] = i;
            }
        }

        return result;
    }
}
