// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TicketMarket {
    uint public nextTicketId;
    uint public nextEventId;

    struct Event {
        uint id;
        string name;
        string description;
        uint date;
    }

    struct TicketType {
        string name;
        string description;
        uint price;
    }
    
    struct Ticket {
        uint id;
        address owner;
        uint eventId;
        TicketType ticketType;
    }

    mapping(uint => Ticket) public tickets;
    mapping(uint => Event) public events;
    mapping(address => uint[]) public ownedTickets;
    mapping(uint => uint[]) public ticketsForEvent;

    event TicketCreated(uint ticketId, uint eventId, uint price);
    event TicketTransferred(uint ticketId, address from, address to, uint price);
    event TicketPriceUpdated(uint ticketId, uint price);

    constructor() {
        nextTicketId = 1;
        nextEventId = 1;
    }

    function createEvent(string memory name, string memory description, uint date) public {
        uint eventId = nextEventId++;
        events[eventId] = Event(eventId, name, description, date);
    }

    function createTicketsForEvent(uint eventId, uint price, uint quantity) public {
        require(events[eventId].date != 0, "Event does not exist.");
        require(price > 0, "Price must be greater than zero.");
        for (uint i = 0; i < quantity; i++) {
            uint ticketId = nextTicketId++;
            tickets[ticketId] = Ticket(ticketId, msg.sender, price, eventId);
            ticketsForEvent[eventId].push(ticketId);
            emit TicketCreated(ticketId, eventId, price);
        }
    }

    function buyFirstAvailableTicket(uint eventId) public payable {
        require(ticketsForEvent[eventId].length > 0, "No tickets available for this event.");
        uint ticketId = ticketsForEvent[eventId][0]; // Get the first ticket available
        require(tickets[ticketId].price <= msg.value, "Not enough ether sent.");
        require(tickets[ticketId].owner != msg.sender, "You cannot buy your own ticket.");

        address seller = tickets[ticketId].owner;
        payable(seller).transfer(msg.value);
        tickets[ticketId].owner = msg.sender;

        // Update the ticketsForEvent mapping
        removeFirstTicket(eventId);

        emit TicketTransferred(ticketId, seller, msg.sender, tickets[ticketId].price);
    }

    function removeFirstTicket(uint eventId) private {
        require(ticketsForEvent[eventId].length > 0, "No tickets to remove.");
        ticketsForEvent[eventId][0] = ticketsForEvent[eventId][ticketsForEvent[eventId].length - 1];
        ticketsForEvent[eventId].pop();
    }

    function setTicketPrice(uint ticketId, uint price) public {
        require(tickets[ticketId].owner == msg.sender, "You are not the owner.");
        require(price > 0, "Price must be greater than zero.");

        tickets[ticketId].price = price;
        emit TicketPriceUpdated(ticketId, price);
    }
}
