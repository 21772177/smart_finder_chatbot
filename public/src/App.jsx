import { useState, useEffect, useRef } from 'react';
import { db } from '../firebase-config';
import { collection, addDoc, query, orderBy, onSnapshot } from 'firebase/firestore';
import app from '../firebase-config';
import './App.css';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [deviceToken, setDeviceToken] = useState('');
  const messagesEndRef = useRef(null);

  // Initialize device token
  useEffect(() => {
    let token = localStorage.getItem('sf_device_token');
    if (!token) {
      token = `device-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('sf_device_token', token);
    }
    setDeviceToken(token);
  }, []);

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMessage = {
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);

    try {
      // Get user's location if available
      let location = { lat: 12.9716, lng: 77.5946 }; // Default to Bangalore
      
      // Try to get user's location
      if (navigator.geolocation) {
        try {
          const position = await new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000 });
          });
          location = {
            lat: position.coords.latitude,
            lng: position.coords.longitude
          };
        } catch (error) {
          console.log('Location access denied or unavailable, using default');
        }
      }

      // Get Firebase function URL
      // For development with emulators: http://localhost:5001/PROJECT_ID/REGION/api/api/query
      // For production: https://REGION-PROJECT_ID.cloudfunctions.net/api/api/query
      const projectId = app.options.projectId || 'smart-finder-chatbot';
      const apiUrl = import.meta.env.DEV
        ? `http://localhost:5001/${projectId}/us-central1/api/api/query`
        : `https://us-central1-${projectId}.cloudfunctions.net/api/api/query`;

      // Call Firebase Function via HTTP
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query: input,
          location: location,
          token: deviceToken
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      const botMessage = {
        role: 'assistant',
        content: data.response || 'I received your message!',
        results: data.results || [],
        timestamp: new Date()
      };

      setMessages(prev => [...prev, botMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
        error: true,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setLoading(false);
    }
  };

  const renderResult = (result) => {
    if (result.platform === 'maps' || result.platform === 'zomato') {
      return (
        <div key={result.title} className="result-card">
          <h4>{result.title}</h4>
          <p>Rating: {result.rating} ⭐ | Distance: {result.distance_m}m</p>
          {result.open_now && <span className="badge">Open Now</span>}
          {result.url && (
            <a href={result.url} target="_blank" rel="noopener noreferrer" className="link">
              View on Map →
            </a>
          )}
        </div>
      );
    }
    if (result.platform === 'YouTube') {
      return (
        <div key={result.title} className="result-card">
          <img src={result.thumbnail} alt={result.title} className="thumbnail" />
          <h4>{result.title}</h4>
          <p>Date: {new Date(result.date).toLocaleDateString()}</p>
          <a href={result.url} target="_blank" rel="noopener noreferrer" className="link">
            Watch Video →
          </a>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="app">
      <div className="chat-container">
        <div className="chat-header">
          <h1>🤖 Smart Finder AI</h1>
          <p>Ask me about nearby places, past visits, or saved content!</p>
        </div>

        <div className="messages-container">
          {messages.length === 0 && (
            <div className="welcome-message">
              <p>👋 Welcome! I can help you:</p>
              <ul>
                <li>Find nearby restaurants and places</li>
                <li>Recall your past visits</li>
                <li>Search your saved social media content</li>
              </ul>
              <p>Try asking: "Where can we eat here North Indian?"</p>
            </div>
          )}

          {messages.map((msg, idx) => (
            <div key={idx} className={`message ${msg.role}`}>
              <div className="message-content">
                <div className="message-text">{msg.content}</div>
                {msg.results && msg.results.length > 0 && (
                  <div className="results">
                    {msg.results.map((result, i) => renderResult(result))}
                  </div>
                )}
                {msg.error && <div className="error">⚠️ {msg.content}</div>}
              </div>
            </div>
          ))}

          {loading && (
            <div className="message assistant">
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        <form onSubmit={sendMessage} className="input-form">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type your message..."
            className="input-field"
            disabled={loading}
          />
          <button type="submit" className="send-button" disabled={loading || !input.trim()}>
            Send
          </button>
        </form>
      </div>
    </div>
  );
}

export default App;

