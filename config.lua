Config = {}

-- Idioma dos textos: 'pt-br' ou 'en' (arquivos em locales/)
Config.Locale = 'pt-br'

-- Framework do servidor: 'auto' descobre sozinho. Para forçar: 'qbcore' ou 'standalone'.
Config.Framework = 'auto'

-- Avisa no console do servidor quando sair versão nova. Só lê um arquivo público; não envia nada.
Config.VersionCheck = true

-- Nome que aparece no canto superior direito ('' esconde)
Config.ServerName = 'Minha Cidade'

-- Comando que esconde ou mostra o HUD
Config.ToggleCommand = 'hud'

-- Liga e desliga cada parte do HUD
Config.Show = {
    name = true,    -- nome do servidor
    id = true,      -- ID do jogador
    clock = true,   -- hora do jogo
    cash = true,    -- dinheiro na carteira
    bank = true,    -- dinheiro no banco
    job = true,     -- emprego e serviço
    place = true,   -- rua, bairro e direção
    hunger = true,  -- fome (só se o framework tiver)
    thirst = true,  -- sede (só se o framework tiver)
    stamina = true, -- fôlego, aparece ao correr
    oxygen = true,  -- ar, aparece debaixo d'água
    voice = true,   -- microfone e rádio
    weapon = true,  -- munição da arma na mão
    fuel = true,    -- combustível no painel do veículo
}

-- Empregos que não aparecem no HUD (nome interno do emprego)
Config.HiddenJobs = { 'unemployed', 'none' }

-- Dinheiro na tela: símbolo e separador de milhar
Config.Currency = { symbol = 'R$', thousands = '.' }

-- Velocímetro: 'kmh' ou 'mph', e a velocidade no fim do arco
Config.SpeedUnit = 'kmh'
Config.DialMaxSpeed = 240

-- Minimapa do jogo
Config.ShowMinimap = false      -- true mostra o minimapa também a pé
Config.MinimapInVehicle = true  -- mostra o minimapa dentro de veículo
Config.HideMinimapBars = true   -- tira do minimapa as barras de vida e colete do jogo (o HUD já mostra)
Config.MinimapEdge = 21.5       -- onde o minimapa termina em 16:9, em % da largura da tela; o bloco de status fica logo depois

-- Quantos alcances de voz existem no seu servidor (o anel do microfone enche conforme o alcance)
Config.VoiceRanges = 3

-- Intervalos de leitura, em milissegundos. Menor = mais fluido e mais custo.
Config.IntervalOnFoot = 400
Config.IntervalArmed = 150      -- com arma de fogo na mão (para a munição acompanhar os tiros)
Config.IntervalInVehicle = 100
Config.LocationInterval = 1500  -- rua, bairro, direção e relógio

-- Cores, sempre no formato '#rrggbb'
Config.Theme = {
    accent = '#ff7a1a',     -- cor de destaque
    background = '#0c0e12', -- fundo das faixas e dos anéis
    surface = '#1b1f27',    -- centro dos anéis e dos mostradores
    line = '#2e3542',       -- contornos
    text = '#f1f3f6',
    muted = '#9aa3b2',      -- rótulos
    success = '#4ade80',    -- vida, em serviço
    warning = '#facc15',    -- fome, avisos
    danger = '#f43f5e',     -- valor baixo, ponteiros
    info = '#60a5fa',       -- colete, farol alto
    thirst = '#38bdf8',     -- sede
}

-- Nomes próprios para ruas e bairros. O que não estiver aqui aparece com o nome do jogo.
-- Rua: nome do jogo em minúsculas. Bairro: código da zona do jogo em maiúsculas.
Config.Streets = {
    -- ['vinewood blvd'] = 'Av. Paulista',
}

Config.Zones = {
    -- DOWNT = 'Centro',
}
