// chatserver.js - Socket.IO chat server for room-and-roomie
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const pool = require('./config');
const cors = require('cors');

// Environment/config vars (customize as needed)
const PORT = process.env.CHAT_PORT || 4000;

const app = express();
app.use(cors());
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});


// Socket.IO event handlers
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Join chat room (room = sorted user ids, e.g. '1-2')
  socket.on('joinRoom', ({ userId, otherUserId }) => {
    const room = [userId, otherUserId].sort().join('-');
    socket.join(room);
    socket.room = room;
    socket.userId = userId;
    console.log(`User ${userId} joined room ${room}`);
  });

  // Send message
  socket.on('sendMessage', async ({ content, toUserId }) => {
    const fromUserId = socket.userId;
    const room = [fromUserId, toUserId].sort().join('-');
    // Save to DB
    try {
      const res = await pool.query(
        'INSERT INTO messages (contenu, expediteur_id, destinataire_id) VALUES ($1, $2, $3) RETURNING *',
        [content, fromUserId, toUserId]
      );
      const message = res.rows[0];
      io.to(room).emit('receiveMessage', {
        id: message.id,
        content: message.contenu,
        fromUserId: message.expediteur_id,
        toUserId: message.destinataire_id,
        date: message.date_envoi,
        read: message.lu
      });
    } catch (err) {
      console.error('DB error sending message:', err);
      socket.emit('error', 'Failed to send message');
    }
  });

  // Load chat history
  socket.on('loadHistory', async ({ userId, otherUserId }) => {
    try {
      const res = await pool.query(
        `SELECT * FROM messages WHERE (expediteur_id = $1 AND destinataire_id = $2) OR (expediteur_id = $2 AND destinataire_id = $1) ORDER BY date_envoi ASC`,
        [userId, otherUserId]
      );
      socket.emit('chatHistory', res.rows.map(msg => ({
        id: msg.id,
        content: msg.contenu,
        fromUserId: msg.expediteur_id,
        toUserId: msg.destinataire_id,
        date: msg.date_envoi,
        read: msg.lu
      })));
    } catch (err) {
      console.error('DB error loading history:', err);
      socket.emit('error', 'Failed to load chat history');
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// API: Get all messages between two users
app.get('/messages', async (req, res) => {
  const { user1, user2 } = req.query;
  if (!user1 || !user2) {
    return res.status(400).json({ error: 'Both user1 and user2 are required' });
  }
  try {
    const result = await pool.query(
      `SELECT * FROM messages
       WHERE (expediteur_id = $1 AND destinataire_id = $2)
          OR (expediteur_id = $2 AND destinataire_id = $1)
       ORDER BY date_envoi ASC`,
      [user1, user2]
    );
    res.json(result.rows.map(msg => ({
      id: msg.id,
      content: msg.contenu,
      fromUserId: msg.expediteur_id,
      toUserId: msg.destinataire_id,
      date: msg.date_envoi,
      read: msg.lu
    })));
  } catch (err) {
    console.error('DB error fetching messages:', err);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

// Health check endpoint
app.get('/', (req, res) => {
  res.send('Chat server is running.');
});

server.listen(PORT, () => {
  console.log(`Chat server listening on port ${PORT}`);
});
