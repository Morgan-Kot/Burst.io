// --- NORMAL MODE REGISTRY ---
Modes.normal = {
    spawnDelayMult: 1.0,
    lifetimeMult: 1.0,
    sizeMinMult: 1.0,
    sizeMaxMult: 1.0,
    radiusMult: 1.0,
    bombOddsMult: 1.0,
    getSpawns: () => (Math.floor(Math.random() * CONFIG.DOUBLE_SPAWN_ODDS) === 0) ? 2 : 1,
    colors: ["#e74c3c", "#3498db", "#2ecc71", "#f1c40f", "#9b59b6", "#ecf0f1"]
};

// --- CORE ENGINE ---
function resizeCanvas() {
    canvas.width = container.clientWidth;
    canvas.height = container.clientHeight;
}
window.addEventListener('resize', resizeCanvas);
resizeCanvas();

document.getElementById('high-score-display').innerText = `High Score: ${state.highScore}`;
document.getElementById('last-score-display').innerText = `Last Score: ${state.lastScore}`;

function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
    document.getElementById('hud').classList.add('hidden');
    if(screenId) document.getElementById(screenId).classList.remove('hidden');
}

function toggleAudio() {
    state.audio = !state.audio;
    document.getElementById('btn-audio').innerText = `AUDIO: ${state.audio ? 'ON' : 'OFF'}`;
}

function toggleHaptics() {
    state.haptics = !state.haptics;
    document.getElementById('btn-haptic').innerText = `VIBRATION: ${state.haptics ? 'ON' : 'OFF'}`;
}

function startGame(mode = 'normal') {
    state.currentMode = mode;
    state.score = 0;
    state.level = 1;
    state.popsThisLevel = 0;
    state.timeLeft = CONFIG.STARTING_TIME;
    state.isRunning = true;
    state.bubbles = [];
    state.particles = [];
    
    clearTimers();
    updateHUD();
    showScreen(''); 
    document.getElementById('hud').classList.remove('hidden');
    
    gameLoop();
    timerLoop();
    render();
}

function gameOver() {
    state.isRunning = false;
    clearTimers();
    
    state.lastScore = state.score;
    localStorage.setItem("burstLastScore", state.lastScore);
    
    if (state.score > state.highScore) {
        state.highScore = state.score;
        localStorage.setItem("burstHighScore", state.highScore);
    }
    
    document.getElementById('final-score').innerText = `Final Score: ${state.score}`;
    document.getElementById('final-level').innerText = `Level Reached: ${state.level}`;
    document.getElementById('high-score-display').innerText = `High Score: ${state.highScore}`;
    document.getElementById('last-score-display').innerText = `Last Score: ${state.lastScore}`;
    
    showScreen('game-over-screen');
}

function clearTimers() {
    state.timers.forEach(t => clearTimeout(t));
    state.timers = [];
}

function getRequiredPops() {
    let effLvl = Math.min(state.level, CONFIG.MAX_DIFFICULTY_LEVEL);
    return 10 + Math.floor((effLvl - 1) / 5);
}

function getSpawnSpeed() {
    let effLvl = Math.min(state.level, CONFIG.MAX_DIFFICULTY_LEVEL);
    let speedSteps = Math.floor((effLvl - 1) / 3);
    let modifier = Math.pow(1 - CONFIG.SPEED_SCALING_FACTOR, speedSteps);
    let modeParams = Modes[state.currentMode] || Modes.normal;
    
    let delay = (Math.random() * (CONFIG.SPAWN_DELAY_MAX - CONFIG.SPAWN_DELAY_MIN) + CONFIG.SPAWN_DELAY_MIN) * modifier * modeParams.spawnDelayMult;
    
    if (state.testMode) delay *= CONFIG.TEST_MODE_MULTIPLIER;
    if (state.juniorMode) delay *= CONFIG.JUNIOR_MULTIPLIER;
    return delay * 1000;
}

