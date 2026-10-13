if Bridge.name ~= 'standalone' then return end

-- Sem framework: o HUD mostra vida, colete, fôlego, rua, voz, arma e painel do veículo.
-- Dinheiro fica em zero, e emprego, fome e sede não aparecem.
-- Use este arquivo como modelo para ligar o HUD a um framework próprio.

local loaded = false

function Bridge.IsLoaded()
    return loaded
end

---Dados do jogador: { identifier, name, cash, bank, hunger, thirst, job = { name, label, grade, gradeLabel, onDuty } }
---hunger e thirst vão de 0 a 100, ou nil se o servidor não usa.
function Bridge.GetData()
    return {
        identifier = nil,
        name = GetPlayerName(PlayerId()),
        cash = 0,
        bank = 0,
        hunger = nil,
        thirst = nil,
        job = { name = 'none', label = '', grade = 0, gradeLabel = '', onDuty = false },
    }
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    loaded = true
    Bridge.Emit('loaded')
end)
