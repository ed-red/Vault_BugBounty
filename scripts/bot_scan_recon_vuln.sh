#!/bin/bash
# set -x
START_TIME=$(date +%s)

#-- variaveis
export EDITOR='vim'
export DOTFILES=$PWD
# DOTFILES=$(git rev-parse --show-toplevel)
# roots_exist=$1
# scan_path=$2

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

echo "${blue}Script iniciou em - $(date +%d-%m-%Y-%H:%M:%S)${reset}"

date="$(date +%d-%m-%Y-%H:%M:%S)"

SUBDOM_LIST="$GIT_ROOT/wordlists/subdomains/httparchive_subdomains_2024_05_28.txt"
RESOLVERS="$GIT_ROOT/wordlists/resolvers/resolvers.txt"

echo $GIT_ROOT
echo $SUBDOM_LIST
echo $RESOLVERS
echo $scan_path
echo $roots_exist
# cd $scan_path
pwd

# Menu principal
menu() {
    echo "${yellow}Escolha uma opção:${reset}"
    echo "1. Enumeração /Resolved / Vulnerabilidades"
    echo "2. Enumeração de subdomínios + Executando resolver URLs buscadas"
    echo "3. Executando resolver URLs buscadas + Verificação de vulnerabilidades"
    echo "4. Verificação de vulnerabilidades"
    echo "5. Sair"
    read -p "Selecione uma opção [1-4]: " opt
}

# Função para verificar qual processo foi concluído
check_complete() {
    task_name=$1
    count_subs=$2
    funcion_text=$3
    echo "${green}A tarefa '$task_name' foi concluída às $(date '+%H:%M:%S') e pegou $count_subs $funcion_text.${reset}"
}

PROCESSES=100
export scan_path

##################################################---ENUMERATION---######################################################
subdomain_enum() {
    # Seu código de enumeração de subdomínio vai aqui...
    echo "---------------------------------------------"
    echo "${yellow}[+] DNS Enumeration - Find Subdomains...${reset}"
    # Verifique se o arquivo "subs.txt" existe e obtenha a contagem de linhas
    if [[ -f "subs.txt" ]]; then
        prev_count=$(wc -l < "subs.txt")
        echo "${green}[+] Número de subdominios em subs.txt antes: $prev_count${reset}."
    else
        echo "O arquivo subs.txt não existe. Contagem definida como 0."
        prev_count=0
    fi
    # cat "$roots_exist" | xargs -I {} amass enum -d {} -dir "$scan_path/amass-outputs"
    # cat "$roots_exist" | xargs -I {} amass db -names -d {} | anew subs.txt

    # cat "$roots_exist" | haktrails subdomains | anew subs.txt
    # cat "$roots_exist" | subfinder | anew subs.txt
    # cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew subs.txt
    # awk '{print "http://" $0; print "https://" $0}' $roots_exist | katana -f fqdn | anew subs.txt

    # Pre-defina o número de processos paralelos

    echo "${yellow}Iniciando a enumeração de subdomínios...${reset}"


    # Função para o amass
    # amass_func() {
    #     domain="$1"
    #     echo "${blue}Processando $domain com amass...${reset}"
    #     cat "$roots_exist" | xargs -I {} amass enum -d {} -dir "$scan_path/amass-outputs" && cat "$roots_exist" | xargs -I {} amass db -names -d {} | anew subs.txt
    #     check_complete "Amass" "$(wc -l subs.txt)"
    # }

    # export -f amass_func
    export scan_path

    # Execute todos os comandos em paralelo
    # (cat "$roots_exist" | xargs -I {} sh -c "amass enum -silent -d {} -dir $scan_path/amass-outputs && amass db -names -d {} | anew subs.txt" && check_complete "Amass" "$(wc -l subs.txt)") &
    # echo "${green}Amass em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe haktrails subdomains | anew subs.txt && check_complete "Haktrails" "$(wc -l subs.txt)")
    echo "${green}Haktrails em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe subfinder -silent | anew subs.txt && check_complete "Subfinder" "$(wc -l subs.txt)")
    echo "${green}Subfinder em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" -silent | anew subs.txt && check_complete "Shuffledns" "$(wc -l subs.txt)")
    echo "${green}Shuffledns em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe "awk '{print \"http://\" \$0; print \"https://\" \$0}'" | katana -f fqdn -silent | anew subs.txt && check_complete "Katana Recon subs" "$(wc -l subs.txt)")
    echo "${green}Katana Recon subs em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe alterx -l -silent | anew subs.txt && check_complete "Alterx" "$(wc -l subs.txt)")
    echo "${green}Alterx em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES chaos -d | anew subs.txt && check_complete "Chaos" "$(wc -l subs.txt)")
    echo "${green}Chaos em andamento...${reset}"
    # Aguarde todos os comandos em segundo plano serem concluídos
    wait

    echo "${green}Todas as tarefas foram concluídas!${reset}"

    # Contagem após a execução dos comandos
    if [[ -f "subs.txt" ]]; then
        new_count=$(wc -l < "subs.txt")
    else
        echo "O arquivo subs.txt não existe após a execução. Contagem definida como 0."
        new_count=0
    fi
    # Exibindo o comparativo
    echo "---------------------------------------------"
    echo "${green}Número de subdominios em subs.txt antes: $prev_count${reset}"
    echo "${green}Número de subdominios em subs.txt agora: $new_count${reset}"
    qnt_dominios_scan_path=$(wc -l subs.txt)
    echo "---------------------------------------------"
    echo "${green}$(wc -l subs.txt) domínios adicionados com sucesso!${reset}"
    echo "---------------------------------------------"

    # Tempo final
    echo "---------------------------------------------"
    END_TIME=$(date +%s)

    ELAPSED_TIME=$(($END_TIME - $START_TIME))
    echo "${blue}Script Terminou em - $(date +%d-%m-%Y-%H:%M:%S)${reset}"
    echo "${green}Tempo total de execução: $ELAPSED_TIME segundos${reset}"
    echo "---------------------------------------------"

    echo "${green}Enumeração de subdomínios concluída!${reset}"
}

