const net = require("net");
const express = require("express");
const path = require("path");
const https = require("https");
const fs = require("fs");

let metrics = {};

const tcpServer = net.createServer((socket) => {
	console.log("Server Connected to C++!");

	let buffer = "";

	socket.on("data", (data) => {
		buffer += data.toString();

		let messages = buffer.split("\n");

		//Leave inomplete messagesd to next packet
		buffer = messages.pop();

		for (const message of messages) {
			if (message.trim() === "") {
				continue;
			}

			try {
				const parsed = JSON.parse(message);

				metrics = parsed;

				console.log("Metrics updated:");
				console.log(metrics);
			} catch (error) {
				console.error("Failed to parse JSON", error);
				console.log("Received:",message);
			}
		}
	});

	socket.on("error", (error) => {
		console.error("TCP connection error:", error);
	});

	socket.on("close", () => {
		console.log("C++ disconnected");
	});
});

tcpServer.listen(5002, "0.0.0.0", () => {
	console.log("TCP server listening on port 5002");
});

const app = express();

const PORT = 3000;

const httpsOptions = {
	key: fs.readFileSync(
		path.join(__dirname, "certs", "gamedata.home.arpa-key.pem")
	),
	cert: fs.readFileSync(
		path.join(__dirname, "certs", "gamedata.home.arpa.pem")
	)
};

app.use(express.static(path.join(__dirname, "frontend")));

app.get("/", (req,res) => {
	res.send("Server connected!");
});

app.get("/api/metrics", (req,res) => {
	res.json(metrics);
});

https.createServer(httpsOptions, app).listen(PORT, "0.0.0.0", () => {
	console.log(`HTTPS server listening on port ${PORT}`);
});
