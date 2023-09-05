#!/bin/bash

# Cores
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
RESET=`tput sgr0`

# Caminho base
BASE_PATH="/root/recons"

# Lista de empresas
COMPANIES_FILE="${BASE_PATH}/companies.txt"
COMPANIES_AVULSOS_FILE="${BASE_PATH}/companies_avulsos.txt"

# set vars
GIT_ROOT=$(git rev-parse --show-toplevel)

# Função para obter o nome base do domínio (sem TLD)
get_base_name() {
    echo $1 | cut -f1 -d'.'
}

# Função para mostrar o escopo de uma empresa
show_scope() {
    local company=$1
    local scope_file="${BASE_PATH}/scope/${company}/scope.txt"
    
    # Verifica se a empresa está no arquivo companies.txt ou companies_avulsos.txt
    if grep -Fxq "$company" $COMPANIES_FILE || grep -Fxq "$company" $COMPANIES_AVULSOS_FILE; then
        if [[ -f $scope_file ]]; then
            echo "${YELLOW}---------------------------------------------${RESET}"
            echo "${GREEN}Escopo para ${RESET}${BLUE}${company}${RESET}:"
            cat $scope_file
            echo "${YELLOW}---------------------------------------------${RESET}"
        else
            echo "${RED}Erro: Arquivo de escopo para ${BLUE}${company}${RESET}${RED} não encontrado.${RESET}"
        fi
    else
        echo "${RED}${BLUE}${company}${RESET}${RED} não encontrado em ${COMPANIES_FILE} nem em ${COMPANIES_AVULSOS_FILE}.${RESET}"
    fi
}

# Função para executar o scan para uma empresa
run_scan() {
    local company=$(get_base_name $1)
    local SCAN_PATH="${BASE_PATH}/scans/${company}"

    export roots_exist="${BASE_PATH}/scope/${company}/scope.txt"
    export scan_path=$SCAN_PATH

    mkdir -p $SCAN_PATH && cd $scan_path
    cp "$roots_exist" "$scan_path/scope.txt"
    # cat "$roots_exist" | anew "$scan_path/subs.txt"
    source /root/Vault_BugBounty/scripts/bot_scan_recon_vuln.sh
}

# Função para adicionar uma nova empresa e seu escopo
add_new_company() {
    local company=$(get_base_name $1)
    echo "$company" >> $COMPANIES_AVULSOS_FILE
    mkdir -p "${BASE_PATH}/scope/${company}"
    echo "$1" >> "${BASE_PATH}/scope/${company}/scope.txt"
    echo "${GREEN}Empresa ${BLUE}${company}${RESET}${GREEN} adicionada com sucesso ao arquivo avulso!${RESET}"
}

# Função para adicionar mais domínios ao escopo de uma empresa
add_to_scope() {
    local company=$(get_base_name $1)
    while true; do
        read -p "${YELLOW}Informe o domínio para adicionar ao escopo de ${BLUE}${company}${RESET}${YELLOW} ou 'q' para sair: ${RESET}" domain
        if [[ "$domain" == "q" ]]; then
            break
        fi
        echo $domain >> "${BASE_PATH}/scope/${company}/scope.txt"
        echo "${GREEN}Domínio ${domain} adicionado ao escopo de ${BLUE}${company}${RESET}.${GREEN}"
    done
}

# Processando argumentos
EXCLUSION_MODE=0
EXCLUSIONS=()
ADDR=()
for arg in "$@"; do
    if [[ "$arg" == "-ex" ]]; then
        EXCLUSION_MODE=1
        continue
    fi

    if [[ $EXCLUSION_MODE -eq 1 ]]; then
        IFS=',' read -ra SPLIT_ARG <<< "$arg"
        for ex in "${SPLIT_ARG[@]}"; do
            EXCLUSIONS+=("$ex")
        done
    else
        ADDR+=("$arg")
    fi
done

# Se o primeiro argumento for "all", carregue todas as empresas do companies.txt
# Se o primeiro argumento for "all", carregue todas as empresas do companies.txt E companies_avulsos.txt
if [[ "${ADDR[0]}" == "all" ]]; then
    readarray -t ADDR < "$COMPANIES_FILE"
    readarray -t AVULSOS < "$COMPANIES_AVULSOS_FILE"
    ADDR=("${ADDR[@]}" "${AVULSOS[@]}")
fi

# Mostrando as empresas excluídas
if [[ ${#EXCLUSIONS[@]} -gt 0 ]]; then
    excluded_companies=$(IFS=','; echo "${EXCLUSIONS[*]}")
    echo "${RED}${excluded_companies}${RESET}${BLUE} estão excluídos. Pulando...${RESET}"
fi

for domain in "${ADDR[@]}"; do
    # Verifique se o domínio está na lista de exclusões
    if [[ " ${EXCLUSIONS[@]} " =~ " ${domain} " ]]; then
        continue
    fi

    domain=$(echo "$domain" | xargs)
    company=$(get_base_name $domain)

    # Verifica se a empresa está na lista de companies.txt ou companies_avulsos.txt
    if grep -Fxq "$company" $COMPANIES_FILE || grep -Fxq "$company" $COMPANIES_AVULSOS_FILE; then
        show_scope $company
    else
        echo "${RED}${BLUE}${company}${RESET}${RED} não encontrado em ${COMPANIES_FILE} nem em ${COMPANIES_AVULSOS_FILE}.${RESET}"
        read -p "${YELLOW}Deseja adicionar ${BLUE}${company}${RESET}${YELLOW} ao arquivo 'companies_avulsos.txt' e definir ${RESET}${BLUE}${domain}${RESET}${YELLOW} como seu escopo inicial? (s/n) ${RESET}" choice

        case $choice in
            [Ss]* ) 
                add_new_company $domain
                add_to_scope $domain;;
            * ) 
                echo "${RED}${domain} não foi adicionado.${RESET}";;
        esac
    fi
done

read -p "${YELLOW}Deseja realizar o scan para todas as empresas listadas acima? (s/n) ${RESET}" choice
case $choice in
    [Ss]* ) 
        for domain in "${ADDR[@]}"; do
            # Verifique se o domínio está na lista de exclusões
            if [[ " ${EXCLUSIONS[@]} " =~ " ${domain} " ]]; then
                continue
            fi

            domain=$(echo "$domain" | xargs)
            run_scan $domain
        done;;
    [Nn]* ) 
        echo "${RED}Scan para todas as empresas foi pulado.${RESET}";;
    * ) 
        echo "${RED}Resposta inválida. Por favor, responda com 's' ou 'n'.${RESET}";;
esac
