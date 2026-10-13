-- Aviso de versão nova no console. Lê um JSON público ({ "<resource>": "1.2.0" }) e compara com a
-- versão do manifesto. Não envia dado nenhum do servidor e não muda o funcionamento do script.

local VERSION_URL = 'https://raw.githubusercontent.com/dalmeidasdev/versions/main/versions.json'

if not Config.VersionCheck or VERSION_URL == '' then return end

local resourceName = GetCurrentResourceName()

---true se a versão `latest` (1.2.3) é maior que a instalada
local function isNewer(latest, installed)
    local a1, a2, a3 = latest:match('^(%d+)%.(%d+)%.(%d+)$')
    local b1, b2, b3 = tostring(installed):match('^(%d+)%.(%d+)%.(%d+)$')
    if not b1 then return latest ~= installed end
    a1, a2, a3, b1, b2, b3 = tonumber(a1), tonumber(a2), tonumber(a3), tonumber(b1), tonumber(b2), tonumber(b3)
    if a1 ~= b1 then return a1 > b1 end
    if a2 ~= b2 then return a2 > b2 end
    return a3 > b3
end

CreateThread(function()
    Wait(10000)
    PerformHttpRequest(VERSION_URL, function(status, body)
        if status ~= 200 or type(body) ~= 'string' or #body > 4096 then return end
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then return end
        local latest = data[resourceName]
        local installed = GetResourceMetadata(resourceName, 'version', 0)
        -- só aceita versão no formato 1.2.3: o texto vai para o console
        if type(latest) ~= 'string' or #latest > 16 or not latest:match('^%d+%.%d+%.%d+$') then return end
        if isNewer(latest, installed) then
            print(('^3[%s] %s^0'):format(resourceName, L('update_available', latest, tostring(installed))))
        end
    end, 'GET')
end)
