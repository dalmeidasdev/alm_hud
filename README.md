# alm_hud

HUD completo para servidores de RP, por Almeida Scripts. Gratuito.

## O que mostra
- **Canto superior direito**: nome do servidor, ID do jogador, hora do jogo, carteira e banco (com a variação animada quando o saldo muda), emprego e se está em serviço.
- **Canto inferior esquerdo**: rua, bairro e direção; anéis de vida, colete, fome, sede, fôlego (ao correr), ar (debaixo d'água), microfone (alcance e fala) e rádio.
- **Canto inferior direito**: munição da arma na mão e, dentro de veículo, velocímetro, conta-giros, marcha, combustível e luzes de trava, farol, motor, freio de mão e cinto.

Cada parte liga e desliga no `config.lua`, e as cores são suas.

## Baixar
Pegue o `alm_hud-<versão>.zip` na página de [Releases](https://github.com/dalmeidasdev/alm_hud/releases). O botão "Download ZIP" do GitHub entrega a pasta com outro nome; se usar esse caminho, renomeie a pasta para `alm_hud`. O passo a passo está no `INSTALL.md`.

## Desempenho
Medido no `resmon` em um servidor QBCore limpo, na versão 1.0.1: 0,03 a 0,04 ms a pé e 0,09 a 0,10 ms dirigindo.

## Requisitos
- FXServer build 5181 ou mais novo.
- Nenhum outro resource é obrigatório.

## Funciona com
| Base | Situação |
|---|---|
| QBCore | adaptador incluído, testado no qb-core 1.3.0 |
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

## Código aberto
Todo o código deste repositório é aberto para leitura. Para ajustar o HUD ao seu servidor você só precisa mexer em `config.lua`, `locales/` e `bridge/`. A pasta `bridge/` é a ligação com o framework e com a voz: é ali que se adapta o HUD a uma base diferente.

O script não coleta nem envia dados do seu servidor. Com `Config.VersionCheck` ligado, ele só lê um arquivo público (`https://raw.githubusercontent.com/dalmeidasdev/versions/main/versions.json`) para avisar no console quando sai versão nova.

## Licença
Uso livre em qualquer servidor e modificação para uso próprio. Não é permitido vender nem republicar; fork no GitHub para estudar ou propor mudanças é permitido. O texto completo está no arquivo `LICENSE`.

## Suporte
Pelo Discord da Almeida Scripts: https://discord.gg/dfuF2gz8NQ
