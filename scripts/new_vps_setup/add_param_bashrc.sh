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
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

#---- inicia script

# Carrega as variáveis do arquivo apis.sh
source $HOME/Vault_BugBounty/.secrets/apis.sh

# Define a localização do arquivo .bashrc
bashrc_file="$HOME/.bashrc"

# Adiciona as variáveis ao arquivo .bashrc
echo "${yellow}[+] Definindo as variáveis com as APIs das tools${reset}"
echo "export SHODAN_API_KEY=$SHODAN_API_KEY" >> "$bashrc_file"

echo "${green}[+] As variáveis foram adicionadas ao arquivo .bashrc com sucesso.${reset}"
