# xdotool-govbr-login

## Descrição

A solução é composta pela função execute_actions, responsável por enviar comandos de teclado e mouse ao browser, e por um servidor netcat que escuta requisições HTTP GET enviadas à porta 3003.

Essa solução visa percorrer o fluxo de login sem o uso de bibliotecas como selenium e playwright, as quais tendem a deixar rastros na forma de configurações atípicas de browser e/ou código injetado. Esses rastros podem ser utilizados pelo GOVBR para detecção do acesso como robotizado, o que impede que o login seja feito.

## Limitações

- Nos testes feitos, consegui logar no site do [Procon-SP](https://fornecedor2.procon.sp.gov.br/login) na maioria das vezes. Contudo, em algumas execuções o xdotool simplesmente não digitou os valores esperados. Caso essa solução seja validada, posso aprimorá-la de forma a torná-la mais resiliente a esse tipo de bug
- Nessa solução, uma instância do firefox é utilizada enquanto o container estiver ativo. De forma que após cada login, a sessão do Procon é encerrada. Talvez seja melhor reiniciar o firefox após cada login 🤔 
- Ainda não implementei validações para direcionar o fluxo de login em caso de erro (como indisponibilidade, bug do xdotool ou captcha). Por isso, caso algum erro aconteça, o servidor somente retornará 500 após tentar executar todos os passos programados

## Como reproduzir

- `docker compose -f docker-compose-firefox.yaml build`
- `docker compose -f docker-compose-firefox.yaml up`
- Fazer requisição GET em `http://localhost:3003?cpf=<CPF>&senha=<SENHA>`. Caso a automação tenha conseguido se autenticar, o HTTP status 200 e um json são retornados. Caso contrário, o HTTP status 500 é retornado
- Para acompanhar a execução da automação, acesse http://localhost:3000 no browser

## Exemplo de uso

```
>>> import requests
>>> response = requests.get('http://localhost:3003?cpf=111.111.111-11&senha=*Abc&$')
>>> response
<Response [200]>
>>> response.json()
{'refresh_token': 'eyJhbGciOiJIUzI1NissInR5cCIgOiAiSldUIiwia2lkIiA6ICJmNTc4MzVjMC1lNWQwLTQ4MmEtOWU3MS1hZjYxYjYxMGU2N2MifQ.eyJpYXQiOjE3MTgyODkxMDgsImp0aSI6IjU4ODBlNDRjLTkwOTEtNGIyOS1hZjc3LaM0MWEyYzAwZTMzMyIsImlzcyI6Imh0dHBzdi8vaWRwLnNwLmdvdi5ici9hdXRoL3JlYWxtcy9pZHBzcCIsImF1ZCI6Imh0dHBzOi8vaWRwLnNwLmdvdi5ici9hdXRoL3JlYWxtcy9pZHBzcCIsInN1YiI6IjMwM2UyZDRiLTRjNjMtNDhkMi04Y2E3LTA4ODQ5NzUwYmJmOCIsInR5cCI6Ik9mZmxpbmUiLCJhenAi...}
```
