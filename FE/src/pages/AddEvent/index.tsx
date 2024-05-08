import React, { useEffect, useState } from "react";

type TicketType = {
  name: string;
  description: string;
  price: number;
  quantity: number;
};

export default function AddEvent() {
  const [events, setEvents] = useState<TicketType[] | null>([]);
  
  const createEvent = async () => {
    const description = document.querySelector(".event-description-input") as HTMLInputElement;
    const name = document.querySelector(".event-name-input") as HTMLInputElement;
    const price = document.querySelector(".event-price-input") as HTMLInputElement;
    const quantity = document.querySelector(".event-quantity-input") as HTMLInputElement;
    const event = {
      name: name.value,
      description: description.value,
      price: parseInt(price.value, 10), 
      quantity: parseInt(quantity.value, 10),
    };
    if (events !== null) {
      setEvents([...events, event]);
    } else {
      setEvents([event]);
    }
  };
  
  useEffect(() => {
    console.log(events);
  }, [events]);
  return (
    <div className="add-event-container">
        <h1>
          Add Ticket Type
        </h1>
        <input className="event-name-input" type="text" placeholder="Ticket Type" />
        <input className="event-description-input" type="text" placeholder="Description" />
        <input className="event-price-input" type="number" placeholder="Price" />
        <input className="event-quantity-input" type="number" placeholder="Quantity" />
        <button onClick={createEvent}>Create Ticket Type</button>
        <div>
          {events?.map((ticket, index) => (
            <div key={index}>
              <h2>{ticket.name}</h2>
              <p>Description: {ticket.description}</p>
              <p>Ticket Price: {ticket.price}</p>
              <p>Tickets left: {ticket.quantity}</p>
            </div>
          ))}
          </div>
    </div>
  );
}
