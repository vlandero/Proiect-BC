import React, { useEffect, useState } from "react";
import Modal from "../Modal";
import { ethers } from "ethers";
import styles from "./index.module.css";
import ABI from "../../TicketMarket.json";
import { listEventsMapper } from "../../utils/mappers";

const TICKET_CONTRACT_ADDRESS = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";

export default function ConnectAccountModal({
  isOpen,
  close,
}: {
  isOpen: boolean;
  close: () => void;
}) {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const [account, setAccount] = useState<ethers.JsonRpcSigner | null>(null);
  const [errText, setErrText] = useState<string | null>(null);

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const accountSign = await provider.send("eth_requestAccounts", []);
        const account = await provider.getSigner(accountSign[0]);
        await provider.getBalance(account.getAddress());
        setAccount(account);
        setErrText(null);
      } catch (err) {
        console.log(err);
        setErrText("Please allow the connection to proceed.");
      }
    } else {
      setErrText("Please install a wallet extension.");
    }
  };

  const testCtr = async () => {
    if (account) {
      try {
        const ctr = new ethers.Contract(
          TICKET_CONTRACT_ADDRESS,
          ABI,
          account
        );
        const res = await ctr.listEvents();
        console.log(listEventsMapper(res));
      } catch (e) {
        console.log(e);
      }
    }
  };

  if (!isOpen) return null;
  return (
    <Modal isOpen={isOpen} close={close}>
      <div>
        <div>{account?.address}</div>
        <button onClick={connectWallet}>Connect Wallet</button>
        <div>
          To disconnect, just remove the website from your metamask extension
          and refresh the page.
        </div>
        <div className={styles["err"]}>{errText}</div>
      </div>
      <button onClick={testCtr}>OK</button>
    </Modal>
  );
}
