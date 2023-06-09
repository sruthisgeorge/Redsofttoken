import React, { useEffect, useState } from 'react';
import Web3 from 'web3';
import MyTokenABI from './MyToken.json';

const CONTRACT_ADDRESS = 'CONTRACT_ADDRESS';

function App() {
  const [web3, setWeb3] = useState(null);
  const [contract, setContract] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [amount, setAmount] = useState('');

  useEffect(() => {
    loadWeb3();
    loadContract();
  }, []);

  const loadWeb3 = async () => {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      await window.ethereum.enable();
      setWeb3(window.web3);
      setAccounts(await window.web3.eth.getAccounts());
    } else {
      alert('Please install MetaMask to use this application.');
    }
  };

  const loadContract = async () => {
    try {
      const networkId = await web3.eth.net.getId();
      const contractData = MyTokenABI.networks[networkId];
      if (contractData) {
        const contract = new web3.eth.Contract(MyTokenABI.abi, contractData.address);
        setContract(contract);
      } else {
        console.error('Contract not deployed on the current network.');
      }
    } catch (error) {
      console.error('Error loading contract:', error);
    }
  };

  const stake = async () => {
    try {
      await contract.methods.stake(amount).send({ from: accounts[0] });
      setAmount('');
    } catch (error) {
      console.error('Stake error:', error);
    }
  };

  const unstake = async () => {
    try {
      await contract.methods.unstake().send({ from: accounts[0] });
    } catch (error) {
      console.error('Unstake error:', error);
    }
  };

  const distributeRewards = async () => {
    try {
      await contract.methods.distributeRewards().send({ from: accounts[0] });
    } catch (error) {
      console.error('Distribute rewards error:', error);
    }
  };

  return (
    <div>
      <h1>MyToken Staking</h1>
      
      <div>
        <label htmlFor="amountInput">Amount:</label>
        <input
          type="number"
          id="amountInput"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
        <button onClick={stake}>Stake</button>
      </div>
      
      <div>
        <button onClick={unstake}>Unstake</button>
      </div>
      
      <div>
        <button onClick={distributeRewards}>Distribute Rewards</button>
      </div>
    </div>
  );
}

export default App;
