import { ethers } from "ethers";
import React, { useState } from "react";
import ConnectAccountModal, {
  TICKET_CONTRACT_ADDRESS,
  provider,
} from "../../components/ConnectAccountModal";
import { useNavigate } from "react-router-dom";
import ABI from "../../TicketMarket.json";

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
      <div>Price in ETH</div>
      <input
        value={ticketType.price}
        onChange={onChange}
        name="price"
        type="number"
        placeholder="Price"
      />
      <div>Quantity</div>
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
  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([]);
  const [name, setName] = useState<string>("");
  const [description, setDescription] = useState<string>("");
  const [startDateTime, setStartDateTime] = useState<string>("");
  const [endDateTime, setEndDateTime] = useState<string>("");

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [extraModalError, setExtraModalError] = useState<string>("");

  const [modalOpen, setModalOpen] = useState<boolean>(false);

  const navigate = useNavigate();

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
        value={startDateTime}
        onChange={(e) => setStartDateTime(e.target.value)}
        type="datetime-local"
        placeholder="Start Date and Time"
      />
      <input
        value={endDateTime}
        onChange={(e) => setEndDateTime(e.target.value)}
        type="datetime-local"
        placeholder="End Date and Time"
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
        callback={async (contract, signer) => {
          contract.on(
            "EventCreated",
            async (eventId, name, description, dateStart, creator) => {
              console.log("received event");
              console.log(creator)
              const signerAddress = await signer.getAddress();
              console.log(signerAddress)
              if (creator === signerAddress) {
                navigate(`/event/${eventId}`);
              }
            }
          );
          const eventInput = [
            name,
            description,
            new Date(startDateTime).getTime() / 1000,
            new Date(endDateTime).getTime() / 1000,
            ticketTypes.map((ticket) => ({
              eventId: 0,
              amount: ticket.quantity,
              ticketType: ticket.name,
              price: BigInt(ticket.price) * BigInt(1e18),
              description: ticket.description,
            })),
          ];
          try {
            setIsLoading(true);
            const res = await contract.createEvent(...eventInput);
            console.log(res);
            setIsLoading(false);
          } catch (e: any) {
            console.log(e);
            setIsLoading(false);
            setExtraModalError(e.reason || "Error creating event");
          }
        }}
      >
        {isLoading ? <div>Loading...</div> : null}
        {extraModalError ? <div>{extraModalError}</div> : null}
      </ConnectAccountModal>
    </div>
  );
}
