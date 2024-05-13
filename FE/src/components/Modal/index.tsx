import React from "react";
import styles from "./index.module.css";

export default function Modal({
  isOpen,
  close,
  children,
}: {
  isOpen: boolean;
  close: () => void;
  children?: React.ReactNode;
}) {
  if (!isOpen) return null;

  return (
    <div className={styles["modal-overlay"]} onClick={close}>
      <div
        className={styles["modal-content"]}
        onClick={(e) => e.stopPropagation()}
      >
        {children}
        <button className={styles["close-button"]} onClick={close}>
          Close
        </button>
      </div>
    </div>
  );
}
