import React, { useEffect, useState } from "react";

type TicketType = {
  name: string;
  description: string;
  price: number;
  quantity: number;
};

function TicketTypeComponent({ ticket }: { ticket: TicketType }) {
  return (
    <div>
      <h2>{ticket.name}</h2>
      <p>Description: {ticket.description}</p>
      <p>Ticket Price: {ticket.price}</p>
      <p>Tickets left: {ticket.quantity}</p>
    </div>
  );
}

function AddTicketTypeComponent({
  addEvent,
}: {
  addEvent: (ticketType: TicketType) => void;
}) {
  const defaultTicketType: TicketType = {
    name: "",
    description: "",
    price: 0,
    quantity: 0,
  };
  const [ticketType, setTicketType] = useState<TicketType>(defaultTicketType);
  const onChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setTicketType({ ...ticketType, [e.target.name]: e.target.value });
  };

  const validateTicketType = () => {
    if (
      ticketType.name === "" ||
      ticketType.description === "" ||
      ticketType.price === 0 ||
      ticketType.quantity === 0
    ) {
      return false;
    }
    return true;
  };

  const onClick = () => {
    if (!validateTicketType()) {
      alert("Please fill all the fields");
      return;
    }
    addEvent(ticketType);
    setTicketType(defaultTicketType);
  };
  return (
    <div>
      <h4>Add Ticket Type</h4>
      <input
        value={ticketType.name}
        onChange={onChange}
        name="name"
        type="text"
        placeholder="Ticket Type"
      />
      <textarea
        value={ticketType.description}
        onChange={onChange}
        name="description"
        placeholder="Description"
      />
      <input
        value={ticketType.price}
        onChange={onChange}
        name="price"
        type="number"
        placeholder="Price"
      />
      <input
        value={ticketType.quantity}
        onChange={onChange}
        name="quantity"
        type="number"
        placeholder="Quantity"
      />
      <button onClick={onClick}>Create Ticket Type</button>
    </div>
  );
}

export default function AddEvent() {
  const [events, setEvents] = useState<TicketType[]>([]);

  const addEvent = (ticket: TicketType) => {
    setEvents([...events, ticket]);
  };
  const createEvent = async () => {
    console.log(events);
  };
  return (
    <div className="add-event-container">
      <h3>Create event</h3>
      <AddTicketTypeComponent addEvent={addEvent} />
      <div>
        {events?.map((ticket, index) => (
          <div key={index}>
            <TicketTypeComponent ticket={ticket} />
          </div>
        ))}
      </div>
      <button onClick={createEvent}>Create Event</button>
    </div>
  );
}
