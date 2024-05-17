// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library StringLibrary {
    function compare(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

library TicketValidation{
    using StringLibrary for string;
    struct ResoldTicketsBulk {
        uint eventId;
        uint amountOnSale;
        uint amountNotOnSale;
        string ticketType;
        uint price;
        string description;
        address owner;
    }
    function validateOwnershipAndType(ResoldTicketsBulk storage ticket, string memory ticketType) internal view {
        require(ticket.ticketType.compare(ticketType), "Owner does not own the ticket.");
        require(!ticket.ticketType.compare(""), "Ticket type is unspecified.");
    }
}

contract TicketMarket {
    using TicketValidation for TicketValidation.ResoldTicketsBulk;
    enum TicketForSale { OnSale, NotOnSale }
    struct Event {
        uint id;
        string name;
        string description;
        uint dateStart;
        uint dateEnd;
        address creator;
    }

    struct TicketsBulk {
        uint eventId;
        uint amount;
        string ticketType;
        uint price;
        string description;
    }

    struct Set {
        string[] values;
        mapping (string => bool) is_in;
    }

    Set private ticketTypesSet;

    function addToSet(string memory a) private {
        if (!ticketTypesSet.is_in[a]) {
            ticketTypesSet.values.push(a);
            ticketTypesSet.is_in[a] = true;
        }
    }

    function resetSet() private {
        delete ticketTypesSet.values;
        for (uint i = 0; i < ticketTypesSet.values.length; i++) {
            delete ticketTypesSet.is_in[ticketTypesSet.values[i]];
        }
    }


    uint public nextEventId = 1;

    mapping(uint => Event) public events;
    mapping(uint => mapping(string => TicketsBulk)) public unsoldTicketsBulks;
    mapping(address => mapping(uint => mapping(string => TicketValidation.ResoldTicketsBulk))) public resoldTicketsBulks;

    mapping (uint => address[]) public eventToOwners;

    event EventCreated(uint eventId, string name, string description, uint date);
    event TicketBulkCreated(uint eventId, uint price, string ticketType);
    event TicketTransferred(uint eventId, string ticketType, address from, address to, uint price);
    event TicketPriceUpdated(uint eventId, string ticketType, uint price);
    event TicketOnSale(uint ticketId, string ticketType, uint price, bool isOnSale);
    event EventEdited(uint eventId, string name, string description, uint date);

    modifier ValidDate(uint dateStart, uint dateEnd) {
        require(dateStart > block.timestamp, "Event must start in the future.");
        require(dateEnd >= dateStart, "Event must end after it starts.");
        _;
    }

    modifier CheckBalanceAndWithdrawExceeded(uint amount) {
        require(msg.value >= amount, "Insufficient funds.");
        uint excess = msg.value - amount;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
        _;
    }

    function editTicketsBulk(uint eventId, string memory ticketType, uint price, uint amountOnSale) public {
        resoldTicketsBulks[msg.sender][eventId][ticketType].validateOwnershipAndType(ticketType);
        require(resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale + resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale > 0, "You own no tickets of this type.");
        require(price >= 0, "Price must be greater (or equal) than zero.");
        require(amountOnSale <= resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale + resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale, "Not enough tickets to put on sale.");

        resoldTicketsBulks[msg.sender][eventId][ticketType].price = price;
        uint prevAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale = amountOnSale;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale + prevAmountOnSale - amountOnSale;

        emit TicketPriceUpdated(eventId, ticketType, price);
    }

    function createEvent(string memory name, string memory description, uint dateStart, uint dateEnd, TicketsBulk[] memory availableTickets) public ValidDate(dateStart, dateEnd) {
        uint eventId = nextEventId++;
        events[eventId] = Event(eventId, name, description, dateStart, dateEnd, msg.sender);
        emit EventCreated(eventId, name, description, dateStart);
        for (uint i = 0; i < availableTickets.length; i++) {
            addToSet(availableTickets[i].ticketType);
            TicketsBulk memory tb = TicketsBulk(eventId, availableTickets[i].amount, availableTickets[i].ticketType, availableTickets[i].price, availableTickets[i].description);
            unsoldTicketsBulks[eventId][availableTickets[i].ticketType] = tb;
            emit TicketBulkCreated(eventId, availableTickets[i].price, availableTickets[i].ticketType);
        }
    }

    function deleteEvent(uint eventId) public {
        require(events[eventId].creator == msg.sender, "You are not the creator of this event.");
        for (uint i = 0; i < ticketTypesSet.values.length; i++) {
            delete unsoldTicketsBulks[eventId][ticketTypesSet.values[i]];
        }
        delete events[eventId];
    }

    function editEvent(uint eventId, string memory name, string memory description, uint dateStart, uint dateEnd, TicketsBulk[] memory availableTickets) public ValidDate(dateStart, dateEnd){
        require(events[eventId].creator == msg.sender, "You are not the creator of this event.");
        events[eventId].name = name;
        events[eventId].description = description;
        events[eventId].dateStart = dateStart;
        events[eventId].dateEnd = dateEnd;

        resetSet();
        for (uint i = 0; i < availableTickets.length; i++) {
            addToSet(availableTickets[i].ticketType);
            TicketsBulk memory tb = TicketsBulk(eventId, availableTickets[i].amount, availableTickets[i].ticketType, availableTickets[i].price, availableTickets[i].description);
            unsoldTicketsBulks[eventId][availableTickets[i].ticketType] = tb;
            emit TicketBulkCreated(eventId, availableTickets[i].price, availableTickets[i].ticketType);
        }
        emit EventEdited(eventId, name, description, dateStart);
    }

    function listEvents() public view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](nextEventId - 1);
        for (uint i = 1; i < nextEventId; i++) {
            allEvents[i - 1] = events[i];
        }
        return allEvents;
    }

    function listMyEvents() public view returns (Event[] memory) {
        uint count = 0;
        for (uint i = 1; i < nextEventId; i++) {
            if (events[i].creator == msg.sender) {
                count++;
            }
        }
        Event[] memory myEvents = new Event[](count);
        count = 0;
        for (uint i = 1; i < nextEventId; i++) {
            if (events[i].creator == msg.sender) {
                myEvents[count++] = events[i];
            }
        }
        return myEvents;
    }

    function getAvailableTicketsForEvent(uint eventId) public view returns (TicketsBulk[] memory) {
        require(events[eventId].dateStart > block.timestamp, "Event has already started");
        uint count = 0;
        for (uint i = 0; i < ticketTypesSet.values.length; i++) {
            if (unsoldTicketsBulks[eventId][ticketTypesSet.values[i]].amount > 0) {
                count++;
            }
        }
        TicketsBulk[] memory availableTickets = new TicketsBulk[](count);
        count = 0;
        for (uint i = 0; i < ticketTypesSet.values.length; i++) {
            if (unsoldTicketsBulks[eventId][ticketTypesSet.values[i]].amount > 0) {
                availableTickets[count++] = unsoldTicketsBulks[eventId][ticketTypesSet.values[i]];
            }
        }
        return availableTickets;
    }
    
    function getResoldTicketsForEvent(uint eventId) public view ValidDate(events[eventId].dateStart, events[eventId].dateEnd) returns (TicketValidation.ResoldTicketsBulk[] memory) {
        uint count = 0;
        for(uint i = 0; i < eventToOwners[eventId].length; i++) {
            for (uint j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]].amountOnSale > 0) {
                    count++;
                }
            }
        }
        TicketValidation.ResoldTicketsBulk[] memory resoldTickets = new TicketValidation.ResoldTicketsBulk[](count);
        count = 0;
        for(uint i = 0; i < eventToOwners[eventId].length; i++) {
            for (uint j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]].amountOnSale > 0) {
                    resoldTickets[count++] = resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]];
                }
            }
        }
        return resoldTickets;
    }

    function getTicketBulksForOwner() public view returns (TicketValidation.ResoldTicketsBulk[] memory) {
        uint count = 0;
        for (uint i = 0; i < nextEventId; i++) {
            for (uint j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountOnSale > 0 || resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountNotOnSale > 0) {
                    count++;
                }
            }
        }
        TicketValidation.ResoldTicketsBulk[] memory resoldTickets = new TicketValidation.ResoldTicketsBulk[](count);
        count = 0;
        for (uint i = 0; i < nextEventId; i++) {
            for (uint j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountOnSale > 0 || resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountNotOnSale > 0) {
                    resoldTickets[count++] = resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]];
                }
            }
        }
        return resoldTickets;
    }

    function buyNewTickets(uint eventId, string memory ticketType, uint amount) public payable ValidDate(events[eventId].dateStart, events[eventId].dateEnd) CheckBalanceAndWithdrawExceeded(unsoldTicketsBulks[eventId][ticketType].price * amount){
        require(events[eventId].creator != msg.sender, "You cannot buy tickets for your own event.");
        require(unsoldTicketsBulks[eventId][ticketType].amount > amount, "No more tickets available for this type.");
        unsoldTicketsBulks[eventId][ticketType].amount -= amount;
        address payable previousOwner = payable(events[eventId].creator);
        uint price = unsoldTicketsBulks[eventId][ticketType].price * amount;
        previousOwner.transfer(price);

        eventToOwners[eventId].push(msg.sender);

        uint currentAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        uint currentAmountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale;

        TicketValidation.ResoldTicketsBulk memory rtb = TicketValidation.ResoldTicketsBulk(eventId, currentAmountOnSale, amount + currentAmountNotOnSale, ticketType, 0, unsoldTicketsBulks[eventId][ticketType].description, msg.sender);
        resoldTicketsBulks[msg.sender][eventId][ticketType] = rtb;

        emit TicketTransferred(eventId, ticketType, previousOwner, msg.sender, price);
    }

    function buyResoldTickets(uint eventId, string memory ticketType, address payable owner, uint amount) public payable ValidDate(events[eventId].dateStart, events[eventId].dateEnd) CheckBalanceAndWithdrawExceeded(resoldTicketsBulks[owner][eventId][ticketType].price * amount){
        require(events[eventId].creator != msg.sender, "You cannot buy tickets for your own event.");
        resoldTicketsBulks[owner][eventId][ticketType].validateOwnershipAndType(ticketType);
        require(resoldTicketsBulks[owner][eventId][ticketType].amountOnSale > amount, "Not enough tickets on sale.");
        require(owner != msg.sender, "You cannot buy your own tickets.");

        uint price = resoldTicketsBulks[owner][eventId][ticketType].price * amount;

        resoldTicketsBulks[owner][eventId][ticketType].amountOnSale -= amount;

        if (resoldTicketsBulks[owner][eventId][ticketType].amountOnSale == 0 && resoldTicketsBulks[owner][eventId][ticketType].amountNotOnSale == 0) {
            delete resoldTicketsBulks[owner][eventId][ticketType];
        }
        owner.transfer(price);

        eventToOwners[eventId].push(msg.sender);
        
        uint currentAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        uint currentAmountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale;

        TicketValidation.ResoldTicketsBulk memory rtb = TicketValidation.ResoldTicketsBulk(eventId, currentAmountOnSale, amount + currentAmountNotOnSale, ticketType, 0, unsoldTicketsBulks[eventId][ticketType].description, msg.sender);
        resoldTicketsBulks[msg.sender][eventId][ticketType] = rtb;

        emit TicketTransferred(eventId, ticketType, owner, msg.sender, price);
    }
}