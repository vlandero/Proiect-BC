import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import styles from "./home.module.css";
const provider = new ethers.BrowserProvider(window.ethereum);

export default function Home() {
  const [account, setAccount] = useState<ethers.JsonRpcSigner | null>(null);
  const [balance, setBalance] = useState<string | null>(null);
  const [errText, setErrText] = useState<string | null>(null);

  const getBalance = async () => {
    if (account) {
      const balance = await provider.getBalance(account.getAddress());
      setBalance(balance.toString());
    }
  };

  useEffect(() => {
    getBalance();
  }, [account]);

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
  return (
    <div>
      <div>{account?.address}</div>
      <button onClick={connectWallet}>Connect Wallet</button>
      <div>
        To disconnect, just remove the website from your metamask extension and
        refresh the page.
      </div>
      <div>{balance}</div>
      <div className={styles["err"]}>{errText}</div>
    </div>
  );
}
