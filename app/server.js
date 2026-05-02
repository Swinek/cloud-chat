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
    console.log(`Succesful connection to Redis: ${redisUrl}`);
}).catch(err => {
    console.error('Failed connection to Redis', err);
});

const PORT = process.env.PORT || 3000;
const memoryLeakCollector = []; 

io.on('connection', (socket) => {
    socket.on('chat message', (msgData) => {
        memoryLeakCollector.push(Buffer.alloc(1024 * 1024, "x"));
        
        if (typeof msgData === 'string') {
            msgData = { text: msgData, isManual: true };
        }
        
        const messageWithPort = `${msgData.text}`;
        
        io.emit('chat message', { 
            text: messageWithPort, 
            isManual: msgData.isManual 
        });
    });
});

server.listen(PORT, () => console.log(`Chat server listening on port ${PORT}`));    