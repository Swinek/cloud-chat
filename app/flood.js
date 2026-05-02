const { io } = require("socket.io-client");

    const URL = "http://51.107.187.155/";
const USERS_COUNT = 5
const MESSAGES_PER_SECOND = 3;


for (let i = 0; i < USERS_COUNT; i++) {
    const socket = io(URL, {
        transports: ['websocket']
    });
    
    const username = `Bot_${i}`;

    socket.on("connect", () => {
    setInterval(() => {
        const payload = {
            text: `[StressTest] Message from ${username} - ${new Date().toISOString()}`,
            isManual: false
        };
        socket.emit("chat message", payload);
    }, 1000 / MESSAGES_PER_SECOND);
});

    socket.on("connect_error", (err) => {
        console.error(`Error for bot ${username}:`, err.message);
    });
}

setTimeout(() => {
    process.exit(0);
}, 60000);   