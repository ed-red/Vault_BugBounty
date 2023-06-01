#!/bin/bash

#--- seta cores
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

#---- inicia script

# Verifica se o Go já está instalado
echo "${yellow}[+] Verificando se o Go já está instalado${reset}"
if command -v go &>/dev/null; then
    echo "${green}[++] O Go já está instalado.${reset}"
    echo "${green}[++] Versão atual: $(go version)${reset}"
    exit 0
fi

# Define a versão do Go a ser instalada
echo "${yellow}[+] Definindo a versão do Go a ser instalada${reset}"
latest_version=$(curl -sSL https://golang.org/VERSION?m=text)

echo "${yellow}[+] Iniciando a instalação do Go versão $latest_version...${reset}"

# Define o diretório de instalação
install_dir="/usr/local"

# Baixa o arquivo compactado da última versão do Go
echo "${yellow}[+] Baixando o arquivo compactado da última versão do Go${reset}"
wget -q "https://go.dev/dl/$latest_version.linux-amd64.tar.gz" -P /tmp

# Extrai o arquivo compactado para o diretório de instalação
echo "${yellow}[+] Extraindo o arquivo compactado para o diretório de instalação${reset}"
rm -rf $install_dir/go
tar -C $install_dir -xzf "/tmp/$latest_version.linux-amd64.tar.gz"

# Define as variáveis de ambiente para o Go
echo "${yellow}[+] Definindo as variáveis de ambiente para o Go${reset}"
echo "export PATH=\$PATH:$install_dir/go/bin" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.bashrc

# Carrega as variáveis de ambiente
echo "${yellow}[+] Carregando as variáveis de ambiente${reset}"
source ~/.bashrc

# Verifica se a instalação foi bem-sucedida
if command -v go &>/dev/null; then
    echo "${green}[++] A instalação do Go foi concluída com sucesso.${reset}"
    echo "${green}[++] Versão instalada: $(go version)${reset}"
else
    echo "${red}[-] Ocorreu um erro durante a instalação do Go.${reset}"
    exit 1
fi

