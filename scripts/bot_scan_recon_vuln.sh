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

SUBDOM_LIST="$GIT_ROOT/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS="$GIT_ROOT/wordlists/resolvers/resolvers.txt"

echo $GIT_ROOT
echo $SUBDOM_LIST
echo $RESOLVERS
echo $scan_path
echo $roots_exist
# cd $scan_path

# Menu principal
menu() {
    echo "${yellow}Escolha uma opção:${reset}"
    echo "1. Enumeração de subdomínios"
    echo "2. Verificação de vulnerabilidades"
    echo "3. Enumeração de subdomínios e Verificação de vulnerabilidades"
    echo "4. Sair"
    read -p "Selecione uma opção [1-4]: " opt
}

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
    PROCESSES=100

    echo "${yellow}Iniciando a enumeração de subdomínios...${reset}"

    # Função para verificar qual processo foi concluído
    check_complete() {
        task_name=$1
        count_subs=$2
        echo "${green}A tarefa '$task_name' foi concluída às $(date '+%H:%M:%S') e pegou $count_subs novos subs.${reset}"
    }

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
    cat "$roots_exist" | xargs -I {} sh -c "amass enum -silent -d {} -dir $scan_path/amass-outputs && amass db -names -d {} | anew subs.txt" && check_complete "Amass" "$(wc -l subs.txt)" &
    echo "${green}Amass em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe haktrails subdomains | anew subs.txt && check_complete "Haktrails" "$(wc -l subs.txt)") &
    echo "${green}Haktrails em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe subfinder -silent | anew subs.txt && check_complete "Subfinder" "$(wc -l subs.txt)") &
    echo "${green}Subfinder em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" -silent | anew subs.txt && check_complete "Shuffledns" "$(wc -l subs.txt)") &
    echo "${green}Shuffledns em andamento...${reset}"

    (cat "$roots_exist" | parallel -j $PROCESSES --pipe "awk '{print \"http://\" \$0; print \"https://\" \$0}'" | katana -f fqdn -silent | anew subs.txt && check_complete "Katana Recon subs" "$(wc -l subs.txt)") &
    echo "${green}Katana Recon subs em andamento...${reset}"
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
    echo "Número de subdominios em subs.txt agora: $new_count${reset}"
    qnt_dominios_scan_path=$(wc -c subs.txt)
    echo "---------------------------------------------"
    echo "${green}$(wc -c subs.txt) domínios adicionados com sucesso!${reset}"
    echo "---------------------------------------------"

    # Tempo final
    echo "---------------------------------------------"
    END_TIME=$(date +%s)

    ELAPSED_TIME=$(($END_TIME - $START_TIME))
    echo "${blue}Script Terminou em - $(date +%d-%m-%Y-%H:%M:%S)${reset}"
    echo "${green}Tempo total de execução: $ELAPSED_TIME segundos${reset}"
    echo "---------------------------------------------"

    echo "---------------------------------------------"
    echo "${yellow}[+] DNS Resolution - Resolve Discovered Subdomains...${reset}"
    puredns resolve "$scan_path/subs.txt" -r "$RESOLVERS" -w "$scan_path/resolved.txt" | wc -l
    cat "$scan_path/subs.txt" | httpx -silent -o "$scan_path/resolved.txt"
    dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" | jq -r '.a?[]?' | anew "$scan_path/ips.txt" | wc -l
    echo "---------------------------------------------"

    echo "---------------------------------------------"
    echo "${yellow}[+] Port Scanning & HTTP Server Discovery...${reset}"
    pwd
    nmap -T4 -vv -iL "$scan_path/ips.txt" --top-ports 3000 -n --open -oX "$scan_path/nmap.xml"
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

    echo "${green}Enumeração de subdomínios concluída!${reset}"
}

vuln_scan() {
    # Seu código de verificação de vulnerabilidade vai aqui...
    # paramspider -l $scan_path/resolved.txt -s | nuclei -t "/root/Tools/fuzzing-templates" -rl 05 | notify -silent -bulk

    echo "---------------------------------------------"
    echo "${yellow}[+] Params Pulling...${reset}"
    paramspider -l $scan_path/subs.txt -s | anew $scan_path/paramspider.txt
    awk '{print "http://" $0; print "https://" $0}' $scan_path/subs.txt | katana | anew $scan_path/paramspider.txt
    mkdir $scan_path/params
    cat "$scan_path/paramspider.txt" | gf debug_logic | tee -a $scan_path/params/debug_logic.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf idor | tee -a $scan_path/params/idor.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf img-traversal | tee -a $scan_path/params/img-traversal.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf interestingEXT | tee -a $scan_path/params/interestingEXT.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf interestingparams | tee -a $scan_path/params/interestingparams.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf interestingsubs | tee -a $scan_path/params/interestingsubs.txt >> $scan_path/params/params.txt
    # cat "$scan_path/paramspider.txt" | gf jsvar | tee -a $scan_path/params/jsvar.txt
    cat "$scan_path/paramspider.txt" | gf lfi | tee -a $scan_path/params/lfi.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf rce | tee -a $scan_path/params/rce.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf redirect | tee -a $scan_path/params/redirect.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf sqli | tee -a $scan_path/params/sqli.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf ssrf | tee -a $scan_path/params/ssfr.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf ssti | tee -a $scan_path/params/ssti.txt >> $scan_path/params/params.txt
    cat "$scan_path/paramspider.txt" | gf xss | tee -a $scan_path/params/xss.txt >> $scan_path/params/params.txt


    echo "---------------------------------------------"

    # cat "$scan_path/resolved.txt" | waybackurls | sort -u >> $scan_path/waybackdata | gf ssrf | tee -a $scan_path/ssfrparams.txt

    # paramspider -l "$scan_path/subs.txt"
    # nuclei -l $scan_path/paramspider_output.txt -t "/root/Tools/fuzzing-templates" -rl 05

    # nuclei -l $scan_path/params/ssfr.txt -t "/root/Tools/fuzzing-templates/ssrf" -rl 05
    cat $scan_path/paramspider.txt | nuclei -es info -t "/root/Tools/fuzzing-templates" -rl 50 -o nuclei_fuzzing-templates.txt | anew | notify -silent -bulk
    cat $scan_path/paramspider.txt | nuclei -es info -rl 50 -o nuclei_all_templates_paramspider.txt | anew | notify -silent -bulk
    cat $scan_path/paramspider.txt | nuclei -es info -rl 50 -o nuclei_all_resolved.txt | anew | notify -silent -bulk

    python3 /root/Tools/xss_vibes/xss_viber.py -f $scan_path/paramspider.txt -o $scan_path/xssvibes_endpoint_vulns.txt
    if [[ -f "$scan_path/xssvibes_endpoint_vulns.txt" ]]; then
        python3 /root/Tools/xss_vibes/xss_viber.py -f $scan_path/xssvibes_endpoint_vulns.txt >> $scan_path/output_xssvibes_completo.txt | notify -silent -bulk
    else
        echo "O arquivo 'xssvibes_endpoint_vulns.txt' não existe."
    fi


    # cat "$scan_path/resolved.txt" | nuclei -es info -o "$scan_path/nuclei.txt" | notify -silent -bulk

    echo "${green}Verificação de vulnerabilidades concluída!${reset}"
}

while true; do
    menu
    case $opt in
        1)
            subdomain_enum
            ;;
        2)
            vuln_scan
            ;;
        3)
            echo "${yellow}[+] Executando enumeração de subdomínios...${reset}"
            subdomain_enum
            echo "${yellow}[+] Executando verificação de vulnerabilidades...${reset}"
            vuln_scan
            ;;
        4)
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
