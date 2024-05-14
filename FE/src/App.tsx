import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Home from './pages/Home';
import AddEvent from './pages/AddEvent';
import Events from './pages/Events';
import Event from './pages/Event';
import MyTickets from './pages/MyTickets';
import MyEvents from './pages/MyEvents';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" Component={Home} />
          <Route path="/add-event" Component={AddEvent} />
          <Route path="/events" Component={Events} />
          <Route path="/event/:eventId" Component={Event} />
          <Route path="/my-tickets" Component={MyTickets} />
          <Route path="/my-events" Component={MyEvents} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
