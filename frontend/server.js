async function getMetrics() {
    const response = await fetch("/api/metrics");
    if (!response.ok) {
        throw new Error("Failed to retrieve metrics");
    }
    return await response.json();
}
async function updateDashboard() {
    try {
        const metrics = await getMetrics();
        const c = document.getElementById("cpu-usage");
        const r = document.getElementById("ram-usage");
        const g = document.getElementById("gpu-usage");
        if (c) {
            c.textContent = metrics.cpu.usage_percent.toFixed(1);
        }
        if (r) {
            r.textContent = metrics.memory.used_percent.toFixed(1);
        }
        if (g) {
            if (metrics.gpu.usage_percent !== null) {
                g.textContent = metrics.gpu.usage_percent.toFixed(1);
            }
            else {
                g.textContent = "N/A";
            }
        }
    }
    catch (error) {
        console.error("Failed to update dashboard: ", error);
    }
}
updateDashboard();
setInterval(updateDashboard, 1000);
export {};
//# sourceMappingURL=server.js.map