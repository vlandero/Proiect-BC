import React, { useState } from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";
import { ResoldTicketsBulk } from "../../utils/types";
import { resoldTicketsBulkMapper } from "../../utils/mappers";

function TicketComponent({
  ticket,
  onSale,
  setTickets,
}: {
  ticket: ResoldTicketsBulk;
  onSale: boolean;
  setTickets: React.Dispatch<React.SetStateAction<ResoldTicketsBulk[]>>;
}) {
  const [newPrice, setNewPrice] = useState<number>(ticket.price);
  const [newAmount, setNewAmount] = useState<number>(ticket.amountOnSale);
  const [editing, setEditing] = useState<boolean>(false);
  const [modalOpen, setModalOpen] = useState<boolean>(false);

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [extraModalError, setExtraModalError] = useState<string>("");

  const editTicket = () => {
    if (editing) {
      setEditing(false);
    } else {
      setEditing(true);
    }
  };

  const saveChanges = () => {
    setModalOpen(true);
  };

  return (
    <div>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          setEditing(false);
          setModalOpen(false);
        }}
        callback={async (contract: ethers.Contract) => {
          try {
            setIsLoading(true);
            await contract.editTicketsBulk(
              ticket.eventId,
              ticket.ticketType,
              BigInt(newPrice) * BigInt(1e18),
              newAmount
            );
            setEditing(false);
            setModalOpen(false);
            setTickets((prev) =>
              prev.map((t) =>
                t.eventId === ticket.eventId &&
                t.ticketType === ticket.ticketType
                  ? {
                      ...t,
                      amountOnSale: newAmount,
                      price: newPrice,
                      amountNotOnSale:
                        t.amountNotOnSale + t.amountOnSale - newAmount,
                    }
                  : t
              )
            );
            setIsLoading(false);
          } catch (error) {
            setIsLoading(false);
            setExtraModalError("Error editing ticket");
          }
        }}
      >
        {isLoading ? <div>Loading...</div> : null}
        {extraModalError ? <div>{extraModalError}</div> : null}
      </ConnectAccountModal>
      {onSale && (
        <button onClick={editTicket}>{editing ? "Cancel" : "Edit"}</button>
      )}
      <h4>{ticket.ticketType}</h4>
      <div>Description: {ticket.description}</div>
      {editing && onSale ? (
        <div>
          <input
            type="number"
            value={newAmount}
            onChange={(e) => setNewAmount(parseInt(e.target.value))}
          />
          <input
            type="number"
            value={newPrice}
            onChange={(e) => setNewPrice(parseInt(e.target.value))}
          />
          <button onClick={saveChanges}>Save</button>
        </div>
      ) : onSale ? (
        <div>
          <div>Amount on sale: {ticket.amountOnSale}</div>
          <div>Price: {ticket.price}</div>
        </div>
      ) : (
        <div>Amount not on sale: {ticket.amountNotOnSale}</div>
      )}
    </div>
  );
}

export default function MyTickets() {
  const [modalOpen, setModalOpen] = useState<boolean>(true);
  const [tickets, setTickets] = useState<ResoldTicketsBulk[]>([]);
  return (
    <div>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          alert("Please connect your account to see the events!");
        }}
        callback={async (contract: ethers.Contract) => {
          const res = await contract.getTicketBulksForOwner();
          console.log(res);
          const tickets = resoldTicketsBulkMapper(res);
          setTickets(tickets);
          console.log(tickets);
          setModalOpen(false);
        }}
      />
      <h3>My tickets</h3>
      {tickets.map((ticket, index) => (
        <TicketComponent
          setTickets={setTickets}
          ticket={ticket}
          onSale={false}
          key={index}
        />
      ))}
      <h3>Tickets on sale</h3>
      {tickets.map((ticket, index) => (
        <TicketComponent
          setTickets={setTickets}
          ticket={ticket}
          onSale={true}
          key={index}
        />
      ))}
    </div>
  );
}
