const CONFIG = {
    STARTING_TIME: 2.5,
    MIN_BUBBLE_SIZE: 36,
    MAX_BUBBLE_SIZE: 68,
    SPAWN_DELAY_MIN: 0.32,
    SPAWN_DELAY_MAX: 1,
    DOUBLE_SPAWN_ODDS: 20,
    BUBBLE_LIFETIME_MS: 1800, 
    MAX_DIFFICULTY_LEVEL: 25,
    SPEED_SCALING_FACTOR: 0.30, 
    POPCOIN_LEVEL_INTERVAL: 1,
    POPCOIN_BASE_PAYOUT: 2,
    VIBRATION_PATTERN: [45, 60, 20],
    BOMB_VIBRATION: [200, 100, 200, 100, 200],
    BOMB_ODDS: 17,
    BOMB_PENALTY: 10,
    coins_flytime: 40000, 
    coin_value: 1,
    coin_size: 120
};

let state = {
    audio: true,
    haptics: true,
    testMode: false,
    juniorMode: false,
    currentMode: 'normal',
    highScore: localStorage.getItem("burstHighScore") || 0,
    lastScore: localStorage.getItem("burstLastScore") || 0,
    popcoins: parseInt(localStorage.getItem("burstPopcoins")) || 0,
    unlockedSkins: JSON.parse(localStorage.getItem("burstUnlockedSkins")) || ["classic_default"],
    equippedSkin: localStorage.getItem("burstEquippedSkin") || "classic_default",
    score: 0,
    level: 1,
    popsThisLevel: 0,
    timeLeft: CONFIG.STARTING_TIME,
    isRunning: false,
    bubbles: [],
    particles: [],
    timers: [],
    coins: [] 
};

let skinImages = {};
const Modes = {}; 
const coinImage = new Image();
coinImage.src = 'assets/resources/popcoin.png'; 

const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');
const container = document.getElementById('game-container');

console.log("UPDATED COIN SIZE")
// Variables.js Version: v1.1 | ADDED_FLYING_POPCOIN_VARIABLES_AND_IMAGE_PRELOADER
