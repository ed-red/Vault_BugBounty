#!/bin/bash
# Definindo as cores
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

source ~/.bashrc

# Variaveis
date="$(date +%d-%m-%Y_%Hh-%Mm-%Ss)"
github_token=$GITHUB_TOKEN

# Diretório dos scripts
echo "${yellow}[+] Mudando para o diretório dos scripts...${reset}"
cd /root/Vault_BugBounty/scripts/scripts_atualizar_templates_nuclei

# Passo 1: Atualizar com o comando newclei
echo "${yellow}[+] Atualizando com o comando newclei...(newclei -token $github_token | anew links.txt | wc -l)${reset}"
newclei -token $github_token | anew links.txt | wc -l | notify -silent

# Passo 2: Executar o script Python para puxar os templates
echo "${yellow}[+] Executando o script Python para puxar os templates...${reset}"
python3 bot_puxar_templates_nuclei.py

# Passo 3: Ir para o diretório do repositório e dar um pull
echo "${yellow}[+] Mudando para o diretório do repositório e atualizando Git...${reset}"
cd /root/Vault_BugBounty/redmc_custom_templates_nuclei
pwd

echo "${yellow}[+] git commit -m "Atualização Templates - $date"...${reset}"
git add .
git commit -m "Atualização Templates - $date"
echo "${yellow}[+] git push origin main:main...${reset}"
git push origin main:main

# Passo 4: Ir para o diretório do repositório e dar um pull
echo "${yellow}[+] Mudando para o diretório do repositório e atualizando Git...${reset}"
cd /root/Vault_BugBounty
pwd

echo "${yellow}[+] git commit -m "Atualização Templates Nuclei - $date"...${reset}"
git add .
git commit -m "Atualização Templates - $date"
echo "${yellow}[+] git push origin main:main...${reset}"
git push origin main:main

# Passo 4: Atualizar os templates do nuclei
echo "${yellow}[+] Atualizando os templates do nuclei...${reset}"
nuclei -update-templates
