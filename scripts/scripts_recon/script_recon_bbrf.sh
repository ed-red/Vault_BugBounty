#!/bin/bash

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

#--- Variaveis
GIT_ROOT=$(git rev-parse --show-toplevel)
# SUBDOM_LIST=$(curl -s https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt)
# RESOLVERS=$(curl -s <URL RESOLVERS PUB>)
SUBDOM_LIST="$GIT_ROOT/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS="$GIT_ROOT/resolvers/resolvers.txt"

while true; do
    echo "${blue}Programas da H1:${reset}"
    programas=($(bbrf programs))

    for i in "${!programas[@]}"; do
        echo "${green}$((i+1)).${reset} ${programas[i]}"
    done
    echo "---------------------------------------------"

    while true; do
        echo "${yellow}Selecione o número do programa ou escreva o nome do programa que quer escanear:${reset}"
        read -r entrada_programa
        echo "---------------------------------------------"

        if [[ $entrada_programa =~ ^[0-9]+$ ]] && [ "$entrada_programa" -le "${#programas[@]}" ]; then
            nome_programa=${programas[$((entrada_programa-1))]}
            echo "${green}Você selecionou o programa:${reset} $nome_programa"
            bbrf use "$nome_programa"
            echo "---------------------------------------------"
            break
        elif [[ " ${programas[@]} " =~ " ${entrada_programa} " ]]; then
            nome_programa=$entrada_programa
            echo "${green}Você selecionou o programa:${reset} $nome_programa"
            bbrf use "$nome_programa"
            echo "---------------------------------------------"
            break
        else
            echo "${red}Entrada inválida. Tente novamente.${reset}"
        fi
    done

    while true; do
        echo "${yellow}Selecione uma opção:${reset}"
        echo "${cyan}1. Ver o scope completo de $nome_programa, listando tudo, domains e wildcard"
        echo "2. Ver apenas os wildcards de $nome_programa"
        echo "3. Adicionar os domínios de $nome_programa ao BBRF!"
        echo "4. Voltar à seleção de programa"
        echo "5. Sair${reset}"
        echo "---------------------------------------------"

        read -r opcao

        case $opcao in
            1)
                echo "---------------------------------------------"
                echo "${green}Ok, abaixo o escopo completo com Domains e Wildcard do $nome_programa:${reset}"
                bbrf scope in -p "$nome_programa"
                echo "---------------------------------------------"
                ;;
            2)
                echo "---------------------------------------------"
                echo "${green}Ok, abaixo estão apenas os Wildcards do $nome_programa:${reset}"
                bbrf scope in -p "$nome_programa" --wildcard
                echo "---------------------------------------------"
                ;;
            3)
                echo "---------------------------------------------"
                echo "${green}Adicionando os domínios de $nome_programa ao BBRF com o Subfinder, haktrails e shuffledns...${reset}"
                recon_path="$HOME/recons"
                scan_path="$recon_path/scans/$nome_programa"
                if [ ! -d "$scan_path" ]; then
                    echo "${yellow}[+] Criando pasta $scan_path...${reset}"
                    mkdir -p "$scan_path"
                fi
                #-- Chamar bbrf_helper.sh para conseguir usar o comando "addInChunks"
                source /root/BugBountyHuntingScripts/bbrf_helper.sh
                echo "---------------------------------------------"
                qnt_dominios_scan_path=$(cat $scan_path/subs.txt | wc -l)
                bbrf scope in -p "$nome_programa" --wildcard --top | subfinder | anew $scan_path/subs.txt && addInChunks $scan_path/subs.txt domains | notify -silent -bulk
                echo "${yellow}[+] $qnt_dominios_scan_path Domínios de $nome_programa adicionados com sucesso usando SubFinder!${reset}"
            
                bbrf scope in -p "$nome_programa" --wildcard --top | haktrails subdomains | anew $scan_path/subs.txt && addInChunks $scan_path/subs.txt domains | notify -silent -bulk
                echo "${yellow}[+] $qnt_dominios_scan_path Domínios de $nome_programa adicionados com sucesso usando HakTrails!${reset}"

                bbrf scope in -p "$nome_programa" --wildcard --top | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew $scan_path/subs.txt && addInChunks $scan_path/subs.txt domains | notify -silent -bulk
                echo "${yellow}[+] $qnt_dominios_scan_path Domínios de $nome_programa adicionados com sucesso usando ShuffleDNS!${reset}"
                echo "---------------------------------------------"
                echo "${green}$qnt_dominios_scan_path Domínios adicionados com sucesso!${reset}"
                echo "---------------------------------------------"
                #-- Chamar resolver usando DNSx
                source /root/Vault_BugBounty/scripts/scripts_bbrf/resolver_bbrf.sh
                ;;
            4)
                echo "${cyan}Voltando à seleção de programa...${reset}"
                echo "---------------------------------------------"
                break
                ;;
            5)
                echo "${red}Saindo...${reset}"
                exit
                ;;
            *)
                echo "${red}Opção inválida.${reset}"
                ;;
        esac
    done
done
