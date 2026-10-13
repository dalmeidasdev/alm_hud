// A página só desenha o que o Lua manda. Não há regra nem dado sensível aqui:
// este arquivo não é protegido pelo Escrow e o jogador pode alterá-lo.

// Os nós do HUD são fixos: cada seletor é procurado na página uma vez só
const nodes = {};
const $ = (selector) => nodes[selector] || (nodes[selector] = document.querySelector(selector));

let currency = { symbol: "$", thousands: "," };
let shown = false;
let paused = false;
let L = {};
let maxSpeed = 240;
let beltKnown = false;
let belt = false;
let noBelt = false; // veículo sem cinto (moto, bicicleta, barco)
const SWEEP = 270; // o mostrador ocupa três quartos do círculo, em graus
const SVG_NS = "http://www.w3.org/2000/svg";
const HEX = /^#[0-9a-f]{6}$/i;
const RGB_KEYS = ["accent", "background", "text"]; // cores que o CSS também usa com transparência
const lastMoney = { cash: null, bank: null };
const lastDrive = { speed: null, gear: null, edge: null, blink: null };

const clamp = (value, min, max) => Math.min(max, Math.max(min, Number(value) || 0));

function formatMoney(value) {
    const digits = String(Math.floor(Math.abs(Number(value) || 0)));
    return `${currency.symbol} ${digits.replace(/\B(?=(\d{3})+(?!\d))/g, currency.thousands)}`;
}

function updateVisibility() {
    $("#hud").classList.toggle("hidden", !shown || paused);
}

// ───────── tema e partes ligadas no config ─────────

function applyTheme(theme = {}) {
    const root = document.documentElement.style;
    for (const [key, value] of Object.entries(theme)) {
        if (typeof value !== "string" || !HEX.test(value)) continue;
        root.setProperty(`--${key}`, value);
        if (RGB_KEYS.includes(key)) {
            const n = parseInt(value.slice(1), 16);
            root.setProperty(`--${key}-rgb`, `${n >> 16}, ${(n >> 8) & 255}, ${n & 255}`);
        }
    }
}

function applyParts(show = {}) {
    for (const el of document.querySelectorAll("[data-part]")) {
        el.classList.toggle("off", show[el.dataset.part] === false);
    }
}

// ───────── escalas dos mostradores ─────────

const SPEEDO = { cx: 222, cy: 104 };
const TACH = { cx: 72, cy: 128, max: 8, red: 6.5 };

/** Ponto de um mostrador: `ratio` de 0 a 1 ao longo do arco, `radius` a partir do centro */
function dialPoint(dial, ratio, radius) {
    const angle = ((-135 + ratio * SWEEP) * Math.PI) / 180;
    return [dial.cx + radius * Math.sin(angle), dial.cy - radius * Math.cos(angle)];
}

function tick(group, dial, ratio, inner, outer, className) {
    const [x1, y1] = dialPoint(dial, ratio, inner);
    const [x2, y2] = dialPoint(dial, ratio, outer);
    const line = document.createElementNS(SVG_NS, "line");
    line.setAttribute("x1", x1.toFixed(1));
    line.setAttribute("y1", y1.toFixed(1));
    line.setAttribute("x2", x2.toFixed(1));
    line.setAttribute("y2", y2.toFixed(1));
    line.setAttribute("class", className);
    group.append(line);
}

function tickLabel(group, dial, ratio, radius, value, className) {
    const [x, y] = dialPoint(dial, ratio, radius);
    const text = document.createElementNS(SVG_NS, "text");
    text.setAttribute("x", x.toFixed(1));
    text.setAttribute("y", y.toFixed(1));
    text.setAttribute("class", className);
    text.textContent = value;
    group.append(text);
}

function buildTicks() {
    const speedGroup = $("#dial-ticks");
    speedGroup.replaceChildren();
    for (let speed = 0; speed <= maxSpeed; speed += 10) {
        const ratio = speed / maxSpeed;
        const major = speed % 20 === 0;
        tick(speedGroup, SPEEDO, ratio, major ? 78 : 83, 89, major ? "tick major" : "tick");
        if (major) tickLabel(speedGroup, SPEEDO, ratio, 66, speed, "tick-label");
    }

    const rpmGroup = $("#rpm-ticks");
    rpmGroup.replaceChildren();
    for (let half = 0; half <= TACH.max * 2; half++) {
        const value = half / 2;
        const ratio = value / TACH.max;
        const major = half % 2 === 0;
        const red = value >= TACH.red;
        tick(rpmGroup, TACH, ratio, major ? 50 : 54, 59, `tick${major ? " major" : ""}${red ? " red" : ""}`);
        if (major) tickLabel(rpmGroup, TACH, ratio, 41, value, `tick-label small${red ? " red" : ""}`);
    }
    // faixa vermelha do giro
    const [x1, y1] = dialPoint(TACH, TACH.red / TACH.max, 61);
    const [x2, y2] = dialPoint(TACH, 1, 61);
    $("#rpm-red").setAttribute("d", `M${x1.toFixed(1)} ${y1.toFixed(1)} A61 61 0 0 1 ${x2.toFixed(1)} ${y2.toFixed(1)}`);
}

