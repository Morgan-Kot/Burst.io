function resolveBubbleProperties(x, y, r, isBomb, effLvl) {
    let color, type;

    if (isBomb) {
        color = "#222222";
        type = "bomb";
    } else {
        let colors = ["#e74c3c", "#3498db", "#2ecc71", "#f1c40f", "#9b59b6", "#1abc9c"];
        if (state.juniorMode) {
            colors = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff", "#00ffff", "#ff8800"];
        }
        color = colors[Math.floor(Math.random() * colors.length)];
        type = "bubble";
    }
    
    let lifetimeMod = Math.pow(1 - CONFIG.SPEED_SCALING_FACTOR, Math.floor((effLvl - 1) / 3));
    let lifetime = CONFIG.BUBBLE_LIFETIME_MS * lifetimeMod;
    
    if (state.testMode) lifetime *= CONFIG.TEST_MODE_MULTIPLIER;
    if (state.juniorMode) lifetime *= CONFIG.JUNIOR_MULTIPLIER;

    return { id: Math.random(), x, y, maxR: r, currentR: r, color, type, active: true, spawnTime: Date.now(), lifetime };
}