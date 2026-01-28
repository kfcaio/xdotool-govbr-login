#!/bin/bash

export DISPLAY=:1
export TARGET_URL="https://fornecedor2.procon.sp.gov.br/login"

execute_actions() {
    CPF=$1
    SENHA=$2

    echo "Focando na janela do Firefox e abrindo uma nova guia..."
    sleep 5
    xdotool search --sync --onlyvisible --class "firefox" windowactivate --sync && xdotool key Ctrl+t
    sleep 1
    
    # Página inicial do PROCON

    echo "Digitando URL..."
    sleep 5
    xdotool type --delay 1 "$TARGET_URL"
    echo "Pressionando Return..."
    sleep 5
    xdotool key "Return"
    echo "Fechando modal de aviso..."
    sleep 5
    xdotool key "Return"
    echo "Pressionando Tab..."
    sleep 5
    xdotool key "Tab"
    echo "Pressionando Return..."
    sleep 5
    xdotool key "Return"

    # SSO do GOVBR

    echo "Digitando CPF..."
    sleep 5
    xdotool type --delay 3 "$CPF"
    sleep 3
    echo "Movendo o mouse aleatoriamente..."
    xdotool mousemove --sync $((RANDOM % 1000)) $((RANDOM % 1000))
    xdotool mousemove --sync $((RANDOM % 1000)) $((RANDOM % 1000))
    xdotool mousemove --sync $((RANDOM % 1000)) $((RANDOM % 1000))
    xdotool mousemove --sync $((RANDOM % 1000)) $((RANDOM % 1000))
    xdotool mousemove --sync $((RANDOM % 1000)) $((RANDOM % 1000))
    sleep 3
    echo "Pressionando Return..."
    sleep 5
    xdotool key "Return"
    echo "Digitando senha..."
    sleep 5
    xdotool type --delay 2 "$SENHA"
    sleep 5
    echo "Pressionando Return..."
    xdotool key "Return"


    # Usuário logado

    echo "Extraindo URL da última aba do Firefox..."
    sleep 5
    lz4jsoncat /config/.mozilla/firefox/*.default-release/sessionstore-backups/recovery.jsonlz4 | jq -r ".windows[0].tabs | sort_by(.lastAccessed)[-1] | .entries[.index-1] | .url"
    echo "Capturando localstorage..."
    xdotool key ctrl+shift+k
    sleep 15
    xdotool type --delay 2 "copy(localStorage)"
    xdotool key "Return"
    sleep 6
    xdotool key ctrl+shift+i
    export LOCALSTORAGE=$(xclip -o)
    echo $LOCALSTORAGE
    sleep 5
    echo "Encerrando sessão..."
    xdotool key "Tab"
    sleep 1
    xdotool key "Return"
    sleep 1
    xdotool key --repeat 2 --delay 1 "Down"
    sleep 1
    xdotool key "Return"
    sleep 1
    xdotool key "Tab"
    sleep 1
    xdotool key "Return"
}

rm -f response
mkfifo response

function handleRequest() {
  while read line; do
    echo $line
    trline=$(echo $line | tr -d '[\r\n]')

    if [ -z "$trline" ]; then
      break
    fi

    if echo "$trline" | grep -q "GET"; then
      params=$(echo "$trline" | awk -F' ' '{print $2}' | awk -F'?' '{print $2}')
      decoded_params=$(echo -e "$(echo -n "$params" | sed 's/%/\\x/g')")
      cpf=$(echo "$decoded_params" | grep -oP '(?<=cpf=)[^&]*')
      senha=$(echo "$decoded_params" | grep -oP '(?<=senha=)[^&]*')

      if [ -n "$cpf" ] && [ -n "$senha" ]; then
        execute_actions "$cpf" "$senha"
        if [ -n "$LOCALSTORAGE" ] && [ "$LOCALSTORAGE" != "{}" ]; then
          echo -e "HTTP/1.1 200 OK\r\n\r\n$LOCALSTORAGE" > response
          unset LOCALSTORAGE
        else
          echo -e "HTTP/1.1 500 Internal Server Error\r\n\r\n" > response
        fi
      else
        echo -e "HTTP/1.1 400 Bad Request\r\n\r\n" > response
      fi
    fi
  done
}


cat response | nc -lN 3003 | handleRequest