function checkOverlap(x, y, r) {
    for (let b of state.bubbles) {
        let dist = Math.sqrt(Math.pow(x - b.x, 2) + Math.pow(y - b.y, 2));
        if (dist < (r + b.maxR + 10)) return true;
    }
    return false;
}

function gameLoop() {
    if (!state.isRunning) return;
    
    let modeParams = Modes[state.currentMode] || Modes.normal;
    let spawns = modeParams.getSpawns();
    let screenScale = canvas.width / 360; 
    
    for (let s = 0; s < spawns; s++) {
        for (let attempt = 0; attempt < 50; attempt++) {
            let scaledMin = CONFIG.MIN_BUBBLE_SIZE * screenScale * modeParams.sizeMinMult;
            let scaledMax = CONFIG.MAX_BUBBLE_SIZE * screenScale * modeParams.sizeMaxMult;
            let r = Math.random() * (scaledMax - scaledMin) + scaledMin;
            
            r *= modeParams.radiusMult;
            if (state.juniorMode) r *= 2.0;

            let x = Math.random() * (canvas.width - r * 2) + r;
            let y = Math.random() * (canvas.height - 40 - r * 2) + r + 40; 
            
            if (!checkOverlap(x, y, r)) {
                let currentBombOdds = Math.floor(CONFIG.BOMB_ODDS * modeParams.bombOddsMult);
                let isBomb = Math.floor(Math.random() * currentBombOdds) === 0;
                let effLvl = Math.min(state.level, CONFIG.MAX_DIFFICULTY_LEVEL);
                state.bubbles.push(resolveBubbleProperties(x, y, r, isBomb, effLvl));
                break;
            }
        }
    }
    
    let delay = getSpawnSpeed();
    state.timers.push(setTimeout(gameLoop, delay));
}

function createParticles(x, y, color) {
    let screenScale = canvas.width / 360;
    for (let i = 0; i < 10; i++) {
        state.particles.push({
            x, y,
            vx: (Math.random() - 0.5) * 12 * screenScale,
            vy: (Math.random() - 0.5) * 12 * screenScale,
            life: 1.0,
            color
        });
    }
}

function timerLoop() {
    if (!state.isRunning) return;
    
    let dec = 0.1;
    if (state.testMode) dec /= CONFIG.TEST_MODE_MULTIPLIER;
    if (state.juniorMode) dec /= CONFIG.JUNIOR_MULTIPLIER;
    
    state.timeLeft -= dec;
    
    if (state.timeLeft <= 0) {
        state.timeLeft = 0;
        updateHUD();
        gameOver();
    } else {
        updateHUD();
        state.timers.push(setTimeout(timerLoop, 100));
    }
}

function updateHUD() {
    document.getElementById('hud-score').innerText = `Score: ${state.score}`;
    document.getElementById('hud-timer').innerText = `Time: ${state.timeLeft.toFixed(1)}s`;
    document.getElementById('hud-popcoins').innerText = `Popcoins: ${state.popcoins}`;
    document.getElementById('hud-level').innerText = `Lvl: ${state.level} (${state.popsThisLevel}/${getRequiredPops()})`;
}

