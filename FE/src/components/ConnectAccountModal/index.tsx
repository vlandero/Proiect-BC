import React, { useEffect, useState } from "react";
import Modal from "../Modal";
import { ethers } from "ethers";
import styles from "./index.module.css";
import ABI from "../../TicketMarket.json";

export const TICKET_CONTRACT_ADDRESS =
  "0x5095d3313C76E8d29163e40a0223A5816a8037D8";
export const provider = new ethers.BrowserProvider(window.ethereum);

export default function ConnectAccountModal({
  isOpen,
  close,
  callback,
  showEstimatedGas,
  children,
}: {
  isOpen: boolean;
  close: () => void;
  callback: (
    contract: ethers.Contract,
    signer: ethers.JsonRpcSigner,
    maxGas: number
  ) => Promise<void>;
  showEstimatedGas?: boolean;
  children?: React.ReactNode;
}) {
  const [account, setAccount] = useState<ethers.JsonRpcSigner | null>(null);
  const [errText, setErrText] = useState<string | null>(null);
  const [desiredGas, setDesiredGas] = useState<number>(1000000);

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
        callback(ctr, account, desiredGas);
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
        <div style={{
          display: showEstimatedGas ? "block" : "none",
        }}>
          <label>Desired maximum Gas</label>
          <input
            type="number"
            value={desiredGas}
            style={{marginLeft: "10px"}}
            onChange={(e) => setDesiredGas(parseInt(e.target.value))}
          />
        </div>
        <div className={styles["err"]}>{errText}</div>
      </div>
      <button onClick={testCtr}>OK</button>
      {children}
    </Modal>
  );
}
