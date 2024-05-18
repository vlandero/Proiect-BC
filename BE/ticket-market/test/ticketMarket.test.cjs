const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TicketMarket", function () {
  beforeEach(async function () {
    TicketMarket = await ethers.getContractFactory("TicketMarket");
    [addr1, addr2, addr3] = await ethers.getSigners();

    ticketMarket = await TicketMarket.deploy();
    await ticketMarket.deployed();
  });

  it("Should create an event", async function () {
    const eventName = "Test Event";
    const eventDescription = "This is a test event";
    const dateStart = Math.floor(Date.now() / 1000) + 3600;
    const dateEnd = Math.floor(Date.now() / 1000) + 7200;
    const ticketType = "General Admission";
    const ticketAmount = 100;
    const ticketPrice = ethers.utils.parseEther("1.0");

    await ticketMarket.createEvent(
      eventName,
      eventDescription,
      dateStart,
      dateEnd,
      [
        {
          eventId: 1,
          amount: ticketAmount,
          ticketType: ticketType,
          price: ticketPrice,
          description: "General admission ticket",
        },
      ]
    );

    const events = await ticketMarket.listEvents();
    expect(events.length).to.equal(1);
    expect(events[0].name).to.equal(eventName);
  });

  it("Should buy new tickets", async function () {
    const eventName = "Test Event";
    const eventDescription = "This is a test event";
    const dateStart = Math.floor(Date.now() / 1000) + 3600;
    const dateEnd = Math.floor(Date.now() / 1000) + 7200;
    const ticketType = "VIP";
    const ticketAmount = 10;
    const ticketPrice = ethers.utils.parseEther("2.0");

    await ticketMarket
      .connect(addr2)
      .createEvent(eventName, eventDescription, dateStart, dateEnd, [
        {
          eventId: 1,
          amount: ticketAmount,
          ticketType: ticketType,
          price: ticketPrice,
          description: "VIP ticket",
        },
      ]);

    await ticketMarket
      .connect(addr1)
      .buyNewTickets(1, ticketType, 5, { value: ticketPrice.mul(5) });

    const availableTickets = await ticketMarket
      .connect(addr1)
      .getAvailableTicketsForEvent(1);
    const boughtTickets = availableTickets.find(
      (t) => t.ticketType === ticketType
    );
    expect(boughtTickets.amount).to.equal(5);
  });

  it("Should buy resold tickets", async function () {
    const eventName = "Test Event";
    const eventDescription = "This is a test event";
    const dateStart = Math.floor(Date.now() / 1000) + 3600;
    const dateEnd = Math.floor(Date.now() / 1000) + 7200;
    const ticketType = "VIP";
    const ticketAmount = 10;
    const ticketPrice = ethers.utils.parseEther("2.0");

    await ticketMarket
      .connect(addr1)
      .createEvent(eventName, eventDescription, dateStart, dateEnd, [
        {
          eventId: 1,
          amount: ticketAmount,
          ticketType: ticketType,
          price: ticketPrice,
          description: "VIP ticket",
        },
      ]);

    await ticketMarket
      .connect(addr2)
      .buyNewTickets(1, ticketType, 5, { value: ticketPrice.mul(5) });

    const resellPrice = ethers.utils.parseEther("2.5");

    await ticketMarket
      .connect(addr2)
      .editTicketsBulk(1, ticketType, resellPrice, 4);

    await ticketMarket
      .connect(addr3)
      .buyResoldTickets(1, ticketType, addr2.getAddress(), 3, {
        value: resellPrice.mul(3),
      });

    const resoldTickets = await ticketMarket.getResoldTicketsForEvent(1);
    const boughtResoldTickets = resoldTickets.find(
      (t) => t.ticketType === ticketType && t.owner === addr2.address
    );

    expect(boughtResoldTickets.amountOnSale).to.equal(1); // din 4, 3 au fost cumparate
  });

  it("Should buy new tickets and save in withdrawal", async function () {
    const eventName = "Test Event";
    const eventDescription = "This is a test event";
    const dateStart = Math.floor(Date.now() / 1000) + 3600;
    const dateEnd = Math.floor(Date.now() / 1000) + 7200;
    const ticketType = "VIP";
    const ticketAmount = 10;
    const ticketPrice = ethers.utils.parseEther("2.0");

    await ticketMarket
      .connect(addr2)
      .createEvent(eventName, eventDescription, dateStart, dateEnd, [
        {
          eventId: 1,
          amount: ticketAmount,
          ticketType: ticketType,
          price: ticketPrice,
          description: "VIP ticket",
        },
      ]);

    await ticketMarket
      .connect(addr3)
      .buyNewTickets(1, ticketType, 4, { value: ticketPrice.mul(5) });

    const pendingWithdrawals = await ticketMarket.getPendingWithdrawal(
      addr3.address
    );

    const ownerWithdrawal = await ticketMarket.connect(addr1).getOwnerComission();

    expect(pendingWithdrawals).to.equal(ticketPrice);
    expect(ownerWithdrawal).to.equal(ticketPrice.mul(4).mul(5).div(100));

    const ownerBalanceBefore = await addr1.getBalance();
    await ticketMarket.connect(addr1).withdrawOwnerComission();
    const ownerBalanceAfter = await addr1.getBalance();
    expect(ownerBalanceAfter > ownerBalanceBefore).to.equal(true);
  });
});