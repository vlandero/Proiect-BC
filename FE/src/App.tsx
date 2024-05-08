import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';

import { ethers } from 'ethers';
import Home from './pages/Home';
import AddEvent from './pages/AddEvent';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" Component={Home} />
          <Route path="/add-event" Component={AddEvent} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
