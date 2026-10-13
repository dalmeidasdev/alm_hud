local resourceName = GetCurrentResourceName()

local visible = false         -- HUD na tela
local loaded = false          -- personagem na cidade
local hiddenByPlayer = false  -- escondido pelo comando
local covers = {}             -- quem pediu para o HUD sair -> true

local money = { cash = 0, bank = 0 }
local needs = {}   -- { hunger, thirst }; vazio se o framework não tem
local job = nil    -- { label, onDuty }, ou nil para esconder
local belt = nil   -- true ou false quando um script de cinto informa; nil esconde a luz

local SHOW <const> = Config.Show
local SPEED_FACTOR <const> = Config.SpeedUnit == 'mph' and 2.236936 or 3.6
local UNARMED <const> = joaat('WEAPON_UNARMED')

local HIDDEN_JOBS <const> = {}
for _, name in ipairs(Config.HiddenJobs) do HIDDEN_JOBS[name] = true end

local function isTrue(value)
    return value == true or value == 1
end

-- ─────────────────────────── envio à interface ──────────────────────────────

local function sendMoney()
    SendNUIMessage({ action = 'money', cash = money.cash, bank = money.bank })
end

local function sendNeeds()
    SendNUIMessage({ action = 'needs', hunger = needs.hunger, thirst = needs.thirst })
end

local function sendJob()
    SendNUIMessage({ action = 'job', label = job and job.label or nil, onDuty = job and job.onDuty or false })
end

local function sendVoice(state)
    if not SHOW.voice or type(state) ~= 'table' then return end
    SendNUIMessage({
        action = 'voice', range = state.range, ranges = state.ranges, radio = state.radio, radioTalking = state.radioTalking,
    })
end

local function sendBelt()
    SendNUIMessage({ action = 'belt', known = belt ~= nil, on = belt == true })
end

---Dados vindos da ponte. O aviso se repete com o mesmo conteúdo: só o que mudou vai para a tela.
local function applyData(data)
    if type(data) ~= 'table' then return end

    local cash = math.floor(tonumber(data.cash) or 0)
    local bank = math.floor(tonumber(data.bank) or 0)
    if cash ~= money.cash or bank ~= money.bank then
        money.cash, money.bank = cash, bank
        if visible then sendMoney() end
    end

    local hunger = tonumber(data.hunger) and math.floor(data.hunger + 0.5) or nil
    local thirst = tonumber(data.thirst) and math.floor(data.thirst + 0.5) or nil
    if hunger ~= needs.hunger or thirst ~= needs.thirst then
        needs.hunger, needs.thirst = hunger, thirst
        if visible then sendNeeds() end
    end

    local info = type(data.job) == 'table' and data.job or {}
    local label = (not HIDDEN_JOBS[info.name] and info.label ~= '') and info.label or nil
    local onDuty = info.onDuty == true
    local known = job ~= nil
    if (label ~= nil) ~= known or (job and (job.label ~= label or job.onDuty ~= onDuty)) then
        job = label and { label = label, onDuty = onDuty } or nil
        if visible then sendJob() end
    end
end

-- ─────────────────────────── leitura do jogo ────────────────────────────────

---Vida de 0 a 100 (o jogo conta de 100 até o máximo)
local function healthPercent(ped)
    if IsEntityDead(ped) then return 0 end
    local max = GetEntityMaxHealth(ped) - 100
    if max <= 0 then return 0 end
    local percent = math.floor((GetEntityHealth(ped) - 100) / max * 100 + 0.5)
    return math.min(100, math.max(0, percent))
end

local streetCache = {} -- nome do jogo -> nome mostrado

local function streetName(name)
    if type(name) ~= 'string' or name == '' then return '' end
    local shown = streetCache[name]
    if not shown then
        shown = Config.Streets[name:lower()] or name
        streetCache[name] = shown
    end
    return shown
end

local function zoneName(code)
    if type(code) ~= 'string' then return '' end
    local shown = Config.Zones[code:upper()]
    if shown then return shown end
    local label = GetLabelText(code)
    if not label or label == 'NULL' then return '' end
    return label
end

---Rua, bairro, direção (1 a 8, a partir do norte no sentido anti-horário) e hora do jogo
local function location(ped)
    local coords = GetEntityCoords(ped)
    local street = streetName(GetStreetNameFromHashKey((GetStreetNameAtCoord(coords.x, coords.y, coords.z))))
    local zone = zoneName(GetNameOfZone(coords.x, coords.y, coords.z))
    local direction = math.floor((GetEntityHeading(ped) + 22.5) / 45.0) % 8 + 1
    local clock = ('%02d:%02d'):format(GetClockHours(), GetClockMinutes())
    return street, zone, direction, clock
end

