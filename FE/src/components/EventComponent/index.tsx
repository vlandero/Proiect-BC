import { useNavigate } from "react-router-dom";
import { EventType } from "../../utils/types";
import styles from "./index.module.css";

export function EventComponent({ event }: { event: EventType }) {
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