function render() {
    if (!state.isRunning) return;
    
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    let now = Date.now();
    
    for (let i = state.bubbles.length - 1; i >= 0; i--) {
        let b = state.bubbles[i];
        let elapsed = now - b.spawnTime;
        let timeRemaining = b.lifetime - elapsed;
        let shrinkWindow = 150; 
        
        if (elapsed >= b.lifetime) {
            b.active = false;
        } else if (timeRemaining <= shrinkWindow) {
            b.currentR = b.maxR * (timeRemaining / shrinkWindow);
        } else {
            b.currentR = b.maxR;
        }
    }
    
    state.bubbles = state.bubbles.filter(b => b.active);
    
    for (let b of state.bubbles) {
        ctx.save();
        if (b.type === "bubble" && skinImages[state.equippedSkin] && skinImages[state.equippedSkin].complete) {
            ctx.beginPath();
            ctx.arc(b.x, b.y, Math.max(0, b.currentR), 0, Math.PI * 2);
            ctx.clip();
            ctx.drawImage(skinImages[state.equippedSkin], b.x - b.currentR, b.y - b.currentR, b.currentR * 2, b.currentR * 2);
            ctx.closePath();
            
            ctx.restore();
            ctx.beginPath();
            ctx.arc(b.x, b.y, Math.max(0, b.currentR), 0, Math.PI * 2);
            ctx.lineWidth = 3;
            ctx.strokeStyle = "#ffffff";
            ctx.stroke();
            ctx.closePath();
        } else {
            ctx.beginPath();
            ctx.arc(b.x, b.y, Math.max(0, b.currentR), 0, Math.PI * 2);
            ctx.fillStyle = b.color;
            ctx.fill();
            ctx.lineWidth = 3;
            ctx.strokeStyle = b.type === "bomb" ? "#e74c3c" : "#ffffff";
            ctx.stroke();
            ctx.closePath();

            if (b.type === "bomb") {
                ctx.fillStyle = "#e74c3c";
                ctx.font = `bold ${b.currentR}px Helvetica`;
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText("!", b.x, b.y);
            }
            ctx.restore();
        }
    }

    let screenScale = canvas.width / 360;
    for (let i = state.particles.length - 1; i >= 0; i--) {
        let p = state.particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.05;
        
        if (p.life <= 0) {
            state.particles.splice(i, 1);
            continue;
        }
        
        ctx.beginPath();
        ctx.arc(p.x, p.y, (4 * screenScale) * p.life, 0, Math.PI * 2);
        ctx.fillStyle = p.color;
        ctx.globalAlpha = p.life;
        ctx.fill();
        ctx.closePath();
        ctx.globalAlpha = 1.0;
    }
    
    requestAnimationFrame(render);
}

canvas.addEventListener('pointerdown', (e) => {
    if (!state.isRunning) return;
    
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    const x = (e.clientX - rect.left) * scaleX;
    const y = (e.clientY - rect.top) * scaleY;
    
    for (let i = state.bubbles.length - 1; i >= 0; i--) {
        let b = state.bubbles[i];
        let dist = Math.sqrt(Math.pow(x - b.x, 2) + Math.pow(y - b.y, 2));
        
        if (dist <= b.currentR && b.active) { 
            b.active = false; 
            createParticles(b.x, b.y, b.color);
            
            if (b.type === "bomb") {
                state.score = Math.max(0, state.score - CONFIG.BOMB_PENALTY);
                playBombSound();
                if (state.haptics && "vibrate" in navigator) {
                    navigator.vibrate(CONFIG.BOMB_VIBRATION);
                }
            } else {
                playPopSound();
                if (state.haptics && "vibrate" in navigator) {
                    navigator.vibrate(CONFIG.VIBRATION_PATTERN);
                }
                
                state.score++; 
                state.popsThisLevel++;
                state.timeLeft = CONFIG.STARTING_TIME; 
                
                if (state.popsThisLevel >= getRequiredPops()) {
                    state.level++;
                    state.popsThisLevel = 0;

                    // Dynamically calculates payout using your new CONFIG variables
                    if (state.level % CONFIG.POPCOIN_LEVEL_INTERVAL === 0) {
                        let basePayout = CONFIG.POPCOIN_BASE_PAYOUT;
                        if (state.level > 25) basePayout *= 2;
                        if (state.currentMode === 'chaos') basePayout *= 3;
                        
                        state.popcoins += basePayout;
                        localStorage.setItem("burstPopcoins", state.popcoins);
                    }
                }
            }
            
            updateHUD(); 
            break; 
        }
    }
});

// This is for debugging and version control
// DO NOT EDIT, DELETE, MOVE, ETC.
console.log("debug-log")
console.log("Build: e1.000.2")
console.log("Changed: Nothing")
console.log("Developer note: Nothing")












