#!/bin/bash

# Inspiration of the blog https://blog.projectdiscovery.io/building-one-shot-recon/

#--- seta cores
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

# set vars
EMPRESA="$1"
GIT_ROOT=$(git rev-parse --show-toplevel)
# SUBDOM_LIST=$(curl -s https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt)
# RESOLVERS=$(curl -s <URL RESOLVERS PUB>)
SUBDOM_LIST="$GIT_ROOT/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS="$GIT_ROOT/resolvers/resolvers.txt"
# export GIT_ROOT=$PWD
export DOTFILES=$PWD

# Verifica se o arquivo /root/recons/companies.txt existe
if [ ! -f "/root/recons/companies.txt" ]; then
  echo "${red}O arquivo /root/recons/companies.txt não existe. Por favor, crie o arquivo com os nomes das empresas.${reset}"
  exit 1
fi

# Lê as empresas do arquivo
readarray -t empresas < /root/recons/companies.txt

# Função para listar empresas com paginação
listar_empresas() {
  local start_index=$1
  for ((i=start_index; i<start_index+25 && i<${#empresas[@]}; i++)); do
    echo "${green}$((i+1)).${reset} ${empresas[i]}"
  done
}

escanear_empresa() {
  EMPRESA=$1
  # Verifique se os diretórios $HOME/recons e $GIT_ROOT/recons existem
  if [ -d "$HOME/recons" ] && [ -d "$GIT_ROOT/recons" ]; then
    # Informe ao usuário que ambos os diretórios existem e peça que ele escolha
    echo "${blue}[+] Os diretórios $HOME/recons e $GIT_ROOT/recons existem. Qual você gostaria de usar?${reset}"
    echo "${green}1) $HOME/recons${reset}"
    echo "${green}2) $GIT_ROOT/recons${reset}"
    read -p "Por favor, escolha uma opção (1-2): " option
    
    # Verifique a entrada do usuário e defina o ppath de acordo
    case $option in
      1) ppath="$HOME/recons";;
      2) ppath="$GIT_ROOT/recons";;
      * ) echo "${red}Opção inválida, saindo do script.${reset}"; exit 1;;
    esac
  elif [ -d "$HOME/recons" ]; then
    # Informe ao usuário que o diretório $HOME/recons existe
    echo "${blue}[+] O diretório ${green}$HOME/recons${reset}${blue} já existe, mesmo assim você quer criar no diretório $GIT_ROOT/recons? (yes/no)${reset}"
    read -p "Por favor, digite sua resposta (y/N/c): " res
    
    # Verifique a entrada do usuário e defina o ppath de acordo
    case $res in
      [Yy]* ) ppath="$GIT_ROOT/recons";;
      [Nn]* ) ppath="$HOME/recons";;
      [Cc]* ) echo "${red}Saindo do script.${reset}"; exit 1;;
      * ) echo "${yellow}[+] Continua em ${green}$HOME/recons${reset}"; ppath="$HOME/recons";;
    esac
  elif [ -d "$GIT_ROOT/recons" ]; then
    # Informe ao usuário que o diretório $GIT_ROOT/recons existe
    echo "${blue}[+] O diretório ${green}$GIT_ROOT/recons${reset}${blue} já existe, mesmo assim você quer criar no diretório $HOME/recons? (yes/no)${reset}"
    read -p "Por favor, digite sua resposta (y/N/c): " res
    
    # Verifique a entrada do usuário e defina o ppath de acordo
    case $res in
      [Yy]* ) ppath="$HOME/recons";;
      [Nn]* ) ppath="$GIT_ROOT/recons";;
      [Cc]* ) echo "${red}Saindo do script.${reset}"; exit 1;;
      * ) echo "${yellow}[+] Continua em ${green}$GIT_ROOT/recons${reset}"; ppath="$GIT_ROOT/recons";;
    esac
  else
    # Pergunte ao usuário onde ele deseja criar os diretórios
    echo "${blue}[+] Onde você deseja criar os diretórios?${reset}"
    echo "${green}1) No diretório $HOME/recons${reset}"
    echo "${green}2) No diretório atual do git${reset}"
    read -p "Por favor, escolha uma opção (1-2): " option

    # Verifique a entrada do usuário e defina o ppath de acordo
    case $option in
      1) ppath="$HOME/recons";;
      2) ppath="$GIT_ROOT/recons";;
      * ) echo "${red}Opção inválida, saindo do script.${reset}"; exit 1;;
    esac
  fi

  # Caminho para os arquivos de escopo da empresa selecionada
  scope_path="$ppath/scope/$EMPRESA"
  roots_exist="$scope_path/scope_dominio.txt" # Aponta para o arquivo de domínio

  # Verifica se o arquivo roots_exist existe
  if [ ! -f "$roots_exist" ]; then
    echo "${red}O arquivo $roots_exist não existe. Por favor, verifique o nome da empresa ou o caminho do arquivo.${reset}"
    exit 1
  fi

  timestamp="$(date +%s)"
  date_scan_path="$(date +%d-%m-%Y_%Hh-%Mm-%Ss)"
  scan_path="$ppath/scans/$EMPRESA/$EMPRESA-$date_scan_path"

  # check if ppath exists, if not create it
  echo "${yellow}[+] Check se as pastas recons/scope e recons/scan existem...${reset}"
  # if [ ! -d "$ppath" ]; then
  #   echo "${yellow}[+] Criando pasta $ppath...${reset}"
  #   mkdir -p "$ppath"
  # fi

  # check if scope_path exists, if not create it
  if [ ! -d "$scope_path" ]; then
    echo "${yellow}[+] Criando pasta $scope_path...${reset}"
    mkdir -p "$scope_path"
  fi

  # check if scan_path exists, if not create it
  if [ ! -d "$scan_path" ]; then
    echo "${yellow}[+] Criando pasta $scan_path...${reset}"
    mkdir -p "$scan_path"
  fi

  # check if scan_path exists, if not create it
  if [ ! -f "$roots_exist" ]; then
    echo "${yellow}[+] Criando arquivo $roots_exist de $EMPRESA...${reset}"
    touch "$roots_exist"
    echo "$EMPRESA.com" >> $roots_exist
    # echo "$EMPRESA.com.br" >> $roots_exist
  fi

  ### PERFORM SCAN ###
  echo "${yellow}[+]${reset}"

  # Função para gerenciar URLs
  manage_urls() {
      echo "${blue}[+] URLs atualmente no escopo:${reset}"
      cat "$roots_exist"
      echo "${yellow}[+]${reset}"
      echo "${blue}[+] Escolha uma opção:${reset}"
      echo "1. Adicionar URL"
      echo "2. Remover URL"
      echo "3. Voltar"
      read -r choice
      case $choice in
      1)
          echo "${blue}[+] URLs atualmente no escopo:${reset}"
          cat "$roots_exist"
          echo "${yellow}[+]${reset}"
          echo "${blue}[+] Insira a URL para adicionar (digite 'fim' para terminar):${reset}"
          while read url; do
              # Verifique se 'fim' foi digitado
              if [[ "$url" == "fim" ]]; then
                  break
              fi
              # Verifique se a URL já está no arquivo
              if ! grep -Fxq "$url" "$roots_exist"
              then
                  echo "$url" >> "$roots_exist"
              fi
          done
          ;;
      2)
          echo "${blue}[+] URLs atualmente no escopo:${reset}"
          cat "$roots_exist"
          echo "${yellow}[+]${reset}"
          echo "${blue}[+] Insira a URL para remover (digite 'fim' para terminar):${reset}"
          while read url; do
              # Verifique se 'fim' foi digitado
              if [[ "$url" == "fim" ]]; then
                  break
              fi
              # Verifique se a URL está no arquivo e remova
              if grep -Fxq "$url" "$roots_exist"
              then
                  sed -i "/$url/d" "$roots_exist"
              fi
          done
          ;;
      3)
          # Volta ao menu principal
          ;;
      *)
          echo "Opção inválida."
          manage_urls
          ;;
      esac
      echo "${blue}Conteúdo de scope_dominio.txt:${reset}"
      cat "$scope_path/scope_dominio.txt"
      echo "${blue}Conteúdo de scope_subdominio.txt:${reset}"
      cat "$scope_path/scope_subdominio.txt"
  }

  # Menu principal
  while true; do
      echo "${blue}[+] URLs atualmente no escopo:${reset}"
      cat "$roots_exist"
      echo "${yellow}[+]${reset}"
      echo "${blue}[+] Escolha uma opção:${reset}"
      echo "1. Gerenciar Escopo"
      echo "2. Iniciar varredura"
      echo "3. Sair"
      read -r choice
      case $choice in
      1)
          manage_urls
          ;;
      2)
          # Iniciar a varredura
          break
          ;;
      3)
          # Sair do script
          exit 0
          ;;
      *)
          echo "Opção inválida."
          ;;
      esac
  done

  echo "Starting scan against roots:"
  cat "$roots_exist"
  cp -v "$roots_exist" "$scan_path/roots.txt"
  cd "$scan_path"

  ##################### ADD SCAN LOGIC HERE #####################
  source $DOTFILES/bot_scan_recon_vuln.sh

  # pwd
  # cat "$roots_exist" | subfinder | anew $scan_path/subs.txt
  # cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew $scan_path/subs.txt

  # command_file="$GIT_ROOT/scripts/add_oneliners_link_scan.sh"

  # # Execute cada linha do arquivo de comando
  # while read -r line; do
  #   echo "${blue}[+] Executando: $line${reset}"
  #   eval "$line"
  # done < "$command_file"


  ###############################################################

  # calculate time diff
  end_time=$(date +%s)
  seconds="$(expr $end_time - $timestamp)"
  time=""

  if [[ "$seconds" -gt 59 ]]
  then
    minutes=$(expr $seconds / 60)
    time="$minutes minutes"
  else
    time="$seconds seconds"
  fi

  echo "Scan $EMPRESA took $time"
  #echo "Scan $EMPRESA took $time" | notify
}

