export type EventType = {
    id: string;
    name: string;
    description: string;
    dateStart: string;
    dateEnd: string;
    creator: string;
}

export type TicketsBulk = {
    eventId: number;
    amount: number;
    ticketType: string;
    price: number;
    description: string;
}

export type CreateEventInput = {
    name: string;
    description: string;
    dateStart: number;
    dateEnd: number;
    availableTickets: TicketsBulk[];
}

export type ResoldTicketsBulk = {
    eventId: number;
    amountOnSale: number;
    amountNotOnSale: number;
    ticketType: string;
    price: number;
    description: string;
    owner: string;
}