// ───────── mensagens ─────────

function show(data) {
    L = data.locale || {};
    if (data.currency) currency = data.currency;
    maxSpeed = Number(data.maxSpeed) > 0 ? Number(data.maxSpeed) : maxSpeed;
    applyTheme(data.theme);
    applyParts(data.show);
    buildTicks();
    $("#server-name").textContent = data.serverName || "";
    if (!data.serverName) $("#server-name").classList.add("off");
    $("#label-id").textContent = L.id || "";
    $("#player-id").textContent = data.id;
    $("#label-speed").textContent = L[data.speedUnit] || "";
    $("#label-cash").textContent = L.cash || "";
    $("#label-bank").textContent = L.bank || "";
    shown = true;
    updateVisibility();
}

/** Anel de status: valor de 0 a 100; `warn` e `low` são os limites de aviso */
function setVital(name, value, warn, low) {
    const amount = clamp(value, 0, 100);
    const node = $(`#v-${name}`);
    $(`#v-${name} .ring-fg`).style.strokeDasharray = `${amount} 100`;
    node.classList.toggle("warn", amount <= warn && amount > low);
    node.classList.toggle("low", amount <= low);
    $(`#v-${name} em`).textContent = Math.round(amount);
    return amount;
}

/** Fome e sede: o anel só existe se o framework informa o valor */
function setNeed(name, value) {
    const known = typeof value === "number";
    $(`#v-${name}`).classList.toggle("hidden", !known);
    if (known) setVital(name, value, 40, 20);
}

function setFuel(value) {
    const known = typeof value === "number";
    $("#fuel-box").classList.toggle("hidden", !known);
    if (!known) return;
    const fuel = clamp(value, 0, 100);
    $("#fuel").style.transform = `scaleX(${fuel / 100})`;
    $("#fuel-value").textContent = `${Math.round(fuel)}%`;
    $("#fuel-box").classList.toggle("low", fuel <= 15);
}

function setStatus(data) {
    setVital("health", data.health, 50, 25);
    const armor = setVital("armor", data.armor, -1, -1);
    $("#v-armor").classList.toggle("hidden", armor <= 0);

    // fôlego e ar só aparecem quando importam
    const stamina = setVital("stamina", data.stamina, 40, 15);
    $("#v-stamina").classList.toggle("hidden", stamina >= 95);
    const underwater = Number(data.oxygen) >= 0;
    $("#v-oxygen").classList.toggle("hidden", !underwater);
    if (underwater) setVital("oxygen", data.oxygen, 50, 25);

    $("#v-voice").classList.toggle("talking", Boolean(data.talking));

    const inVehicle = Boolean(data.driving);
    $("#cluster").classList.toggle("hidden", !inVehicle);
    $("#hud").classList.toggle("driving", inVehicle);
    if (inVehicle) {
        setLamps(data);
        setFuel(data.fuel);
    }
    // com o minimapa do jogo na tela, o bloco da esquerda vai para o lado dele
    $("#hud").classList.toggle("radar", Boolean(data.radar));
    if (data.radar && data.radarEdge !== lastDrive.edge) {
        lastDrive.edge = data.radarEdge;
        $("#hud").style.setProperty("--radar-edge", `${data.radarEdge}vw`);
    }

    if (data.street !== undefined) $("#street").textContent = data.street;
    if (data.zone !== undefined) $("#zone").textContent = data.zone;
    if (data.direction !== undefined) $("#direction").textContent = (L.directions || [])[data.direction - 1] || "";
    if (data.clock !== undefined) $("#clock").textContent = data.clock;

    paused = Boolean(data.paused);
    updateVisibility();
}

/** Luzes do painel: mudam devagar, chegam junto com o status */
function setLamps(data) {
    const engine = Number(data.engine);
    $("#lamp-engine").classList.toggle("warn", engine < 7 && engine >= 4);
    $("#lamp-engine").classList.toggle("bad", engine < 4);
    $("#lamp-lights").classList.toggle("on", Number(data.lights) === 1);
    $("#lamp-lights").classList.toggle("high", Number(data.lights) === 2);
    $("#lamp-lock").classList.toggle("on", Boolean(data.locked));
    $("#lamp-brake").classList.toggle("bad", Boolean(data.handbrake));
    if (Boolean(data.noBelt) !== noBelt) {
        noBelt = Boolean(data.noBelt);
        drawBelt();
    }
}

function updateBeltBlink() {
    // cinto solto com o veículo andando: a luz pisca
    const blink = beltKnown && !noBelt && !belt && (lastDrive.speed || 0) > 20;
    if (blink === lastDrive.blink) return;
    lastDrive.blink = blink;
    $("#lamp-belt").classList.toggle("blink", blink);
}

