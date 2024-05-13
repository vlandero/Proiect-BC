// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TicketMarket {
    enum TicketForSale { OnSale, NotOnSale }
    struct Event {
        uint id;
        string name;
        string description;
        uint dateStart;
        uint dateEnd;
        address creator;
    }

    struct ResoldTicketsBulk {
        uint eventId;
        uint amountOnSale;
        uint amountNotOnSale;
        string ticketType;
        uint price;
        string description;
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
    mapping(address => mapping(uint => mapping(string => ResoldTicketsBulk))) public resoldTicketsBulks;

    mapping (uint => address[]) public eventToOwners;

    event EventCreated(uint eventId, string name, string description, uint date);
    event TicketBulkCreated(uint eventId, uint price, string ticketType);
    event TicketTransferred(uint eventId, string ticketType, address from, address to, uint price);
    event TicketPriceUpdated(uint eventId, string ticketType, uint price);
    event TicketOnSale(uint ticketId, string ticketType, uint price, bool isOnSale);
    event EventEdited(uint eventId, string name, string description, uint date);

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function putTicketBulkOnResale(uint eventId, string memory ticketType, uint price, uint ticketAmount) public { // ticket amount, split and merge ticket bulks
        require(compareStrings(resoldTicketsBulks[msg.sender][eventId][ticketType].ticketType, ticketType), "You do not own the ticket.");
        require(!compareStrings(resoldTicketsBulks[msg.sender][eventId][ticketType].ticketType, ""), "You do not own the ticket.");
        require(resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale == 0, "The ticket is already on sale.");
        require(price >= 0, "Price must be greater (or equal) than zero.");
        require(resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale >= ticketAmount, "Not enough tickets to put on sale.");

        resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale -= ticketAmount;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale += ticketAmount;
        resoldTicketsBulks[msg.sender][eventId][ticketType].price = price;

        emit TicketOnSale(eventId, ticketType, price, true);
    }

    function editTicketBulkPrice(uint eventId, string memory ticketType, uint price, uint amountOnSale) public {
        require(compareStrings(resoldTicketsBulks[msg.sender][eventId][ticketType].ticketType, ticketType), "You do not own the ticket.");
        require(!compareStrings(resoldTicketsBulks[msg.sender][eventId][ticketType].ticketType, ""), "You do not own the ticket.");
        require(resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale > 0, "The ticket is not on sale.");
        require(price >= 0, "Price must be greater (or equal) than zero.");
        require(amountOnSale <= resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale + resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale, "Not enough tickets to put on sale.");

        resoldTicketsBulks[msg.sender][eventId][ticketType].price = price;
        uint prevAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale = amountOnSale;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale += prevAmountOnSale - amountOnSale;

        emit TicketPriceUpdated(eventId, ticketType, price);
    }

    function createEvent(string memory name, string memory description, uint dateStart, uint dateEnd, TicketsBulk[] memory availableTickets) public {
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

    function editEvent(uint eventId, string memory name, string memory description, uint dateStart, uint dateEnd, TicketsBulk[] memory availableTickets) public {
        require(events[eventId].creator == msg.sender, "You are not the creator of this event.");
        require(events[eventId].dateStart > block.timestamp, "Event has already started");
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
    
    function getResoldTicketsForEvent(uint eventId) public view returns (ResoldTicketsBulk[] memory) {
        require(events[eventId].dateStart > block.timestamp, "Event has already started");
        uint count = 0;
        for(uint i = 0; i < eventToOwners[eventId].length; i++) {
            for (uint j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]].amountOnSale > 0) {
                    count++;
                }
            }
        }
        ResoldTicketsBulk[] memory resoldTickets = new ResoldTicketsBulk[](count);
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

    function getTicketBulksForOwner() public view returns (ResoldTicketsBulk[] memory) {
        uint count = 0;
        for (uint i = 0; i < nextEventId; i++) {
            for (uint j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountOnSale > 0 || resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountNotOnSale > 0) {
                    count++;
                }
            }
        }
        ResoldTicketsBulk[] memory resoldTickets = new ResoldTicketsBulk[](count);
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

    function buyNewTickets(uint eventId, string memory ticketType, uint amount) public payable {
        require(events[eventId].dateStart > block.timestamp, "Event has already started");
        require(unsoldTicketsBulks[eventId][ticketType].amount > amount, "No more tickets available for this type.");
        require(msg.value == unsoldTicketsBulks[eventId][ticketType].price * amount, "Incorrect payment amount.");
        unsoldTicketsBulks[eventId][ticketType].amount -= amount;
        address payable previousOwner = payable(events[eventId].creator);
        previousOwner.transfer(msg.value);

        uint currentAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        uint currentAmountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale;

        ResoldTicketsBulk memory rtb = ResoldTicketsBulk(eventId, currentAmountOnSale, amount + currentAmountNotOnSale, ticketType, 0, unsoldTicketsBulks[eventId][ticketType].description);
        resoldTicketsBulks[msg.sender][eventId][ticketType] = rtb;

        emit TicketTransferred(eventId, ticketType, previousOwner, msg.sender, msg.value);
    }

    function buyResoldTickets(uint eventId, string memory ticketType, address payable owner, uint amount) public payable {
        require(compareStrings(resoldTicketsBulks[owner][eventId][ticketType].ticketType, ticketType), "Owner does not own the ticket.");
        require(compareStrings(resoldTicketsBulks[owner][eventId][ticketType].ticketType, ""), "Owner does not own the ticket.");
        require(events[eventId].dateStart > block.timestamp, "Event has already started");
        require(resoldTicketsBulks[owner][eventId][ticketType].amountOnSale > amount, "Not enough tickets on sale.");
        require(msg.value == resoldTicketsBulks[owner][eventId][ticketType].price * amount, "Incorrect payment amount.");

        resoldTicketsBulks[owner][eventId][ticketType].amountOnSale -= amount;

        if (resoldTicketsBulks[owner][eventId][ticketType].amountOnSale == 0 && resoldTicketsBulks[owner][eventId][ticketType].amountNotOnSale == 0) {
            delete resoldTicketsBulks[owner][eventId][ticketType];
        }
        owner.transfer(msg.value);
        
        uint currentAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        uint currentAmountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale;

        ResoldTicketsBulk memory rtb = ResoldTicketsBulk(eventId, currentAmountOnSale, amount + currentAmountNotOnSale, ticketType, 0, unsoldTicketsBulks[eventId][ticketType].description);
        resoldTicketsBulks[msg.sender][eventId][ticketType] = rtb;

        emit TicketTransferred(eventId, ticketType, owner, msg.sender, msg.value);
    }
}
