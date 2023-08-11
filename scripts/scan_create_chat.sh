#!/bin/bash

#--- Set Colors
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

# Set Variables
EMPRESA="$1"
GIT_ROOT=$(git rev-parse --show-toplevel)
SUBDOM_LIST="$GIT_ROOT/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS="$GIT_ROOT/resolvers/resolvers.txt"
export DOTFILES=$PWD

# Check if companies.txt exists
if [ ! -f "/root/recons/companies.txt" ]; then
  echo "${red}O arquivo /root/recons/companies.txt não existe. Por favor, crie o arquivo com os nomes das empresas.${reset}"
  exit 1
fi

# Read companies from the file
readarray -t empresas < /root/recons/companies.txt

#--- List Companies with Pagination
listar_empresas() {
  local start_index=$1
  for ((i=start_index; i<start_index+25 && i<${#empresas[@]}; i++)); do
    echo "${green}$((i+1)).${reset} ${empresas[i]}"
  done
}

#--- Manage URLs
manage_urls() {
  while true; do
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
            if ! grep -Fxq "$url" "$roots_exist"; then
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
            if grep -Fxq "$url" "$roots_exist"; then
                sed -i "/$url/d" "$roots_exist"
            fi
        done
        ;;
    3)
        # Volta ao menu principal
        return
        ;;
    *)
        echo "Opção inválida."
        ;;
    esac
  done
}

#--- Scan Company
escanear_empresa() {
  EMPRESA=$1
  timestamp="$(date +%s)"
  date_scan_path="$(date +%d-%m-%Y_%Hh-%Mm-%Ss)"
  scan_path="$ppath/scans/$EMPRESA/$EMPRESA-$date_scan_path"

  # Check if folders exist and create them if not
  echo "${yellow}[+] Verificando se as pastas recons/scope e recons/scan existem...${reset}"
  mkdir -p "$ppath/scope/$EMPRESA" "$scan_path"

  # Create root file if not exist
  roots_exist="$ppath/scope/$EMPRESA/scope_dominio.txt"
  if [ ! -f "$roots_exist" ]; then
    echo "${yellow}[+] Criando arquivo $roots_exist de $EMPRESA...${reset}"
    touch "$roots_exist"
    echo "$EMPRESA.com" >> $roots_exist
  fi

  ### PERFORM SCAN ###
  echo "${yellow}[+] Iniciando a varredura...${reset}"

  # Logic to manage URLs
  scope_path="$ppath/scope/$EMPRESA"
  roots_exist="$scope_path/scope_dominio.txt" # Aponta para o arquivo de domínio

  # Logic to perform the scan
  echo "Starting scan against roots:"
  cat "$roots_exist"
  cp -v "$roots_exist" "$scan_path/roots.txt"
  cd "$scan_path"

  ##################### ADD SCAN LOGIC HERE #####################
  # Here you can add the specific scanning logic, such as calling
  # other scripts, running specific commands, etc.
  # ...

  echo "${green}[+] Varredura concluída!${reset}"

  # Main menu to manage URLs or start scanning
  confirmado_opcao2=false
  if [ "$confirmado_opcao2" != "true" ]; then
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
          # Start scanning
          confirmado_opcao2=true
          break
          ;;
      3)
          # Exit the script
          exit 0
          ;;
      *)
          echo "Opção inválida."
          ;;
      esac
    done
  fi

  # ... (logic to perform the scan)
}

#--- Main Menu
main_menu() {
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

  if $scan_todas; then
    for EMPRESA in "${empresas[@]}"; do
      echo "${green}Escaneando a empresa:${reset} $EMPRESA"
      escanear_empresa $EMPRESA
    done
  else
    escanear_empresa $EMPRESA
  fi
}

#--- Start the Script
main_menu
