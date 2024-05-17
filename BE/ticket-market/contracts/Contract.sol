// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Withdrawable.sol";
import "hardhat/console.sol";

library StringLibrary {
    function compare(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

library TicketValidation{
    using StringLibrary for string;
    struct ResoldTicketsBulk {
        uint256 eventId;
        uint256 amountOnSale;
        uint256 amountNotOnSale;
        string ticketType;
        uint256 price;
        string description;
        address owner;
    }
    function validateOwnershipAndType(ResoldTicketsBulk storage ticket, string memory ticketType) internal view {
        require(ticket.ticketType.compare(ticketType), "Owner does not own the ticket.");
        require(!ticket.ticketType.compare(""), "Ticket type is unspecified.");
    }
}

contract TicketMarket is Withdrawable {
    using TicketValidation for TicketValidation.ResoldTicketsBulk;
    enum TicketForSale { OnSale, NotOnSale }
    struct Event {
        uint256 id;
        string name;
        string description;
        uint256 dateStart;
        uint256 dateEnd;
        address creator;
    }

    struct TicketsBulk {
        uint256 eventId;
        uint256 amount;
        string ticketType;
        uint256 price;
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
        for (uint256 i = 0; i < ticketTypesSet.values.length; i++) {
            delete ticketTypesSet.is_in[ticketTypesSet.values[i]];
        }
    }


    uint256 public nextEventId = 1;

    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(string => TicketsBulk)) public unsoldTicketsBulks;
    mapping(address => mapping(uint256 => mapping(string => TicketValidation.ResoldTicketsBulk))) public resoldTicketsBulks;

    mapping (uint256 => address[]) public eventToOwners;

    event EventCreated(uint256 eventId, string name, string description, uint256 date, address creator);
    event TicketBulkCreated(uint256 eventId, uint256 price, string ticketType);
    event TicketTransferred(uint256 eventId, string ticketType, address from, address to, uint256 price);
    event TicketPriceUpdated(uint256 eventId, string ticketType, uint256 price);
    event TicketOnSale(uint256 ticketId, string ticketType, uint256 price, bool isOnSale);
    event EventEdited(uint256 eventId, string name, string description, uint256 date);

    modifier ValidDate(uint256 dateStart, uint256 dateEnd) {
        require(dateStart > block.timestamp, "Event must start in the future.");
        require(dateEnd >= dateStart, "Event must end after it starts.");
        _;
    }

    modifier CheckBalanceAndWithdrawExceeded(uint256 amount) {
        require(msg.value >= amount, "Insufficient funds.");
        uint256 excess = msg.value - amount;
        if (excess > 0) {
            _addToPendingWithdrawal(msg.sender, excess);
        }
        _;
    }

    function editTicketsBulk(uint256 eventId, string memory ticketType, uint256 price, uint256 amountOnSale) external {
        resoldTicketsBulks[msg.sender][eventId][ticketType].validateOwnershipAndType(ticketType);
        require(resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale + resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale > 0, "You own no tickets of this type.");
        require(price >= 0, "Price must be greater (or equal) than zero.");
        require(amountOnSale <= resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale + resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale, "Not enough tickets to put on sale.");

        resoldTicketsBulks[msg.sender][eventId][ticketType].price = price;
        uint256 prevAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale = amountOnSale;
        resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale + prevAmountOnSale - amountOnSale;

        emit TicketPriceUpdated(eventId, ticketType, price);
    }

    function createEvent(string memory name, string memory description, uint256 dateStart, uint256 dateEnd, TicketsBulk[] memory availableTickets) external ValidDate(dateStart, dateEnd) {
        uint256 eventId = nextEventId++;
        events[eventId] = Event(eventId, name, description, dateStart, dateEnd, msg.sender);
        for (uint256 i = 0; i < availableTickets.length; i++) {
            addToSet(availableTickets[i].ticketType);
            TicketsBulk memory tb = TicketsBulk(eventId, availableTickets[i].amount, availableTickets[i].ticketType, availableTickets[i].price, availableTickets[i].description);
            unsoldTicketsBulks[eventId][availableTickets[i].ticketType] = tb;
            emit TicketBulkCreated(eventId, availableTickets[i].price, availableTickets[i].ticketType);
        }
        emit EventCreated(eventId, name, description, dateStart, msg.sender);
    }

    function deleteEvent(uint256 eventId) external {
        require(events[eventId].creator == msg.sender, "You are not the creator of this event.");
        for (uint256 i = 0; i < ticketTypesSet.values.length; i++) {
            delete unsoldTicketsBulks[eventId][ticketTypesSet.values[i]];
        }
        delete events[eventId];
    }

    function editEvent(uint256 eventId, string memory name, string memory description, uint256 dateStart, uint256 dateEnd, TicketsBulk[] memory availableTickets) external ValidDate(dateStart, dateEnd){
        require(events[eventId].creator == msg.sender, "You are not the creator of this event.");
        events[eventId].name = name;
        events[eventId].description = description;
        events[eventId].dateStart = dateStart;
        events[eventId].dateEnd = dateEnd;

        resetSet();
        for (uint256 i = 0; i < availableTickets.length; i++) {
            addToSet(availableTickets[i].ticketType);
            TicketsBulk memory tb = TicketsBulk(eventId, availableTickets[i].amount, availableTickets[i].ticketType, availableTickets[i].price, availableTickets[i].description);
            unsoldTicketsBulks[eventId][availableTickets[i].ticketType] = tb;
            emit TicketBulkCreated(eventId, availableTickets[i].price, availableTickets[i].ticketType);
        }
        emit EventEdited(eventId, name, description, dateStart);
    }

    function listEvents() external view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](nextEventId - 1);
        for (uint256 i = 1; i < nextEventId; i++) {
            allEvents[i - 1] = events[i];
        }
        return allEvents;
    }

    function listMyEvents() external view returns (Event[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (events[i].creator == msg.sender) {
                count++;
            }
        }
        Event[] memory myEvents = new Event[](count);
        count = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (events[i].creator == msg.sender) {
                myEvents[count++] = events[i];
            }
        }
        return myEvents;
    }

    function getAvailableTicketsForEvent(uint256 eventId) external view returns (TicketsBulk[] memory) {
        require(events[eventId].dateStart > block.timestamp, "Event has already started");
        uint256 count = 0;
        for (uint256 i = 0; i < ticketTypesSet.values.length; i++) {
            if (unsoldTicketsBulks[eventId][ticketTypesSet.values[i]].amount > 0) {
                count++;
            }
        }
        TicketsBulk[] memory availableTickets = new TicketsBulk[](count);
        count = 0;
        for (uint256 i = 0; i < ticketTypesSet.values.length; i++) {
            if (unsoldTicketsBulks[eventId][ticketTypesSet.values[i]].amount > 0) {
                availableTickets[count++] = unsoldTicketsBulks[eventId][ticketTypesSet.values[i]];
            }
        }
        return availableTickets;
    }
    
    function getResoldTicketsForEvent(uint256 eventId) external view ValidDate(events[eventId].dateStart, events[eventId].dateEnd) returns (TicketValidation.ResoldTicketsBulk[] memory) {
        uint256 count = 0;
        for(uint256 i = 0; i < eventToOwners[eventId].length; i++) {
            for (uint256 j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]].amountOnSale > 0) {
                    count++;
                }
            }
        }
        TicketValidation.ResoldTicketsBulk[] memory resoldTickets = new TicketValidation.ResoldTicketsBulk[](count);
        count = 0;
        for(uint256 i = 0; i < eventToOwners[eventId].length; i++) {
            for (uint256 j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]].amountOnSale > 0) {
                    resoldTickets[count++] = resoldTicketsBulks[eventToOwners[eventId][i]][eventId][ticketTypesSet.values[j]];
                }
            }
        }
        return resoldTickets;
    }

    function getTicketBulksForOwner() external view returns (TicketValidation.ResoldTicketsBulk[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextEventId; i++) {
            for (uint256 j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountOnSale > 0 || resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountNotOnSale > 0) {
                    count++;
                }
            }
        }
        TicketValidation.ResoldTicketsBulk[] memory resoldTickets = new TicketValidation.ResoldTicketsBulk[](count);
        count = 0;
        for (uint256 i = 0; i < nextEventId; i++) {
            for (uint256 j = 0; j < ticketTypesSet.values.length; j++) {
                if (resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountOnSale > 0 || resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]].amountNotOnSale > 0) {
                    resoldTickets[count++] = resoldTicketsBulks[msg.sender][i][ticketTypesSet.values[j]];
                }
            }
        }
        return resoldTickets;
    }

    function buyNewTickets(uint256 eventId, string memory ticketType, uint256 amount) external payable ValidDate(events[eventId].dateStart, events[eventId].dateEnd) CheckBalanceAndWithdrawExceeded(unsoldTicketsBulks[eventId][ticketType].price * amount){
        require(events[eventId].creator != msg.sender, "You cannot buy tickets for your own event.");
        require(unsoldTicketsBulks[eventId][ticketType].amount >= amount, "No more tickets available for this type.");
        unsoldTicketsBulks[eventId][ticketType].amount -= amount;
        address payable previousOwner = payable(events[eventId].creator);
        uint256 price = unsoldTicketsBulks[eventId][ticketType].price * amount;
        addToOwnerPendingWithdrawal(price * 5 / 100);
        previousOwner.transfer(price - price * 5 / 100);

        eventToOwners[eventId].push(msg.sender);

        uint256 currentAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        uint256 currentAmountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale;

        string memory desc = unsoldTicketsBulks[eventId][ticketType].description;
        TicketValidation.ResoldTicketsBulk memory rtb = TicketValidation.ResoldTicketsBulk(eventId, currentAmountOnSale, amount + currentAmountNotOnSale, ticketType, 0, desc, msg.sender);
        resoldTicketsBulks[msg.sender][eventId][ticketType] = rtb;

        emit TicketTransferred(eventId, ticketType, previousOwner, msg.sender, price - price * 5 / 100);
    }

    function buyResoldTickets(uint256 eventId, string memory ticketType, address payable owner, uint256 amount) external payable ValidDate(events[eventId].dateStart, events[eventId].dateEnd) CheckBalanceAndWithdrawExceeded(resoldTicketsBulks[owner][eventId][ticketType].price * amount){
        require(events[eventId].creator != msg.sender, "You cannot buy tickets for your own event.");
        resoldTicketsBulks[owner][eventId][ticketType].validateOwnershipAndType(ticketType);
        require(resoldTicketsBulks[owner][eventId][ticketType].amountOnSale >= amount, "Not enough tickets on sale.");
        require(owner != msg.sender, "You cannot buy your own tickets.");

        uint256 price = resoldTicketsBulks[owner][eventId][ticketType].price * amount;

        resoldTicketsBulks[owner][eventId][ticketType].amountOnSale -= amount;

        if (resoldTicketsBulks[owner][eventId][ticketType].amountOnSale == 0 && resoldTicketsBulks[owner][eventId][ticketType].amountNotOnSale == 0) {
            delete resoldTicketsBulks[owner][eventId][ticketType];
        }
        addToOwnerPendingWithdrawal(price * 5 / 100);
        owner.transfer(price - price * 5 / 100);

        eventToOwners[eventId].push(msg.sender);
        
        uint256 currentAmountOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountOnSale;
        uint256 currentAmountNotOnSale = resoldTicketsBulks[msg.sender][eventId][ticketType].amountNotOnSale;

        string memory desc = unsoldTicketsBulks[eventId][ticketType].description;
        TicketValidation.ResoldTicketsBulk memory rtb = TicketValidation.ResoldTicketsBulk(eventId, currentAmountOnSale, amount + currentAmountNotOnSale, ticketType, 0, desc, msg.sender);
        resoldTicketsBulks[msg.sender][eventId][ticketType] = rtb;

        emit TicketTransferred(eventId, ticketType, owner, msg.sender, price - price * 5 / 100);
    }
}