##################################################---RECON---############################################################
resolved_verified() {
    echo "---------------------------------------------"
    echo "${yellow}[+] DNS Resolution - Resolve Discovered Subdomains...${reset}"
    echo $scan_path
    if [[ -f "$scan_path/subs_resolved.txt" ]]; then
        prev_count=$(wc -l < "$scan_path/subs_resolved.txt")
        echo "${green}[+] Número de subdominios Resolvidos em subs_resolved.txt antes: $prev_count${reset}."
    else
        echo "O arquivo subs_resolved.txt não existe. Contagem definida como 0."
        prev_count=0
        touch $scan_path/subs_resolved.txt
    fi

    puredns resolve $scan_path/subs.txt -r "$RESOLVERS" -q | anew subs_resolved.txt && check_complete "Puredns" "$(wc -l $scan_path/subs_resolved.txt)" "Subs Resolvidas"
    echo "${green}Puredns em andamento...${reset}"
    
    cat $scan_path/subs.txt | httpx | anew subs_resolved.txt && check_complete "httpx" "$(wc -l $scan_path/subs_resolved.txt)" "Subs Resolvidas"
    echo "${green}httpx em andamento...${reset}"

    # puredns resolve "$scan_path/subs.txt" -r "$RESOLVERS" -w "$scan_path/subs_resolved.txt" | wc -l
    # cat "$scan_path/subs.txt" | httpx -o "$scan_path/subs_resolved.txt"
    dnsx -silent -l "$scan_path/subs_resolved.txt" -json -o "$scan_path/dns.json" | jq -r '.a?[]?' | anew "$scan_path/ips.txt" | wc -l
    echo "---------------------------------------------"

    echo "---------------------------------------------"
    echo "${yellow}[+] Port Scanning & HTTP Server Discovery...${reset}"
    
    # nmap -T4 -vv -iL "$scan_path/ips.txt" --top-ports 3000 -n --open -oX "$scan_path/nmap.xml"
    tew -x "$scan_path/nmap.xml" -dnsx "$scan_path/dns.json" --vhost -o "$scan_path/hostport.txt" | httpx -sr -srd "$scan_path/responses" -json -o "$scan_path/http.json"
    echo "---------------------------------------------"

    cat "$scan_path/http.json" | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u > "$scan_path/http.txt"

    echo "---------------------------------------------"
    echo "${yellow}[+] Crawling...${reset}"
    # gospider -S "$scan_path/http.txt" --depth 3 --no-redirect -t 50 -c 3 -o $scan_path/gospider
    gospider -S "$scan_path/http.txt" --json | grep "{" | jq -r '.output?' | tee "$scan_path/crawl.txt"
    echo "---------------------------------------------"

    echo "---------------------------------------------"
    echo "${yellow}[+] Javascript Pulling...${reset}"
    cat "$scan_path/crawl.txt" | grep "\\.js" | httpx -sr -srd js
    echo "---------------------------------------------"

    sed -i 's|http://||g; s|https://||g' $scan_path/subs_resolved.txt

    subdominios_count=$(echo -e "${RED}$date - Total de Subdominios Encontrados:${reset} $(cat $scan_path/subs.txt | wc -l)")
    subdominios_resolved_count=$(echo -e "${RED}$date - Total de Subdominios Resolvidos:${reset} $(cat $scan_path/subs_resolved.txt | wc -l)")


    echo -e "${YELLOW}===============================================${reset}\n"
    echo -e "$subdominios_count\n$subdominios_resolved_count\n"
    echo -e "$subdominios_count\n$subdominios_resolved_count\n=========================================================\n" | perl -pe 's/\e\[?.*?[\@-~]//g' >> $scan_path/notes.txt
    echo -e "${YELLOW}===============================================${reset}\n"

    # Tempo final
    END_TIME=$(date +%s)

    ELAPSED_TIME=$(($END_TIME - $START_TIME))
    echo -e "${BLUE}Script Terminou em - $(date +%d-%m-%Y-%H:%M:%S)${reset}"
    echo -e "${GREEN}Tempo total de execução: $ELAPSED_TIME segundos${reset}\n"
    echo -e "${YELLOW}===============================================${reset}"
    echo -e "${GREEN}==== Verificação de subdomínios concluída! ====${reset}"
    echo -e "${YELLOW}===============================================${reset}"

}

