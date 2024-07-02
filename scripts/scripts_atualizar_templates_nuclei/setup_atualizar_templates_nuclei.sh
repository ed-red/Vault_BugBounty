#!/bin/bash

# Definindo as cores
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

source ~/.bashrc

# Variáveis
date="$(date +%d-%m-%Y_%Hh-%Mm-%Ss)"
github_token=$GITHUB_TOKEN

# Diretório dos scripts
echo "${yellow}[+] Mudando para o diretório dos scripts...${reset}"
if cd /root/Vault_BugBounty/scripts/scripts_atualizar_templates_nuclei; then
    echo "${green}[++] Diretório dos scripts encontrado.${reset}"
else
    echo "${red}[-] Diretório dos scripts não encontrado.${reset}"
    exit 1
fi

pwd

# Passo 1: Atualizar com o comando newclei
# echo -e "${yellow}========================================${NC}\n" | $HOME/go/bin/notify -silent -bulk
# echo -e NUCLEI ATUALIZANDO... $(date) | $HOME/go/bin/notify -silent -bulk
echo "${yellow}[+] Atualizando com o comando newclei...(newclei -token $github_token | anew links.txt | wc -l)${reset}"
if ! newclei -token $github_token | anew links.txt ; then
    echo "${red}[-] Erro ao executar o comando newclei.${reset}"
    exit 1
fi

# Passo 2: Executar o script Python para puxar os templates
echo "${yellow}[+] Executando o script Python para puxar os templates...${reset}"
if ! python3 /root/Vault_BugBounty/scripts/scripts_atualizar_templates_nuclei/bot_puxar_templates_nuclei.py; then
    echo "${red}[-] Erro ao executar o script Python.${reset}"
    exit 1
fi

# Passo 3: Ir para o diretório do repositório e dar um pull
echo "${yellow}[+] Mudando para o diretório do repositório e atualizando Git...${reset}"
if cd /root/Vault_BugBounty/redmc_custom_templates_nuclei; then
    echo "${green}[++] Diretório do repositório encontrado.${reset}"
else
    echo "${red}[-] Diretório do repositório não encontrado.${reset}"
    exit 1
fi
pwd

echo "${yellow}[+] git commit -m 'Atualização Templates - $date'...${reset}"
git add .
git commit -m "Atualização Templates - $date"
echo "${yellow}[+] git push origin main:main...${reset}"
git push origin main:main

# Passo 4: Ir para o diretório do repositório e dar um pull
echo "${yellow}[+] Mudando para o diretório do repositório e atualizando Git...${reset}"
if cd /root/Vault_BugBounty; then
    echo "${green}[++] Diretório do repositório encontrado.${reset}"
else
    echo "${red}[-] Diretório do repositório não encontrado.${reset}"
    exit 1
fi
pwd

echo "${yellow}[+] git commit -m 'Atualização Templates Nuclei - $date'...${reset}"
git add .
git commit -m "Atualização Templates - $date"
echo "${yellow}[+] git push origin main:main...${reset}"
git push origin main:main

# Passo 4: Atualizar os templates do nuclei
echo "${yellow}[+] Atualizando os templates do nuclei...${reset}"
if ! nuclei -update-templates; then
    echo "${red}[-] Erro ao atualizar os templates do nuclei.${reset}"
    exit 1
fi
