-- Voz: alcance e rádio. Vale para qualquer framework.
-- Quem acende o microfone é o próprio jogo (o HUD lê se o jogador está falando); este arquivo só
-- informa o alcance escolhido e o rádio. Hoje entende o pma-voice. Para outro sistema de voz,
-- preencha a tabela `state` nos eventos dele e chame Bridge.Emit('voice', state).

local state = {
    range = Config.VoiceRanges,  -- alcance atual, de 1 a Config.VoiceRanges
    ranges = Config.VoiceRanges,
    radio = nil,                 -- canal do rádio (número ou texto), ou nil fora do rádio
    radioTalking = false,        -- transmitindo no rádio
}

---Estado da voz: { range, ranges, radio, radioTalking }
function Bridge.GetVoice()
    return state
end

if GetResourceState('pma-voice') == 'missing' then return end

---Canal do rádio como vem do sistema de voz: número diferente de zero ou texto curto; o resto é "fora do rádio"
local function channelOf(value)
    if type(value) == 'number' then return value ~= 0 and value or nil end
    if type(value) == 'string' and value ~= '' and #value <= 8 then return value end
    return nil
end

local function publish()
    Bridge.Emit('voice', state)
end

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    state.range = tonumber(mode) or state.range
    publish()
end)

AddEventHandler('pma-voice:radioActive', function(active)
    state.radioTalking = active == true
    publish()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end

    local proximity = LocalPlayer.state.proximity
    if type(proximity) == 'table' and tonumber(proximity.index) then state.range = tonumber(proximity.index) end
    state.radio = channelOf(LocalPlayer.state.radioChannel)
    publish()

    local bag = ('player:%s'):format(GetPlayerServerId(PlayerId()))

    -- o pma-voice grava o alcance ao conectar na voz, o que pode acontecer depois da leitura acima
    AddStateBagChangeHandler('proximity', bag, function(_, _, value)
        local index = type(value) == 'table' and tonumber(value.index)
        if not index or index == state.range then return end
        state.range = index
        publish()
    end)

    AddStateBagChangeHandler('radioChannel', bag, function(_, _, value)
        state.radio = channelOf(value)
        if not state.radio then state.radioTalking = false end
        publish()
    end)
end)
