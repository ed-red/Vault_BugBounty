#!/bin/bash

# Tools para estudar se vai ser util para alguma coisa:
# https://github.com/junegunn/fzf

#------- Variáveis
git_root=$(git rev-parse --show-toplevel)
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
echo "${green}[+] Finalizou full-upgrade Ubuntu ... ${reset}"

# Instalação Pacotes Base
echo "${yellow}[+] Instalando Pacotes Base...${reset}"
apt update
apt install -y git \
                bash-completion \
                gawk \
                make \
                cmake \
                shellcheck \
                htop

echo "${yellow}[+] Instalando Ble.sh ... ${reset}"
# Fonte: https://github.com/akinomyoga/ble.sh

cd $HOME
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local
# Verifica se a linha já está no .bashrc
if grep -Fxq "source ~/.local/share/blesh/ble.sh" ~/.bashrc
then
    echo "ble.sh já está configurado no .bashrc."
else
    echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
fi
sleep 2

# Definindo parametros de customização do ble.sh
echo "A instalação foi concluída. Por favor, execute os seguintes comandos para concluir a configuração:"
## ble-face >> Muda a cor dos highlight:
# ble-face auto_complete=bg=254,fg=238
echo "ble-face auto_complete=fg=gray"
echo "ble-face region_insert=fg=238,bg=254"
## remove as cores dos highlights, = ou =1 para ativar
echo "bleopt highlight_syntax="
## Compartilha o historico dos comandos com outras sessões
echo "bleopt history_share=1"


echo "source ~/.local/share/blesh/ble.sh"





echo "${yellow}[+] Instalando Bash.it ... ${reset}"
