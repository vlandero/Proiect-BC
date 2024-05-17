import React from "react";
import ConnectAccountModal from "../../components/ConnectAccountModal";
import { ethers } from "ethers";

export default function Home() {
  const [modalOpen, setModalOpen] = React.useState(true);
  const [availableBalance, setAvailableBalance] = React.useState(0);
  const [canWithdraw, setCanWithdraw] = React.useState(false);
  const [withdrawModalOpen, setWithdrawModalOpen] = React.useState(false);
  const withdraw = async () => {
    setWithdrawModalOpen(true);
  };
  return (
    <div>
      <h1>Home</h1>
      <div>{availableBalance} ETH to withdraw</div>
      {canWithdraw && <button onClick={withdraw}>Withdraw</button>}
      <ConnectAccountModal
        isOpen={modalOpen}
        close={() => {
          setModalOpen(false);
        }}
        callback={async (contract: ethers.Contract) => {
          try {
            const res = await contract.getOwnerPendingWithdrawal();
            setAvailableBalance(Number(BigInt(res) / BigInt(10 ** 18)));
            setModalOpen(false);
            setCanWithdraw(true);
          } catch (err) {
            console.log(err);
          }
        }}
      ></ConnectAccountModal>

      <ConnectAccountModal
        isOpen={withdrawModalOpen}
        close={() => {
          setWithdrawModalOpen(false);
        }}
        callback={async (contract: ethers.Contract) => {
          try {
            const res = await contract.withdrawOwner();
            console.log(res);
            setWithdrawModalOpen(false);
            setAvailableBalance(0);
            setCanWithdraw(false);
          } catch (err) {
            console.log(err);
          }
        }}
      ></ConnectAccountModal>
    </div>
  );
}
