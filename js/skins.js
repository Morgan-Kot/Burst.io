async function initShop() {
    try {
        const response = await fetch('data/skins.json');
        const skinsData = await response.json();
        
        skinsData.forEach(skin => {
            if (skin.imagePath && !skinImages[skin.id]) {
                const img = new Image();
                img.src = skin.imagePath;
                skinImages[skin.id] = img;
            }
        });

        renderShop(skinsData);
    } catch (error) {
        console.error("Error loading pop-shop:", error);
    }
}

function renderShop(skinsData) {
    document.getElementById('shop-balance').innerText = `Popcoins: ${state.popcoins}`;
    const container = document.getElementById('shop-items-container');
    container.innerHTML = '';

    skinsData.forEach(skin => {
        const isUnlocked = state.unlockedSkins.includes(skin.id);
        const isEquipped = state.equippedSkin === skin.id;
        
        const itemEl = document.createElement('div');
        itemEl.className = `shop-item ${isEquipped ? 'equipped' : ''}`;
        const previewHTML = skin.imagePath ? 
            `<img src="${skin.imagePath}" alt="${skin.name}">` : 
            `<div class="shop-circle-preview" style="background: #5e2ced;"></div>`;

        let actionBtnHTML = '';
        if (isEquipped) {
            actionBtnHTML = `<button class="shop-btn" style="background: #394557; color: #fff;" disabled>Equipped</button>`;
        } else if (isUnlocked) {
            actionBtnHTML = `<button class="shop-btn" style="background: #2980b9; color: #fff;" onclick="equipSkin('${skin.id}')">Equip</button>`;
        } else {
            actionBtnHTML = `<button class="shop-btn" style="background: #394557; color: #f1c40f;" onclick="buySkin('${skin.id}', ${skin.cost})">${skin.cost} POPCOINS</button>`;
        }

        itemEl.innerHTML = `
            ${previewHTML}
            ${actionBtnHTML}
        `;
        container.appendChild(itemEl);
    });
}

function equipSkin(id) {
    state.equippedSkin = id;
    localStorage.setItem("burstEquippedSkin", id);
    initShop();
}

function buySkin(id, cost) {
    if (state.popcoins >= cost) {
        state.popcoins -= cost;
        state.unlockedSkins.push(id);
        localStorage.setItem("burstPopcoins", state.popcoins);
        localStorage.setItem("burstUnlockedSkins", JSON.stringify(state.unlockedSkins));
        initShop();
        updateHUD();
    } else {
        alert("Not enough Popcoins!");
    }
}

const nativeShowScreen = showScreen;
showScreen = function(screenId) {
    if (screenId === 'shop-screen') {
        initShop();
    }
    nativeShowScreen(screenId);
};

initShop();

//debugging and version control
//every change made in this file has to be documented in the changelog
console.log("-- skins.js changelog --")
console.log("Changed: nothing")
console.log("Developer notes: nothing")