params_pulling(){
    echo "---------------------------------------------"
    echo "${yellow}[+] Params Pulling...${reset}"

    mkdir $scan_path/params

    paramspider -l $scan_path/subs_resolved.txt -s | anew $scan_path/params/all_params.txt
    
    awk '{print "http://" $0; print "https://" $0}' $scan_path/subs_resolved.txt | katana | anew $scan_path/params/all_params.txt
    
    # Declare an array with the list of patterns you want to search for using gf
    declare -a patterns=("debug_logic" "idor" "img-traversal" "interestingEXT" "interestingparams" "interestingsubs" "lfi" "rce" "redirect" "sqli" "ssrf" "ssti" "xss")
    # Iterate over each pattern in the patterns array
    for pattern in "${patterns[@]}"; do
        echo $pattern
        cat $scan_path/params/all_params.txt | gf $pattern | tee -a $scan_path/params/$pattern.txt >> $scan_path/params/all_params.txt
    done
    echo "---------------------------------------------"
}

##################################################---VULN---#############################################################
vuln_scan() {
    echo "---------------------------------------------"
    echo "${yellow}[+] Executando verificação de vulnerabilidades...${reset}"
    # Seu código de verificação de vulnerabilidade vai aqui...
    # paramspider -l $scan_path/subs_resolved.txt -s | nuclei -t "/root/Tools/fuzzing-templates" -rl 05 | notify -silent -bulk

    # cat "$scan_path/subs_resolved.txt" | waybackurls | sort -u >> $scan_path/waybackdata | gf ssrf | tee -a $scan_path/ssrfparams.txt

    # paramspider -l "$scan_path/subs.txt"
    # nuclei -l $scan_path/paramspider_output.txt -t "/root/Tools/fuzzing-templates" -rl 05

    # nuclei -l $scan_path/params/ssrf.txt -t "/root/Tools/fuzzing-templates/ssrf" -rl 05
    
    nuclei -l $scan_path/subs_resolved.txt -as -o $scan_path/nuclei.txt

    cat $scan_path/paramspider.txt | nuclei -t "github/redmc_custom_templates_nuclei-ed-red/fuzzing/xff-403-bypass.yaml" -rl 50 -o nuclei_fuzzing_xff-403-bypass.txt | notify -silent -bulk
    cat $scan_path/paramspider.txt | nuclei -es info -t "/root/Tools/fuzzing-templates" -rl 50 -o nuclei_fuzzing-templates.txt | notify -silent -bulk
    cat $scan_path/params/xss.txt | nuclei -es info -t "/root/Tools/fuzzing-templates/xss" -rl 50 -o nuclei_fuzzing_xss.txt | notify -silent -bulk

    # cat $scan_path/paramspider.txt | nuclei -es info -rl 50 -o nuclei_all_templates_paramspider.txt | anew | notify -silent -bulk
    # cat $scan_path/paramspider.txt | nuclei -es info -rl 50 -o nuclei_all_resolved.txt | anew | notify -silent -bulk

    python3 /root/Tools/xss_vibes/xss_viber.py -f $scan_path/paramspider.txt -o $scan_path/xssvibes_endpoint_vulns.txt
    if [[ -f "$scan_path/xssvibes_endpoint_vulns.txt" ]]; then
        python3 /root/Tools/xss_vibes/xss_viber.py -f $scan_path/xssvibes_endpoint_vulns.txt >> $scan_path/output_xssvibes_completo.txt | notify -silent -bulk
    else
        echo "O arquivo 'xssvibes_endpoint_vulns.txt' não existe."
    fi

    cat "$scan_path/subs_resolved.txt" | nuclei -es info -o "$scan_path/nuclei.txt" | notify -silent -bulk

    echo "${green}Verificação de vulnerabilidades concluída!${reset}"
    echo "------------------------------------------------------------"
}

while true; do
    menu
    case $opt in
        1)
            subdomain_enum
            resolved_verified
            params_pulling
            vuln_scan
            exit 0
            ;;
        2)
            subdomain_enum
            resolved_verified
            exit 0
            ;;
        3)
            resolved_verified
            params_pulling
            vuln_scan
            exit 0
            ;;
        4)
            params_pulling
            vuln_scan
            exit 0
            ;;
        5)
            echo "${blue}Saindo...${reset}"
            exit 0
            ;;
        *)
            echo "${red}Opção inválida. Tente novamente.${reset}"
            ;;
    esac
done


END_TIME=$(date +%s)
ELAPSED_TIME=$(($END_TIME - $START_TIME))
echo "${blue}Script terminou em - $(date +%d-%m-%Y-%H:%M:%S)${reset}"
echo "${green}Tempo total de execução: $ELAPSED_TIME segundos${reset}"
