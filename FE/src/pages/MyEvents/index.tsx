import React, { useState } from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";
import { EventType } from "../../utils/types";
import { listEventsMapper } from "../../utils/mappers";
import { EventComponent } from "../../components/EventComponent";

export default function MyEvents() {
  const [modalOpen, setModalOpen] = useState<boolean>(false);
  const [myEvents, setMyEvents] = useState<EventType[]>([]);
  return (
    <div>
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {}}
        callback={async (contract: ethers.Contract) => {
          try {
            const res = await contract.listMyEvents();
            setMyEvents(listEventsMapper(res));
            setModalOpen(false);
          } catch (error) {
            console.log(error);
          }
        }}
      />
      {myEvents.map((event, index) => (
        <EventComponent key={index} event={event} />
      ))}
    </div>
  );
}