# Lista as empresas e pede ao usuário para selecionar uma
start_index=0
scan_todas=false
while true; do
  echo "${blue}Empresas disponíveis:${reset}"
  listar_empresas $start_index
  echo "---------------------------------------------"
  echo "${yellow}Digite 'm' para mostrar mais, 'q' para sair, 'a' para escanear todas as empresas, ou selecione o número da empresa ou escreva o nome da empresa que deseja escanear:${reset}"
  read -r entrada_empresa
  echo "---------------------------------------------"

  if [[ $entrada_empresa == 'm' ]]; then
    start_index=$((start_index + 25))
    continue
  elif [[ $entrada_empresa == 'q' ]]; then
    echo "${red}Saindo do script.${reset}"
    exit 0
  elif [[ $entrada_empresa == 'a' ]]; then
    echo "${green}Você selecionou escanear todas as empresas.${reset}"
    scan_todas=true
    break
  elif [[ $entrada_empresa =~ ^[0-9]+$ ]] && [ "$entrada_empresa" -le "${#empresas[@]}" ]; then
    EMPRESA=${empresas[$((entrada_empresa-1))]}
    echo "${green}Você selecionou a empresa:${reset} $EMPRESA"
    break
  elif [[ " ${empresas[@]} " =~ " ${entrada_empresa} " ]]; then
    EMPRESA=$entrada_empresa
    echo "${green}Você selecionou a empresa:${reset} $EMPRESA"
    break
  else
    echo "${red}Entrada inválida. Tente novamente.${reset}"
  fi
done

# Loop para escanear todas as empresas ou apenas uma, dependendo da escolha do usuário
if $scan_todas; then
  echo "${green}Você selecionou escanear todas as empresas.${reset}"
  echo "[+] O diretório /root/recons já existe, mesmo assim você quer criar no diretório /recons? (yes/no)"
  read -r confirmacao
  if [[ $confirmacao == 'yes' ]]; then
    for EMPRESA in "${empresas[@]}"; do
      echo "${green}Escaneando a empresa:${reset} $EMPRESA"
      escanear_empresa $EMPRESA
    done
  else
    echo "${red}Operação cancelada pelo usuário.${reset}"
    exit 0
  fi
else
  escanear_empresa $EMPRESA
fi