#!/bin/bash

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

SUBDOM_LIST="$GIT_ROOT/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS="$GIT_ROOT/resolvers/resolvers.txt"

echo $GIT_ROOT
echo $RESOLVERS
echo $scan_path
echo $roots_exist
# cd $scan_path
echo $(pwd)

echo "---------------------------------------------"
echo "${yellow}[+] DNS Enumeration - Find Subdomains...${reset}"
cat "$roots_exist" | haktrails subdomains | anew subs.txt
cat "$roots_exist" | subfinder | anew subs.txt
cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew subs.txt
awk '{print "http://" $0; print "https://" $0}' $roots_exist | katana -f fqdn | anew subs.txt
echo "---------------------------------------------"

qnt_dominios_scan_path=$(wc -c subs.txt)
echo "---------------------------------------------"
echo "${green}$(wc -c subs.txt) domínios adicionados com sucesso!${reset}"
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
cat $scan_path/paramspider.txt | nuclei -es info -t "/root/Tools/fuzzing-templates" -rl 50 -o nuclei_output.txt | anew | notify -silent -bulk >> /root/recons/nuclei_output_all.txt

python3 /root/Tools/xss_vibes/main.py -f $scan_path/paramspider.txt -o $scan_path/xssvibes_endpoint_vulns.txt | notify -silent -bulk >> /root/recons/nuclei_output_all.txt
python3 /root/Tools/xss_vibes/main.py -f $scan_path/xssvibes_endpoint_vulns.txt>> $scan_path/output_xssvibes_completo.txt | notify -silent -bulk >> /root/recons/nuclei_output_all.txt

# cat "$scan_path/resolved.txt" | nuclei -es info -o "$scan_path/nuclei.txt" | notify -silent -bulk