/** Velocidade, giro e marcha: a única mensagem que chega várias vezes por segundo */
function setDrive(data) {
    const speed = Number(data.speed) || 0;
    const ratio = clamp(speed / maxSpeed, 0, 1);
    const rpm = clamp((Number(data.rpm) || 0) / 50, 0, 1);
    // o que está dentro do SVG só é regravado quando muda: cada escrita repinta o mostrador
    if (speed !== lastDrive.speed) {
        lastDrive.speed = speed;
        $("#speed").textContent = speed;
        $("#dial-speed").style.strokeDasharray = `${ratio * SWEEP} 360`;
    }
    $("#needle").style.transform = `rotate(${-135 + ratio * SWEEP}deg)`;
    $("#rpm-needle").style.transform = `rotate(${-135 + rpm * SWEEP}deg)`;

    const gear = Number(data.gear);
    const gearText = gear === 0 ? "R" : speed === 0 && rpm < 0.3 ? "N" : String(gear);
    if (gearText !== lastDrive.gear) {
        lastDrive.gear = gearText;
        $("#gear").textContent = gearText;
    }
    updateBeltBlink();
}

function setMoney(kind, value) {
    const amount = Math.floor(Number(value) || 0);
    const previous = lastMoney[kind];
    lastMoney[kind] = amount;
    $(`#${kind}`).textContent = `${amount < 0 ? "-" : ""}${formatMoney(amount)}`;
    if (previous === null || previous === amount) return;

    const diff = amount - previous;
    const node = $(`#${kind}-delta`);
    node.textContent = `${diff > 0 ? "+" : "-"} ${formatMoney(diff)}`;
    node.classList.remove("play", "up", "down");
    void node.offsetWidth; // reinicia a animação
    node.classList.add("play", diff > 0 ? "up" : "down");
}

/** Alcance da voz e rádio. Quem acende o microfone ao falar é a mensagem de status. */
function setVoice(data) {
    const ranges = Math.max(1, Number(data.ranges) || 1);
    $("#v-voice .ring-fg").style.strokeDasharray = `${(clamp(data.range, 0, ranges) / ranges) * 100} 100`;

    // rádio: aparece só com um canal sintonizado
    const onRadio = data.radio !== undefined && data.radio !== null;
    const radio = $("#v-radio");
    radio.classList.toggle("hidden", !onRadio);
    radio.classList.toggle("talking", Boolean(data.radioTalking));
    $("#radio-label").textContent = onRadio ? String(data.radio) : "";
}

function setBelt(data) {
    beltKnown = Boolean(data.known);
    belt = Boolean(data.on);
    drawBelt();
}

function drawBelt() {
    const lamp = $("#lamp-belt");
    lamp.classList.toggle("hidden", !beltKnown || noBelt);
    lamp.classList.toggle("on", belt);
    lamp.classList.toggle("bad", !belt);
    updateBeltBlink();
}

/** Munição da arma na mão: balas no pente e de reserva */
function setWeapon(data) {
    const box = $("#weapon");
    box.classList.toggle("hidden", !data.armed);
    if (!data.armed) return;
    const clip = Number(data.clip) || 0;
    const size = Number(data.clipSize) || 0;
    $("#ammo-clip").textContent = clip;
    $("#ammo-reserve").textContent = `/ ${Number(data.reserve) || 0}`;
    box.classList.toggle("low", clip > 0 && size > 0 && clip <= size * 0.25);
    box.classList.toggle("empty", clip === 0);
}

function setJob(data) {
    $("#job").classList.toggle("hidden", !data.label);
    if (!data.label) return;
    $("#job-label").textContent = data.label;
    $("#job-duty").textContent = (data.onDuty ? L.duty : L.off_duty) || "";
    $("#job").classList.toggle("on", Boolean(data.onDuty));
}

// avisa o Lua que a página já pode receber mensagens
window.addEventListener("load", () => {
    fetch(`https://${GetParentResourceName()}/ready`, { method: "POST", body: "{}" }).catch(() => {});
});

window.addEventListener("message", (event) => {
    const data = event.data;
    switch (data.action) {
        case "show":
            show(data);
            break;
        case "hide":
            shown = false;
            updateVisibility();
            break;
        case "money":
            setMoney("cash", data.cash);
            setMoney("bank", data.bank);
            break;
        case "status":
            setStatus(data);
            break;
        case "drive":
            setDrive(data);
            break;
        case "needs":
            setNeed("hunger", data.hunger);
            setNeed("thirst", data.thirst);
            break;
        case "voice":
            setVoice(data);
            break;
        case "belt":
            setBelt(data);
            break;
        case "job":
            setJob(data);
            break;
        case "weapon":
            setWeapon(data);
            break;
    }
});
