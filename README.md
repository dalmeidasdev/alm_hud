# alm_hud

HUD completo para servidores de RP, por Almeida Scripts. Gratuito.

## O que mostra
- **Canto superior direito**: nome do servidor, ID do jogador, hora do jogo, carteira e banco (com a variação animada quando o saldo muda), emprego e se está em serviço.
- **Canto inferior esquerdo**: rua, bairro e direção; anéis de vida, colete, fome, sede, fôlego (ao correr), ar (debaixo d'água), microfone (alcance e fala) e rádio.
- **Canto inferior direito**: munição da arma na mão e, dentro de veículo, velocímetro, conta-giros, marcha, combustível e luzes de trava, farol, motor, freio de mão e cinto.

Cada parte liga e desliga no `config.lua`, e as cores são suas.

## Requisitos
- FXServer build 5181 ou mais novo.
- Nenhum outro resource é obrigatório.

## Funciona com
| Base | Situação |
|---|---|
| QBCore | adaptador incluído, **ainda em teste** |
| Sem framework (`standalone`) | sem dinheiro, emprego, fome e sede |
| vRP / Creative | previsto para a próxima versão |

Voz: entende o `pma-voice` (alcance e rádio). Com outro sistema de voz, o microfone ainda acende ao falar.
Combustível: lê o nível de combustível do próprio jogo, que os scripts de combustível mais comuns mantêm atualizado.

## Configuração
Tudo fica no `config.lua`, com um comentário por opção: partes ligadas, moeda, km/h ou mph, minimapa, cores e nomes próprios para ruas e bairros. Os textos estão em `locales/` (português e inglês).

## Para outros scripts
Os dois funcionam do lado do cliente.

```lua
-- Tirar o HUD da tela enquanto uma tela cheia estiver aberta
exports.alm_hud:Cover('minha_tela', true)   -- ao abrir
exports.alm_hud:Cover('minha_tela', false)  -- ao fechar

-- Informar o cinto de segurança (a luz do painel só aparece depois da primeira chamada)
exports.alm_hud:SetSeatbelt(true)   -- preso
exports.alm_hud:SetSeatbelt(false)  -- solto
```
Também existem como eventos locais: `alm_hud:cover` (id, ligado) e `alm_hud:seatbelt` (ligado).

No QBCore com o `qb-smallresources`, o cinto já vem ligado: não precisa chamar nada. Em moto, bicicleta e barco a luz do cinto não aparece.

## Arquivos abertos e protegidos
`config.lua`, `locales/` e `bridge/` são abertos para você ajustar. A pasta `bridge/` é a ligação com o framework e com a voz: é ali que se adapta o HUD a uma base diferente. O restante do Lua é protegido pelo Asset Escrow da Cfx. A interface (`html/`) é aberta.

O script não coleta nem envia dados do seu servidor. Com `Config.VersionCheck` ligado, ele só lê um arquivo público para avisar no console quando sai versão nova.

## Suporte
Pelo Discord da Almeida Scripts.
