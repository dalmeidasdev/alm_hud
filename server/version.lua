-- Aviso de versão nova no console. Lê um JSON público ({ "<resource>": "1.2.0" }) e compara com a
-- versão do manifesto. Não envia dado nenhum do servidor e não muda o funcionamento do script.

local VERSION_URL = 'https://raw.githubusercontent.com/dalmeidasdev/versions/main/versions.json'

if not Config.VersionCheck or VERSION_URL == '' then return end

local resourceName = GetCurrentResourceName()

CreateThread(function()
    Wait(10000)
    PerformHttpRequest(VERSION_URL, function(status, body)
        if status ~= 200 or type(body) ~= 'string' then return end
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then return end
        local latest = data[resourceName]
        local installed = GetResourceMetadata(resourceName, 'version', 0)
        if type(latest) == 'string' and latest ~= installed then
            print(('^3[%s] %s^0'):format(resourceName, L('update_available', latest, tostring(installed))))
        end
    end, 'GET')
end)
