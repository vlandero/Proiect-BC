import React, { useState } from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";
import { listEventsMapper } from "../../utils/mappers";
import { EventType } from "../../utils/types";
import { EventComponent } from "../../components/EventComponent";

export default function Events() {
  const [modalOpen, setModalOpen] = useState<boolean>(true);
  const [events, setEvents] = useState<EventType[]>([]);
  return (
    <div>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          alert("Please connect your account to see the events!");
        }}
        callback={async (contract: ethers.Contract) => {
          const res = await contract.listEvents();
          const events = listEventsMapper(res);
          setEvents(events);
          setModalOpen(false);
        }}
      />
      {events.map((event, index) => (
        <EventComponent key={index} event={event} />
      ))}
    </div>
  );
}
