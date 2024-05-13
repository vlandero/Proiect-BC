import { ethers } from "ethers";
import React, { useState } from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";

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
  addTicketType,
}: {
  addTicketType: (ticketType: TicketType) => void;
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
    addTicketType(ticketType);
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
  const [account, setAccount] = useState<ethers.JsonRpcSigner | null>(null);
  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([]);
  const [name, setName] = useState<string>("");
  const [description, setDescription] = useState<string>("");
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");

  const [modalOpen, setModalOpen] = useState<boolean>(true);

  const addTicketType = (ticket: TicketType) => {
    setTicketTypes([...ticketTypes, ticket]);
  };
  const createEvent = async () => {
    console.log(ticketTypes);
    setModalOpen(true);
  };
  return (
    <div className="add-event-container">
      <h3>Create event</h3>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        type="text"
        placeholder="Event Name"
      />
      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        placeholder="Description"
      />
      <input
        value={startDate}
        onChange={(e) => setStartDate(e.target.value)}
        type="date"
        placeholder="Start Date"
      />
      <input
        value={endDate}
        onChange={(e) => setEndDate(e.target.value)}
        type="date"
        placeholder="End Date"
      />
      <AddTicketTypeComponent addTicketType={addTicketType} />
      <div>
        {ticketTypes?.map((ticket, index) => (
          <div key={index}>
            <TicketTypeComponent ticket={ticket} />
          </div>
        ))}
      </div>
      <button onClick={createEvent}>Create Event</button>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          setModalOpen(false);
        }}
      />
    </div>
  );
}
