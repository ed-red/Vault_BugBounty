#!/bin/bash

# -- Criar pasta .secret e arquivo .apis:
# SHODAN_API_KEY=xxx
# CENSYS_API_ID=xxx
# CENSYS_API_SECRET=xxx
# FOFA_EMAIL=xxx
# FOFA_KEY=xxx
# QUAKE_TOKEN=xxx
# HUNTER_API_KEY=xxx
# ZOOMEYE_API_KEY=xxx
# NETLAS_API_KEY=xxx
# CRIMINALIP_API_KEY=xxx
# PUBLICWWW_API_KEY=xxx

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

#---- inicia script

# Carrega as variáveis do arquivo apis.sh
source $HOME/Vault_BugBounty/.secrets/apis.sh

# Define a localização do arquivo .bashrc
bashrc_file="$HOME/.bashrc"

# Adiciona as variáveis ao arquivo .bashrc
echo "${yellow}[+] Definindo as variáveis com as APIs das tools${reset}"
while read -r line
do
    if [[ "$line" == *=* && "$line" != "#"* ]]; then
        var_name="${line%%=*}"
        var_value="${line#*=}"
        if ! grep -q "export $var_name=$var_value" "$bashrc_file"; then
            echo "${yellow}[-] Variáveis $var_name não existe... aplicando... ${reset}"
            echo "export $var_name=$var_value" >> "$bashrc_file"
            echo "${green}[++] Variáveis $var_name aplicada!! ${reset}"
        else
            echo "${green}[++] Variáveis $var_name já existe! ${reset}"
        fi
    fi
done < $HOME/Vault_BugBounty/.secrets/apis.sh

echo "${green}[+] As variáveis foram adicionadas ao arquivo .bashrc com sucesso.${reset}"
