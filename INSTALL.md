# Instalação do alm_hud

1. Baixe o `alm_hud-<versão>.zip` na página de Releases do GitHub (`github.com/dalmeidasdev/alm_hud/releases`).
   Não use o "Source code (zip)" nem o botão "Download ZIP" do GitHub: eles entregam a pasta com outro nome (`alm_hud-1.0.0`, `alm_hud-main`). Se já baixou assim, renomeie a pasta para `alm_hud`.
2. Extraia a pasta `alm_hud` dentro de `resources/`. **A pasta tem de se chamar `alm_hud`.**
3. Tire ou desligue o HUD que você usava antes (por exemplo `qb-hud` ou `ps-hud`): dois HUDs ao mesmo tempo ficam um por cima do outro.
4. No `server.cfg`, depois da linha do seu framework:
   ```
   ensure alm_hud
   ```
5. Abra o `config.lua` e ajuste o nome do servidor, a moeda e as cores.
6. Reinicie o servidor, ou rode `refresh` e `ensure alm_hud` no console.

## Conferindo
- Ao entrar com o personagem, o HUD aparece sozinho.
- `/hud` esconde e mostra.
- Entre em um veículo: o painel aparece no canto inferior direito.
- No console do servidor e no F8 não pode aparecer erro com `alm_hud`.

## Problemas comuns
| O que acontece | Causa | Solução |
|---|---|---|
| Erro de sintaxe em arquivo `.lua` | Servidor antigo | Atualize o FXServer para o build 5181 ou mais novo |
| Dinheiro em zero e sem emprego | O framework não foi reconhecido | Deixe o `ensure alm_hud` depois do framework; confira `Config.Framework` |
| Fome e sede não aparecem | O framework não informa esses valores | Normal no modo `standalone`; em outra base, ajuste `bridge/client/` |
| Combustível não aparece ou fica parado | Seu script de combustível não atualiza o nível do jogo | Desligue `fuel` em `Config.Show` |
| A luz do cinto não aparece | Nenhum script informou o cinto (no QBCore, quem informa é o `qb-smallresources`) | Veja "Para outros scripts" no README |
| As cores não mudam | Cor fora do formato | Use sempre `'#rrggbb'`, com seis dígitos |
