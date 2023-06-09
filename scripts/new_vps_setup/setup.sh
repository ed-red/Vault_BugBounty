#!/bin/bash

#-- variaveis
export EDITOR='vim'
export DOTFILES=$PWD
# DOTFILES=$(git rev-parse --show-toplevel)

source $DOTFILES/install_upgrade_golang.sh
source $DOTFILES/install_tools.sh
source $DOTFILES/install_tools_pip3_repo.sh
# source $DOTFILES/add_param_apis_bashrc
# source $DOTFILES/install_custom_bash.sh
