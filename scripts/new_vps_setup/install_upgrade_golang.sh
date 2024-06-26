#!/bin/bash

#--- seta cores
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

#---- inicia script
# Define a versão do Go mais atual
echo "${yellow}[+] Definindo a versão do Go a ser instalada...${reset}"
latest_version=$(curl -sSL https://golang.org/VERSION?m=text | head -n 1)
echo "${yellow}[+] A última versão do Go é a $latest_version...${reset}"

# Verifica se o Go já está instalado
echo "${yellow}[+]${reset}"
echo "${cyan}[+] Verificando se a versão $latest_version do Go já está instalada...${reset}"
if command -v go &>/dev/null; then
    current_version=$(go version | awk '{print $3}')
    if [[ "$current_version" == "$latest_version" ]]; then
        echo "${green}[++] O Go já está instalado na versão mais recente: $latest_version.${reset}"
        echo "${yellow}[+]${reset}"
    fi
fi

echo "${yellow}[+] Iniciando a instalação/atualização do Go para a versão $latest_version, a mais recente...${reset}"

# Define o diretório de instalação
install_dir="/usr/local"

# Baixa o arquivo compactado da última versão do Go
echo "${yellow}[+] Baixando o arquivo compactado da última versão do Go${reset}"
wget -q "https://go.dev/dl/$latest_version.linux-amd64.tar.gz" -P /tmp

# Extrai o arquivo compactado para o diretório de instalação
echo "${yellow}[+] Extraindo o arquivo compactado para o diretório de instalação${reset}"
sudo rm -rf "$install_dir/go"
sudo tar -C $install_dir -xzf "/tmp/$latest_version.linux-amd64.tar.gz"

# Função para adicionar uma linha ao .bashrc se não existir
add_to_bashrc_if_not_exists() {
    local line="$1"
    local file="$2"
    grep -qxF "$line" "$file" || echo "$line" >> "$file"
}

# Define as variáveis de ambiente para o Go
echo "${yellow}[+] Definindo as variáveis de ambiente para o Go${reset}"
add_to_bashrc_if_not_exists "export PATH=\$PATH:$install_dir/go/bin" ~/.bashrc
add_to_bashrc_if_not_exists "export GOPATH=\$HOME/go" ~/.bashrc
add_to_bashrc_if_not_exists "export PATH=\$PATH:\$GOPATH/bin" ~/.bashrc

# Carrega as variáveis de ambiente na sessão atual do script
export PATH=$PATH:$install_dir/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Verifica se a instalação foi bem-sucedida
if command -v go &>/dev/null; then
    echo "${green}[++] A instalação do Go foi concluída com sucesso.${reset}"
    echo "${green}[++] Versão instalada: $(go version)${reset}"
else
    echo "${red}[-] Ocorreu um erro durante a instalação do Go.${reset}"
    exit 1
fi
