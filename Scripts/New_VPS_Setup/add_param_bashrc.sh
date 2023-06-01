#!/bin/bash

#--- seta cores
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

#---- inicia script
# Define as variáveis de ambiente para as APIs das tools

# export SHODAN_API_KEY=xxx
# export CENSYS_API_ID=xxx
# export CENSYS_API_SECRET=xxx
# export FOFA_EMAIL=xxx
# export FOFA_KEY=xxx
# export QUAKE_TOKEN=xxx
# export HUNTER_API_KEY=xxx
# export ZOOMEYE_API_KEY=xxx
# export NETLAS_API_KEY=xxx
# export CRIMINALIP_API_KEY=xxx
# export PUBLICWWW_API_KEY=xxx

echo "${yellow}[+] Definindo as variáveis com as APIs das tools${reset}"
echo "export SHODAN_API_KEY=$SHODAN_API_KEY" >> ~/.bashrc