-- O minimapa do jogo traz barras de vida e colete próprias; o HUD já mostra isso nos anéis.
-- O valor 3 em SETUP_HEALTH_ARMOUR esconde as duas. O jogo às vezes restaura, então repete com o mapa na tela.
local minimapScaleform = nil
local minimapReady = false
local function hideMinimapBars()
    if not minimapScaleform then minimapScaleform = RequestScaleformMovie('minimap') end
    if not HasScaleformMovieLoaded(minimapScaleform) then return end
    if not minimapReady then
        -- pedir este scaleform deixa o minimapa em branco até o mapa ampliado ser ligado e desligado uma vez
        minimapReady = true
        SetRadarBigmapEnabled(true, false)
        Wait(0)
        SetRadarBigmapEnabled(false, false)
    end
    BeginScaleformMovieMethod(minimapScaleform, 'SETUP_HEALTH_ARMOUR')
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()
end

-- Uma única thread, que só existe enquanto o HUD está visível.
-- Três mensagens: 'status' (o que muda devagar: vida, rua, luzes), 'drive' (velocidade, giro e
-- marcha) e 'weapon' (munição). Cada uma só sai quando algum valor dela muda, e as tabelas são
-- reaproveitadas: nada é alocado por leitura.
local loopId = 0
local function statusLoop()
    loopId = loopId + 1
    local id = loopId -- esconder e mostrar rápido não pode deixar duas threads rodando
    local slow = { action = 'status' }
    local fast = { action = 'drive' }
    local gun = { action = 'weapon', armed = false }
    local changed = false
    local function put(key, value)
        if slow[key] ~= value then
            slow[key] = value
            changed = true
        end
    end
    local nextLocation = 0
    local nextSlow = 0 -- dentro de veículo, a leitura lenta tem intervalo próprio
    local wasInVehicle = false
    local paused, armed = false, false
    local radar = nil -- último estado pedido ao minimapa
    local player = PlayerId()
    while visible and id == loopId do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local inVehicle = veh ~= 0

        local wantRadar = Config.ShowMinimap or (inVehicle and Config.MinimapInVehicle)
        if wantRadar ~= radar then
            radar = wantRadar
            DisplayRadar(wantRadar)
            nextLocation = 0
        end

        -- Dentro de veículo o laço roda rápido por causa do velocímetro; vida, luzes, rua e munição
        -- continuam no ritmo de quem está a pé. Entrar ou sair do veículo lê tudo na hora.
        local now = GetGameTimer()
        if now >= nextSlow or inVehicle ~= wasInVehicle then
            wasInVehicle = inVehicle
            changed = false

            -- rua, relógio e o acerto do minimapa mudam mais devagar ainda: intervalo próprio
            if now >= nextLocation then
                nextLocation = now + Config.LocationInterval
                local street, zone, direction, clock = location(ped)
                put('street', street)
                put('zone', zone)
                put('direction', direction)
                put('clock', clock)
                put('radar', wantRadar)
                -- onde o minimapa termina, em % da largura da tela (ele é mais estreito em tela ultralarga)
                put('radarEdge', wantRadar and math.floor(Config.MinimapEdge * (16 / 9) / GetAspectRatio(false) * 10 + 0.5) / 10 or 0)
                if wantRadar and Config.HideMinimapBars then hideMinimapBars() end
            end

            paused = IsPauseMenuActive()
            put('health', healthPercent(ped))
            put('armor', GetPedArmour(ped))
            put('paused', paused)
            put('driving', inVehicle)
            -- fôlego em passos de 5%; o ar só existe debaixo d'água (-1 esconde o anel)
            put('stamina', inVehicle and 100 or math.floor((100.0 - GetPlayerSprintStaminaRemaining(player)) / 5 + 0.5) * 5)
            put('oxygen', IsPedSwimmingUnderWater(ped)
                and math.floor(math.min(100.0, math.max(0.0, GetPlayerUnderwaterTimeRemaining(player) * 10.0)) / 5 + 0.5) * 5 or -1)
            if SHOW.voice then put('talking', isTrue(NetworkIsPlayerTalking(player))) end

            if inVehicle then
                local _, lightsOn, highBeams = GetVehicleLightsState(veh)
                put('engine', math.floor(math.max(0.0, GetVehicleEngineHealth(veh)) / 100))
                put('lights', isTrue(highBeams) and 2 or (isTrue(lightsOn) and 1 or 0))
                put('locked', GetVehicleDoorLockStatus(veh) >= 2)
                put('handbrake', isTrue(GetVehicleHandbrake(veh)))
                -- moto, bicicleta e barco não têm cinto: a luz some
                local class = GetVehicleClass(veh)
                put('noBelt', class == 8 or class == 13 or class == 14)
                if SHOW.fuel then put('fuel', math.floor(math.min(100.0, math.max(0.0, GetVehicleFuelLevel(veh))) + 0.5)) end
            end
            if changed then SendNUIMessage(slow) end

            -- munição: só arma que tem pente
            armed = false
            if SHOW.weapon then
                local weapon = GetSelectedPedWeapon(ped)
                local clipSize = weapon ~= UNARMED and GetMaxAmmoInClip(ped, weapon, true) or 0
                if clipSize > 0 then
                    armed = true
                    local _, clip = GetAmmoInClip(ped, weapon)
                    local reserve = math.max(0, GetAmmoInPedWeapon(ped, weapon) - clip)
                    if not gun.armed or clip ~= gun.clip or reserve ~= gun.reserve or clipSize ~= gun.clipSize then
                        gun.armed, gun.clip, gun.reserve, gun.clipSize = true, clip, reserve, clipSize
                        SendNUIMessage(gun)
                    end
                elseif gun.armed then
                    gun.armed = false
                    SendNUIMessage(gun)
                end
            end

            -- a pé o próprio Wait do laço já dá o intervalo: a leitura lenta roda em toda volta
            nextSlow = inVehicle and now + (armed and Config.IntervalArmed or Config.IntervalOnFoot) or 0
        end

        if inVehicle then
            local speed = math.floor(GetEntitySpeed(veh) * SPEED_FACTOR + 0.5)
            -- giro em passos de 2%: o arco não precisa de mais que isso
            local rpm = GetIsVehicleEngineRunning(veh) and math.floor(GetVehicleCurrentRpm(veh) * 50 + 0.5) or 0
            local gear = GetVehicleCurrentGear(veh)
            if speed ~= fast.speed or rpm ~= fast.rpm or gear ~= fast.gear then
                fast.speed, fast.rpm, fast.gear = speed, rpm, gear
                SendNUIMessage(fast)
            end
        else
            fast.speed = nil -- ao entrar em outro veículo, a primeira leitura sempre sai
        end

        -- com o menu de pausa aberto o HUD está escondido: não precisa da leitura rápida
        if paused then
            nextSlow = 0
            Wait(Config.IntervalOnFoot)
        elseif inVehicle then
            Wait(Config.IntervalInVehicle)
        else
            Wait(armed and Config.IntervalArmed or Config.IntervalOnFoot)
        end
    end
    -- HUD escondido: o minimapa volta ao padrão a pé (se outro laço já assumiu, o minimapa é dele)
    if id == loopId then DisplayRadar(Config.ShowMinimap) end
