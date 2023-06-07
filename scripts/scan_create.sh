#!/bin/bash

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
id="$1"
git_root=$(git rev-parse --show-toplevel)

# Verifique se os diretórios $HOME/recons e $git_root/recons existem
if [ -d "$HOME/recons" ] && [ -d "$git_root/recons" ]; then
  # Informe ao usuário que ambos os diretórios existem e peça que ele escolha
  echo "${blue}[+] Os diretórios $HOME/recons e $git_root/recons existem. Qual você gostaria de usar?${reset}"
  echo "${green}1) $HOME/recons${reset}"
  echo "${green}2) $git_root/recons${reset}"
  read -p "Por favor, escolha uma opção (1-2): " option
  
  # Verifique a entrada do usuário e defina o ppath de acordo
  case $option in
    1) ppath="$HOME/recons";;
    2) ppath="$git_root/recons";;
    * ) echo "${red}Opção inválida, saindo do script.${reset}"; exit 1;;
  esac
elif [ -d "$HOME/recons" ]; then
  # Informe ao usuário que o diretório $HOME/recons existe
  echo "${blue}[+] O diretório ${green}$HOME/recons${reset}${blue} já existe, mesmo assim você quer criar no diretório $git_root/recons? (yes/no)${reset}"
  read -p "Por favor, digite sua resposta (y/N/c): " res
  
  # Verifique a entrada do usuário e defina o ppath de acordo
  case $res in
    [Yy]* ) ppath="$git_root/recons";;
    [Nn]* ) ppath="$HOME/recons";;
    [Cc]* ) echo "${red}Saindo do script.${reset}"; exit 1;;
    * ) echo "${yellow}[+] Continua em ${green}$HOME/recons${reset}"; ppath="$HOME/recons";;
  esac
elif [ -d "$git_root/recons" ]; then
  # Informe ao usuário que o diretório $git_root/recons existe
  echo "${blue}[+] O diretório ${green}$git_root/recons${reset}${blue} já existe, mesmo assim você quer criar no diretório $HOME/recons? (yes/no)${reset}"
  read -p "Por favor, digite sua resposta (y/N/c): " res
  
  # Verifique a entrada do usuário e defina o ppath de acordo
  case $res in
    [Yy]* ) ppath="$HOME/recons";;
    [Nn]* ) ppath="$git_root/recons";;
    [Cc]* ) echo "${red}Saindo do script.${reset}"; exit 1;;
    * ) echo "${yellow}[+] Continua em ${green}$git_root/recons${reset}"; ppath="$git_root/recons";;
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
    2) ppath="$git_root/recons";;
    * ) echo "${red}Opção inválida, saindo do script.${reset}"; exit 1;;
  esac
fi

scope_path="$ppath/scope/$id"
roots_exist="$scope_path/roots.txt"

timestamp="$(date +%s)"
scan_path="$ppath/scans/$id-$timestamp"

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
  echo "${yellow}[+] Criando arquivo $roots_exist de $id...${reset}"
  touch "$roots_exist"
  echo "$id.com" >> $roots_exist
  # echo "$id.com.br" >> $roots_exist
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

### ADD SCAN LOGIC HERE ###
cat "$roots_exist" | subfinder | anew subs.txt


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

echo "Scan $id took $time"
#echo "Scan $id took $time" | notify
