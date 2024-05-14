import React, { useState } from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";
import { ResoldTicketsBulk } from "../../utils/types";
import { resoldTicketsBulkMapper } from "../../utils/mappers";

function TicketComponent({
  ticket,
  editable,
}: {
  ticket: ResoldTicketsBulk;
  editable: boolean;
}) {
  const editTicket = async () => {
    alert("Edit ticket");
  };
  // edit price and amount on sale
  return (
    <div>
      {editable && <button onClick={editTicket}>Edit</button>}
      <div>{ticket.description}</div>
      <div>{ticket.price}</div>
      <div>{ticket.ticketType}</div>
      <div>{ticket.amountOnSale}</div>
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
          const tickets = resoldTicketsBulkMapper(res);
          setTickets(tickets);
          console.log(tickets);
          setModalOpen(false);
        }}
      />
      <h3>My tickets</h3>
      {tickets.map((ticket, index) => (
        <TicketComponent ticket={ticket} editable={true} key={index} />
      ))}
      <h3>Tickets on sale</h3>
      {tickets.map((ticket, index) => (
        <TicketComponent ticket={ticket} editable={true} key={index} />
      ))}
    </div>
  );
}
