if Bridge.name ~= 'qbcore' then return end

-- QBCore original, conferido contra o qb-core 1.3.0. Fome e sede vêm de metadata.hunger e
-- metadata.thirst (0 a 100).

local QBCore = exports['qb-core']:GetCoreObject()

-- Cópia dos dados do personagem. O qb-core novo avisa só o campo que mudou; guardar a cópia aqui
-- evita depender de qual resource recebe o aviso primeiro.
local cache = nil

local function normalize(data)
    data = data or {}
    local info = data.charinfo or {}
    local money = data.money or {}
    local job = data.job or {}
    local grade = job.grade or {}
    local meta = data.metadata or {}
    return {
        identifier = data.citizenid,
        name = ('%s %s'):format(info.firstname or '', info.lastname or ''),
        cash = money.cash or 0,
        bank = money.bank or 0,
        hunger = tonumber(meta.hunger),
        thirst = tonumber(meta.thirst),
        job = {
            name = job.name or 'unemployed',
            label = job.label or '',
            grade = tonumber(grade.level) or 0,
            gradeLabel = grade.name or '',
            onDuty = job.onduty == true,
        },
    }
end

---true se o personagem já está na cidade
function Bridge.IsLoaded()
    return LocalPlayer.state.isLoggedIn == true
end

---Dados do personagem: { identifier, name, cash, bank, hunger, thirst, job = { name, label, grade, gradeLabel, onDuty } }
---hunger e thirst vão de 0 a 100, ou nil se o servidor não usa.
function Bridge.GetData()
    cache = QBCore.Functions.GetPlayerData() or cache
    return normalize(cache)
end

-- Cinto: quem cuida é o qb-smallresources, que avisa a cada mudança. Versões antigas avisam sem
-- dizer o estado, então sem o valor o adaptador só inverte o que tinha.
local belted = nil

---Cinto de segurança: true (preso), false (solto) ou nil se o servidor não tem script de cinto.
function Bridge.GetSeatbelt()
    if GetResourceState('qb-smallresources') ~= 'started' then return nil end
    local ok, on = pcall(function() return exports['qb-smallresources']:HasSeatbeltOn() end)
    if ok and type(on) == 'boolean' then
        belted = on
    else
        belted = belted or false
    end
    return belted
end

AddEventHandler('seatbelt:client:ToggleSeatbelt', function(on)
    if type(on) == 'boolean' then
        belted = on
    else
        belted = not belted
    end
    Bridge.Emit('seatbelt', belted)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Bridge.Emit('loaded')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    cache = nil
    Bridge.Emit('unloaded')
end)

-- qb-core antigo: manda os dados inteiros a cada mudança
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if type(data) ~= 'table' then return end
    cache = data
    Bridge.Emit('data', normalize(data))
end)

-- qb-core novo: manda só o campo que mudou ('money', 'metadata', 'job'...), ou 'all' com tudo
RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, value)
    if key == 'all' then
        if type(value) ~= 'table' then return end
        cache = value
    elseif type(key) == 'string' then
        cache = cache or QBCore.Functions.GetPlayerData() or {}
        cache[key] = value
    else
        return
    end
    Bridge.Emit('data', normalize(cache))
end)
