#!/bin/bash

#--- SETA CORES
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
RESET=`tput sgr0`

#-- variáveis
export EDITOR='vim'
SCRIPT_DIR="$(dirname $(realpath $0))"
VAULT_BUGBOUNTY_PATH="$(dirname $(dirname $SCRIPT_DIR))"
export DOTFILES=$SCRIPT_DIR

function execute_script() {
  case $1 in
    1) source $DOTFILES/install_upgrade_golang.sh;;
    2) source $DOTFILES/install_tools.sh;;
    3) source $DOTFILES/install_tools_pip3_repo.sh;;
    4) source $DOTFILES/add_param_apis_bashrc;;
    5) source $DOTFILES/install_custom_bash.sh;;
    *) echo -e "${RED}Opção inválida. Por favor, escolha uma opção de 1 a 5.${RESET}";;
  esac
}

while true; do
  echo -e "${YELLOW}==================================${RESET}"
  echo -e "${GREEN}Escolha um script para executar:${RESET}"
  echo "1) Install/Upgrade Golang - ${CYAN}($DOTFILES/install_upgrade_golang.sh)${RESET}"
  echo "2) Install Tools - ${CYAN}($DOTFILES/install_tools.sh)${RESET}"
  echo "3) Install Tools from Pip3 Repo - ${CYAN}($DOTFILES/install_tools_pip3_repo.sh)${RESET}"
  echo "4) Add Param APIs to Bashrc - ${CYAN}($DOTFILES/add_param_apis_bashrc)${RESET}"
  echo "5) Install Custom Bash - ${CYAN}($DOTFILES/install_custom_bash.sh)${RESET}"
  echo -e "${RED}6) Sair${RESET}"
  echo -e "${YELLOW}==================================${RESET}"
  read -p "Insira a opção desejada (1-6): " option

  if [ $option -eq 6 ]; then
    echo -e "${BLUE}Saindo...${RESET}"
    exit
  fi

  execute_script $option
done
