#!/bin/bash

#-- variaveis
export EDITOR='vim'
export DOTFILES=$PWD
# DOTFILES=$(git rev-parse --show-toplevel)

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

## DNS Enumeration - Find Subdomains
echo "${yellow}[+] DNS Enumeration - Find Subdomains...${reset}"
cat "$roots_exist" | haktrails subdomains | anew subs.txt
cat "$roots_exist" | subfinder | anew subs.txt
cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew subs.txt

qnt_dominios_scan_path=$(wc -c subs.txt)
echo "---------------------------------------------"
echo "${green}$qnt_dominios_scan_path domínios adicionados com sucesso!${reset}"
echo "---------------------------------------------"

## DNS Resolution - Resolve Discovered Subdomains
echo "${yellow}[+] DNS Resolution - Resolve Discovered Subdomains...${reset}"
puredns resolve "$scan_path/subs.txt" -r "$RESOLVERS" -w "$scan_path/resolved.txt" | wc -l
dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" | jq -r '.a?[]?' | anew "$scan_path/ips.txt" | wc -l

## Port Scanning & HTTP Server Discovery
echo "${yellow}[+] Port Scanning & HTTP Server Discovery...${reset}"
pwd
nmap -T4 -vv -iL "$scan_path/ips.txt" --top-ports 3000 -n --open -oX "$scan_path/nmap.xml"
tew -x "$scan_path/nmap.xml" -dnsx "$scan_path/dns.json" --vhost -o "$scan_path/hostport.txt" | httpx -sr -srd "$scan_path/responses" -json -o "$scan_path/http.json"

cat "$scan_path/http.json" | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u > "$scan_path/http.txt"

## Crawling
echo "${yellow}[+] Crawling...${reset}"
gospider -S "$scan_path/http.txt" --json | grep "{" | jq -r '.output?' | tee "$scan_path/crawl.txt"

## Javascript Pulling
echo "${yellow}[+] Javascript Pulling...${reset}"
cat "$scan_path/crawl.txt" | grep "\\.js" | httpx -sr -srd js

# cat "$scan_path/subs.txt" | nuclei -rl 60 -uc -es info -o "$scan_path/nuclei.txt"
