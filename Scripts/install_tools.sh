#!/bin/bash

# Install para não dar erro:
# apt install -y libpcap-dev

#------- Variáveis
URL_RUST="https://sh.rustup.rs"
GO_TOOLS=$(curl -s https://raw.githubusercontent.com/ed-red/Vault_BugBounty/main/Tools/add_me_go_tools.txt)
PIP3_TOOLS=(
    turbosearch
    pyccat
)
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

#---- script
echo "${yellow}[+] Atualizando Ubuntu ... ${reset}"
apt update
echo "${yellow}[+] Start Full-Upgrade Ubuntu ... ${reset}"
apt full-upgrade -y
echo "${green}[+] Finalizou Full-Upgrade Ubuntu ... ${reset}"

echo "${yellow}[+] Instalando Bash-completion ... ${reset}"
apt install bash-completion

# Verifica se o Rust já está instalado
if [ -x "$(command -v rustc)" ]; then
    echo "${green}[++] O Rust já está instalado.${reset}"
else
    echo "${red}[-] O Rust não está instalado.${reset}"

    # Instalando o Rust
    echo "${yellow}[+] Installing Rust ${reset}"

    # Baixa o script rustup-init
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup-init.sh

    # Executa o script rustup-init para instalar o Rust
    chmod +x rustup-init.sh
    ./rustup-init.sh -y

    # Verifica se a instalação foi bem-sucedida
    if [ $? -eq 0 ]; then
        echo "${green}[++] Rust foi instalado com sucesso.${reset}"
        echo "${yellow}[++] Carregando as configurações do Rust...${reset}"
        source $HOME/.cargo/env
    else
        echo "${red}[-] Ocorreu um erro durante a instalação do Rust.${reset}"
        exit 1
    fi

    # Verifica a versão do Rust instalada
    rustc --version
fi

# Final da instalação do Rust

# Instalação Pacotes Base
echo "${yellow}[+] Instalando pacotes base${reset}"
apt update
apt install -y vim-nox \
                tmux \
                git \
                exuberant-ctags \
                zsh \
                tree \
                htop \
                ncurses-term \
                silversearcher-ag \
                curl \
                npm \
                libpcap-dev

# Instalação Pacotes Base-Dev
echo "${yellow}[+] Instalando base-dev libs ... ${reset}"
apt install -y build-essential \
              git \
              vim \
              xclip \
              curl \
              wget
apt install -y python3 \
              python3-pip \
              build-essential \
              gcc \
              cmake \
              ruby \
              git \
              curl \
              libpcap-dev \
              zip \
              python3-dev \
              pv \
              dnsutils \
              libssl-dev \
              libffi-dev \
              libxml2-dev \
              libxslt1-dev \
              zlib1g-dev \
              jq \
              apt-transport-https \
              xvfb \
              prips $DEBUG_STD
echo "${green}[*] Feito. ${reset}"

# Função para verificar se um pacote Go está instalado
package_installed() {
    local package="$1"
    go list -e -f '{{.ImportPath}}' "$package" >/dev/null 2>&1
}

# Instalando Golang Tools
echo "${yellow}[+] Installing Golang Tools ${reset}"

for tool in $GO_TOOLS
do
    tool_name=$(echo $tool | sed -E 's#(https://github.com/|github.com/)(.*)@latest#\2#')

    if package_installed "$tool_name"; then
        echo "${green}[*] O pacote $tool_name já está instalado.${reset}"
    else
        echo "${blue}[+] Instalando a ferramenta $tool_name...${reset}"
        output=$(GO111MODULE=on go install $tool 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "${green}[++] Instalação bem sucedida de $tool_name${reset}"
        else
            echo "${red}[-] Erro na instalação de $tool_name com go install${reset}"
            output=$(GO111MODULE=on go get -u $tool 2>&1)
            
            if [ $? -eq 0 ]; then
                echo "${green}[++] Instalação bem sucedida de $tool_name com go get -u${reset}"
            else
                echo "${red}[-] Erro na instalação de $tool_name com go get -u${reset}"
                errors="${errors}\n${red}Erro na instalação de $tool_name:${reset}\n$output\n"
            fi
        fi
    fi
done

if [ -n "$errors" ]; then
    echo -e "\n${red}Erros encontrados durante a instalação:${reset}"
    echo -e "$errors"
else
    echo "${green}[**] Todas as ferramentas foram instaladas com sucesso.${reset}"
fi

# Instalar Ferramentas com o Pip3
# - [ ] TurboSearch


echo "${yellow}[+] Installing PIP3 Tools ${reset}"

for tool in "${PIP3_TOOLS[@]}"
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
