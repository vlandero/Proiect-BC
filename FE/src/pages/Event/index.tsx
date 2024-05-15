import React, { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";
import {
  eventMapper,
  resoldTicketsBulkMapper,
  resoldToNormal,
  ticketsBulkMapper,
} from "../../utils/mappers";
import { EventType, ResoldTicketsBulk, TicketsBulk } from "../../utils/types";
import styles from "./index.module.css";

function TicketComponent({
  ticket,
  owner,
}: {
  ticket: TicketsBulk;
  owner?: string;
}) {
  const { eventId } = useParams();
  const [amount, setAmount] = useState<number>(0);
  const [modalOpen, setModalOpen] = useState<boolean>(false);
  const navigate = useNavigate();
  const buy = async () => {
    if (amount === 0) {
      alert("Please select the amount of tickets you want to buy!");
      return;
    }
    setModalOpen(true);
  };
  return (
    <div className={styles["ticket-bulk"]}>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          setModalOpen(false);
        }}
        callback={async (contract: ethers.Contract) => {
          try {
            if (owner) {
              await contract.buyResoldTickets(
                eventId,
                ticket.ticketType,
                owner,
                amount,
                {
                  value: BigInt(amount) * BigInt(ticket.price) * BigInt(1e18),
                }
              );
            } else {
              await contract.buyNewTickets(eventId, ticket.ticketType, amount, {
                value: BigInt(amount) * BigInt(ticket.price) * BigInt(1e18),
              });
              setModalOpen(false);
              navigate(`/my-tickets`);
            }
          } catch (error: any) {
            console.log(error);
          }
        }}
      />
      <h4>{ticket.ticketType}</h4>
      <p>{ticket.description}</p>
      <p>{ticket.price} ETH</p>
      <p>{ticket.amount} tickets</p>
      <div>
        <button onClick={buy}>Buy</button>
        <div>
          <div>Amount</div>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(parseInt(e.target.value))}
          />
        </div>
      </div>
    </div>
  );
}

export default function Event() {
  const { eventId } = useParams();
  const [modalOpen, setModalOpen] = useState<boolean>(true);
  const [event, setEvent] = useState<EventType | undefined>(undefined);
  const [newTickets, setNewTickets] = useState<TicketsBulk[]>([]);
  const [resoldTickets, setResoldTickets] = useState<ResoldTicketsBulk[]>([]);
  if (!eventId) {
    return <div>Invalid event id</div>;
  }
  return (
    <div>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          alert("Please connect your account to see the events!");
        }}
        callback={async (contract: ethers.Contract) => {
          const eventRes = await contract.events(eventId);
          setEvent(eventMapper(eventRes));
          const newTicketsRes = await contract.getAvailableTicketsForEvent(
            eventId
          );
          setNewTickets(ticketsBulkMapper(newTicketsRes));
          const resoldTicketsRes = await contract.getResoldTicketsForEvent(
            eventId
          );
          console.log(resoldTicketsRes)
          setResoldTickets(resoldTicketsBulkMapper(resoldTicketsRes));
          setModalOpen(false);
        }}
      />
      <h2>{event?.name}</h2>
      <p>Description: {event?.description}</p>
      <p>Start Date: {event?.dateStart}</p>
      <p>End Date: {event?.dateEnd}</p>
      <h3>Tickets</h3>
      {newTickets.map((ticket, index) => (
        <TicketComponent key={index} ticket={ticket} />
      ))}
      <h3>Resold tickets</h3>
      {resoldTickets.map((ticket, index) => (
        <TicketComponent
          key={index}
          ticket={resoldToNormal(ticket)}
          owner={ticket.owner}
        />
      ))}
    </div>
  );
}
