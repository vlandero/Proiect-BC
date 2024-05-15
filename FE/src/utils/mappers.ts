import { EventType, ResoldTicketsBulk, TicketsBulk } from "./types";

export const listEventsMapper = (ev: any): EventType[] => {
  return ev.map(eventMapper);
};

export const eventMapper = (ev: any): EventType => {
  const dateStart = new Date(parseInt(ev[3]) * 1000);
  const dateEnd = new Date(parseInt(ev[4]) * 1000);
  return {
    id: ev[0].toString(),
    name: ev[1].toString(),
    description: ev[2].toString(),
    dateStart: dateStart.toISOString(),
    dateEnd: dateEnd.toISOString(),
    creator: ev[5].toString(),
  };
};

export const ticketsBulkMapper = (ev: any): TicketsBulk[] => {
  return ev.map((ticket: any) => ({
    eventId: parseInt(ticket[0].toString()),
    amount: parseInt(ticket[1].toString()),
    ticketType: ticket[2].toString(),
    price: Number(ticket[3] / BigInt(1e18)),
    description: ticket[4].toString(),
  }));
};

export const resoldTicketsBulkMapper = (ev: any): ResoldTicketsBulk[] => {
  return ev.map((ticket: any) => ({
    eventId: parseInt(ticket[0].toString()),
    amountOnSale: parseInt(ticket[1].toString()),
    amountNotOnSale: parseInt(ticket[2].toString()),
    ticketType: ticket[3].toString(),
    price: Number(ticket[4] / BigInt(1e18)),
    description: ticket[5].toString(),
    owner: ticket[6].toString(),
  }));
};

export const resoldToNormal = (ev: ResoldTicketsBulk): TicketsBulk => {
  return {
    eventId: ev.eventId,
    amount: ev.amountOnSale,
    ticketType: ev.ticketType,
    price: ev.price,
    description: ev.description,
  };
};