end

-- ─────────────────────────── mostrar e esconder ─────────────────────────────

local function refresh()
    local shouldShow = loaded and not hiddenByPlayer and next(covers) == nil
    if shouldShow == visible then return end
    visible = shouldShow

    if not visible then
        SendNUIMessage({ action = 'hide' })
        return
    end

    SendNUIMessage({
        action = 'show',
        locale = LocaleUi(),
        theme = Config.Theme,
        show = SHOW,
        currency = Config.Currency,
        serverName = Config.ServerName,
        speedUnit = Config.SpeedUnit == 'mph' and 'mph' or 'kmh',
        maxSpeed = Config.DialMaxSpeed,
        id = GetPlayerServerId(PlayerId()),
    })
    sendMoney()
    sendNeeds()
    sendJob()
    sendBelt()
    sendVoice(Bridge.GetVoice())
    CreateThread(statusLoop)
end

local function onLoaded()
    applyData(Bridge.GetData())
    if Bridge.GetSeatbelt and belt == nil then belt = Bridge.GetSeatbelt() end
    loaded = true
    DisplayRadar(Config.ShowMinimap)
    refresh()
end

Bridge.On('loaded', onLoaded)

Bridge.On('unloaded', function()
    loaded = false
    refresh()
end)

Bridge.On('data', applyData)

Bridge.On('voice', function(state)
    if visible then sendVoice(state) end
end)

-- ─────────────────────────── para outros scripts ────────────────────────────

---Tira o HUD da tela enquanto uma tela cheia de outro script estiver aberta.
---exports.<este resource>:Cover('minha_tela', true) ao abrir e (..., false) ao fechar.
local function cover(id, on)
    if type(id) ~= 'string' then return end
    covers[id] = on and true or nil
    refresh()
end

---Informa o cinto de segurança: true (preso), false (solto) ou nil (esconde a luz do painel).
local function setSeatbelt(on)
    local value = nil
    if on ~= nil then value = on == true end
    if value == belt then return end
    belt = value
    if visible then sendBelt() end
end

exports('Cover', function(id, on)
    cover(id or GetInvokingResource(), on)
end)
exports('SetSeatbelt', setSeatbelt)

AddEventHandler(resourceName .. ':cover', cover)
AddEventHandler(resourceName .. ':seatbelt', setSeatbelt)

-- o adaptador do framework também pode informar o cinto
Bridge.On('seatbelt', setSeatbelt)

-- quem pediu para cobrir parou sem devolver: o HUD volta
AddEventHandler('onResourceStop', function(resource)
    if resource == resourceName then
        DisplayRadar(true)
    elseif covers[resource] then
        covers[resource] = nil
        refresh()
    end
end)

-- ─────────────────────────── página, comando e início ───────────────────────

-- A página avisa quando terminou de carregar. Se o resource foi reiniciado com o jogador na
-- cidade, o primeiro 'show' saiu antes de a página existir: manda de novo.
RegisterNUICallback('ready', function(_, cb)
    if visible then
        visible = false
        refresh()
    end
    cb({})
end)

RegisterCommand(Config.ToggleCommand, function()
    hiddenByPlayer = not hiddenByPlayer
    refresh()
end, false)

-- Resource iniciado com o jogador já dentro da cidade
CreateThread(function()
    DisplayRadar(Config.ShowMinimap)
    if Bridge.IsLoaded() then onLoaded() end
end)
