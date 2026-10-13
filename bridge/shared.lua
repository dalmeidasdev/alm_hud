-- Ponte de frameworks. Este arquivo escolhe o adaptador; cada arquivo de bridge/client e
-- bridge/server começa com `if Bridge.name ~= '<nome>' then return end`, então só um deles vale.
-- Para ligar o script a um framework que não está na lista, copie o adaptador standalone,
-- troque o nome e acrescente uma linha em KNOWN.

Bridge = {}

-- Ordem importa: o primeiro que estiver no servidor é usado.
local KNOWN = {
    { name = 'qbcore', resource = 'qb-core' },
}

local function detect()
    local wanted = Config.Framework
    if type(wanted) == 'string' and wanted ~= 'auto' then return wanted end
    for _, framework in ipairs(KNOWN) do
        local state = GetResourceState(framework.resource)
        if state == 'started' or state == 'starting' then return framework.name end
    end
    return 'standalone'
end

Bridge.name = detect()

-- Avisos da ponte para o script, iguais em todo framework (só do lado do cliente):
--   'loaded'    personagem entrou na cidade
--   'unloaded'  personagem saiu (troca de personagem)
--   'data'      dados mudaram; recebe a mesma tabela de Bridge.GetData()
--   'seatbelt'  cinto mudou; recebe true (preso) ou false (solto). Opcional, junto com Bridge.GetSeatbelt()
local listeners = {}

function Bridge.On(event, fn)
    local list = listeners[event]
    if not list then
        list = {}
        listeners[event] = list
    end
    list[#list + 1] = fn
end

function Bridge.Emit(event, ...)
    local list = listeners[event]
    if not list then return end
    for i = 1, #list do list[i](...) end
end
