import React, { useState } from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";
import { listEventsMapper } from "../../utils/mappers";
import { EventType } from "../../utils/types";
import styles from "./index.module.css";
import { useNavigate } from "react-router-dom";

function EventComponent({ event }: { event: EventType }) {
  const navigate = useNavigate();
  const eventClick = () => {
    navigate(`/event/${event.id}`);
  };
  return (
    <div onClick={eventClick} className={styles["event-comp"]}>
      <h2>{event.name}</h2>
      <p>Description: {event.description}</p>
      <p>Start Date: {event.dateStart}</p>
      <p>End Date: {event.dateEnd}</p>
      <p>Creator: {event.creator}</p>
    </div>
  );
}

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
