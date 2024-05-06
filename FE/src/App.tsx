import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';

import { ethers } from 'ethers';
import Home from './pages/Home';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" Component={Home} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
