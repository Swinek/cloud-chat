const { io } = require("socket.io-client");

const URL = "http://79.76.59.232/"; 
const USERS_COUNT = 50; // Number of simulated users
const MESSAGES_PER_SECOND = 10; // Messages per second per user

for (let i = 0; i < USERS_COUNT; i++) {
    const socket = io(URL);
    const username = `Bot_${i}`;

    socket.on("connect", () => {
        setInterval(() => {
            socket.emit("chat message", `[StressTest] Message from ${username} - ${new Date().toISOString()}`);
        }, 1000 / MESSAGES_PER_SECOND);
    });

    socket.on("connect_error", (err) => {
        console.error(`Error for bot ${username}:`, err.message);
    });
}