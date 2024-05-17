import React, { useEffect, useState } from "react";
import Modal from "../Modal";
import { ethers } from "ethers";
import styles from "./index.module.css";
import ABI from "../../TicketMarket.json";
import { useNavigate } from "react-router-dom";

export const TICKET_CONTRACT_ADDRESS =
  "0x73511669fd4dE447feD18BB79bAFeAC93aB7F31f";
export const provider = new ethers.BrowserProvider(window.ethereum);

export default function ConnectAccountModal({
  isOpen,
  close,
  callback,
  children,
}: {
  isOpen: boolean;
  close: () => void;
  callback: (
    contract: ethers.Contract,
    signer: ethers.JsonRpcSigner
  ) => Promise<void>;
  children?: React.ReactNode;
}) {
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
        const ctr = new ethers.Contract(TICKET_CONTRACT_ADDRESS, ABI, account);
        callback(ctr, account);
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
      {children}
    </Modal>
  );
}
