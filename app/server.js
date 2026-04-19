const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { createClient } = require('redis');
const { createAdapter } = require('@socket.io/redis-adapter');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.get('/', (req, res) => res.sendFile(__dirname + '/index.html'));

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
const pubClient = createClient({ url: redisUrl });
const subClient = pubClient.duplicate();

Promise.all([pubClient.connect(), subClient.connect()]).then(() => {
    io.adapter(createAdapter(pubClient, subClient));
});
const PORT = process.env.PORT || 3000;

io.on('connection', (socket) => {
    socket.on('chat message', (msg) => {
        const messageWithPort = `[Server ${PORT}] ${msg}`;
        io.emit('chat message', messageWithPort);
    });
});
server.listen(PORT, () => console.log(`Chat server listening on port ${PORT}`));