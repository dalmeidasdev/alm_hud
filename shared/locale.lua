-- Textos: cada arquivo de locales/ preenche Locales['<idioma>']. Texto que falta no idioma
-- escolhido cai no pt-br, e o que falta nos dois aparece como a própria chave.

Locales = {}

local FALLBACK = 'pt-br'

local function current()
    return Locales[Config.Locale] or Locales[FALLBACK] or {}
end

---Texto do idioma em uso; argumentos extras entram no string.format
function L(key, ...)
    local text = current()[key]
    if text == nil then
        local fallback = Locales[FALLBACK]
        text = fallback and fallback[key] or key
    end
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

---Tabela de textos da interface (vai inteira para a NUI na abertura)
function LocaleUi()
    return current().ui or (Locales[FALLBACK] and Locales[FALLBACK].ui) or {}
end
