#!/bin/bash

#------- Variáveis
GO_TOOLS=$(curl -s https://raw.githubusercontent.com/ed-red/Vault_BugBounty/main/Tools/add_me_go_tools.txt)
PIP3_TOOLS=$(curl -s https://raw.githubusercontent.com/ed-red/Vault_BugBounty/main/Tools/add_me_pip3_tools.txt)
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
declare -A repos
repos["Sublist3r"]="aboul3la/Sublist3r"
repos["gf"]="tomnomnom/gf"
repos["Gf-Patterns"]="1ndianl33t/Gf-Patterns"
repos["LinkFinder"]="dark-warlord14/LinkFinder"
repos["Interlace"]="codingo/Interlace"
repos["JSScanner"]="0x240x23elu/JSScanner"
repos["GitTools"]="internetwache/GitTools"
repos["SecretFinder"]="m4ll0k/SecretFinder"
repos["M4ll0k"]="m4ll0k/BBTz"
repos["Git-Dumper"]="arthaud/git-dumper"
repos["CORStest"]="RUB-NDS/CORStest"
repos["Knock"]="guelfoweb/knock"
repos["Photon"]="s0md3v/Photon"
repos["Sudomy"]="screetsec/Sudomy"
repos["DNSvalidator"]="vortexau/dnsvalidator"
repos["Massdns"]="blechschmidt/massdns"
repos["Dirsearch"]="maurosoria/dirsearch"
repos["Knoxnl"]="xnl-h4ck3r/knoxnl"
repos["xnLinkFinder"]="xnl-h4ck3r/xnLinkFinder"
repos["MSwellDOTS"]="mswell/dotfiles"
repos["Waymore"]="xnl-h4ck3r/waymore"
repos["altdns"]="infosec-au/altdns"
repos["XSStrike-Reborn"]="ItsIgnacioPortal/XSStrike-Reborn"

dir="$HOME/Tools"

mkdir -p ~/Tools/

cd "$dir" || {
    echo "Failed to cd to $dir in ${FUNCNAME[0]} @ line ${LINENO}"
    exit 1
}

# Standard repos installation
repos_step=0
for repo in "${!repos[@]}"; do
    # Verifica se o diretório do repositório já existe
    echo "${yellow}[+] Verificando se "${repo,,}" já está instalado...${reset}"
    if [ -d "$dir/$repo" ]; then
        echo "${green}[+][+] O pacote $repo já está instalado. Pulando a instalação...${reset}"
        continue
    fi

    echo "${yellow}[+] Não existe, baixando o "${repos[$repo]}" do Github para a pasta $dir... ${reset}"
    repos_step=$((repos_step + 1))
    eval git clone https://github.com/${repos[$repo]} $dir/$repo 

    eval cd $dir/$repo
    eval git pull
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        printf "${yellow} $repo installed (${repos_step}/${#repos[@]})${reset}\n"
    else
        printf "${red} Unable to install $repo, try manually (${repos_step}/${#repos[@]})${reset}\n"
        continue
    fi
    if [ -s "requirements.txt" ]; then
        echo "${yellow}[+] Instalando os requirements do "${repos[$repo]}"... ${reset}"
        eval $SUDO pip3 install -r requirements.txt
        echo "${green}[++] Requirements Instalado "${repos[$repo]}"... ${reset}"
    fi
    if [ -s "setup.py" ]; then
        echo "${yellow}[+] Instalando o setup.py do "${repos[$repo]}"... ${reset}"
        eval $SUDO python3 setup.py install
        echo "${green}[++] Setup.py Instalado "${repos[$repo]}"... ${reset}"
    fi
    if [ -s "Makefile" ]; then
        echo "${yellow}[+] Instalando com Make "${repos[$repo]}"... ${reset}"
        eval $SUDO make 
        eval $SUDO make install 
    fi

    if [ "gf" = "$repo" ]; then
        eval cp -r examples/*.json ~/.gf
    elif [ "Gf-Patterns" = "$repo" ]; then
        eval mv *.json ~/.gf
    fi

    cd "$dir" || {
        echo "Failed to cd to $dir in ${FUNCNAME[0]} @ line ${LINENO}"
        exit 1
    }
done
