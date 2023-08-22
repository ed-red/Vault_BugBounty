#!/bin/bash

# Install para não dar erro:
# apt install -y libpcap-dev por que dava pau com uma tool de godasdsa

#------- Variáveis
git_root=$(git rev-parse --show-toplevel)
URL_RUST="https://sh.rustup.rs"
GO_TOOLS=$(curl -s https://raw.githubusercontent.com/ed-red/Vault_BugBounty/main/tools/add_me_go_tools.txt)
PIP3_TOOLS=$(curl -s https://raw.githubusercontent.com/ed-red/Vault_BugBounty/main/tools/add_me_pip3_tools.txt)
# GO_TOOLS=$(cat $git_root/tools/add_me_go_tools.txt)
# PIP3_TOOLS=$(cat $git_root/tools/add_me_pip3_tools.txt)
errors=""

#--- Cores
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

# Ajustando Clock TimeZone + Date
timedatectl set-timezone America/Sao_Paulo

# Função para verificar se um pacote Go está instalado
package_installed() {
    local package="$1"
    bin_name=$(basename "$package")
    command -v "$bin_name" >/dev/null 2>&1
}

# Instalando Golang Tools
echo "${yellow}[+] Installing Golang Tools ${reset}"

echo "$GO_TOOLS" | while read -r tool
do
    tool_name=$(echo $tool | sed -E 's#(https://github.com/|github.com/)(.*)@latest#\2#')
    bin_name=$(basename "$tool_name")

    echo "${blue}[+] Instalando a ferramenta $bin_name...${reset}"
    output=$(GO111MODULE=on go install $tool 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "${green}[++] Ferramenta $bin_name foi instalada com sucesso.${reset}"
    else
        echo "${red}[-] Erro na instalação de $bin_name com go install${reset}"
        errors="${errors}\n${red}Erro na instalação de $bin_name:${reset}\n$output\n"
    fi
done

if [ -n "$errors" ]; then
    echo -e "\n${red}Erros encontrados durante a instalação:${reset}"
    echo -e "\n${cyan}$tool${reset}"
    echo -e "$errors"
else
    echo "${green}[**] Todas as ferramentas foram instaladas com sucesso.${reset}"
fi

# Instalar Ferramentas com o PIP3
echo "${yellow}[+] Installing PIP3 Tools ${reset}"

for tool in $PIP3_TOOLS
do
    if pip3 show "$tool" &>/dev/null; then
        echo "${green}[*] O pacote $tool já está instalado.${reset}"
    else
        echo "${blue}[++] Iniciando a instalação do pacote $tool...${reset}"
        if pip3 install --upgrade "$tool"; then
            echo "${green}[+] O pacote $tool foi instalado com sucesso.${reset}"
        else
            echo "${red}[-] Ocorreu um erro durante a instalação do pacote $tool.${reset}"
        fi
    fi
done

echo "${yellow}[*] Instalação de pacotes concluída.${reset}"

