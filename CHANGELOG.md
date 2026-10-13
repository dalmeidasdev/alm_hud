# Mudanças

## 1.0.1
- Ícones do cadeado e do combustível redesenhados.
- `Config.NoSeatbeltClasses`: escolha em quais classes de veículo a luz do cinto não aparece.
- O ponteiro acompanha `Config.IntervalInVehicle`: dá para subir o intervalo sem o ponteiro andar aos trancos.
- Intervalos do `config.lua` com mínimo de 50 ms; valor errado ou apagado não trava mais o HUD.
- `Config.Framework` com nome desconhecido, ou com o framework desligado, cai no modo sem framework em vez de dar erro.
- `Cover` com nome próprio é desfeito quando o script que pediu para.
- Aviso de versão só aparece quando a versão publicada é maior que a instalada, e ignora resposta fora do formato.
- QBCore: avisos de campos que o HUD não usa são ignorados.
- Menos leituras com o menu de pausa aberto dentro de veículo.

## 1.0.0
- Primeira versão: status, dinheiro, emprego, rua e bairro, voz e rádio, munição e painel do veículo.
- Adaptador para QBCore e modo sem framework.
- No QBCore, a luz do cinto acompanha o `qb-smallresources`.
- Aviso de versão nova no console do servidor.
- Textos em português e inglês.
