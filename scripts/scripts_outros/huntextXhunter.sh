#!/bin/bash

# Prompt the user for the target domain
read -p "Digite o domínio-alvo: " target
# Create a directory with the target name
echo "creating directory..." | lolcat
mkdir -p "$target"
echo "directory created" | lolcat
# Enumerating subdomains with subfinder, amass, assetfinder, sublist3r, knock e DNSDumpster
echo "running first enumeration"
subfinder -d "$target" -silent | anew "$target/subdomains.txt" | lolcat 
amass enum -d "$target" -silent | anew "$target/subdomains.txt" | lolcat
assetfinder "$target" | anew "$target/subdomains.txt" | lolcat
sublist3r -d "$target" | anew "$target/subdomains.txt" | lolcat
echo "first enumeration finished"
# Re-enumerate using previous results and save to "subdomains_recursive.txt"
echo "second enumeration running"
cat "$target/subdomains.txt" | subfinder -silent | anew "$target/subdomains_recursive.txt" | lolcat
cat "$target/subdomains.txt" | amass enum -silent | anew "$target/subdomains_recursive.txt" | lolcat
cat "$target/subdomains.txt" | assetfinder | anew "$target/subdomains_recursive.txt" | lolcat
cat "$target/subdomains.txt" | sublist3r -silent | anew "$target/subdomains_recursive.txt" | lolcat
cat "$target/subdomains.txt" | httprobe | anew "$target/subdomains_recursive_httprobe.txt" | lolcat
cat "$target/subdomains.txt" | dnsx -a -resp | anew "$target/subdomains_recursive_dnsx.txt" | lolcat
cat "$target/subdomains_recursive.txt" "$target/subdomains_recursive_httprobe.txt" "$target/subdomains_recursive_dnsx.txt" | anew "$target/final_enumeration.txt" | lolcat
echo "second enumeration finished"
# premutation in enumeration
echo "premutation running"
cat "$target/final_enumeration.txt" | alterx -en | anew "$target/premutation.txt" | lolcat
echo "premutation finished"
# validating domains and passing to http
echo "domain validation running"
cat "$target/premutation.txt" | dnsx | httpx -silent | anew "$target/http_domains.txt" | lolcat
echo "domain validation finished"
# collecting urls
echo "running url collection"
cat "$target/http_domains.txt" | waybackurls | anew "$target/wayback_urls.txt" | lolcat
cat "$target/http_domains.txt" | gau | anew  "$target/gau_urls.txt" | lolcat
cat "$target/http_domains.txt" | katana | anew "$target/katana.urls.txt" | lolcat
cat "$target/wayback_urls.txt" "$target/gau_urls.txt" "$target/katana.urls.txt" | anew "$target/final_crawler.txt" | lolcat
echo "finished url collection"
# Filter only URLs parameters and save to file "parameters.txt"
echo "leaving only parameters"
cat anew "$target/final_crawler.txt" | uro | anew anew "$target/parametros.txt" | lolcat
echo "leaving only parameters finished"
# passing urls with parameters to nuclei
echo "starting the nuclei"
nuclei -l "$target/parametros.txt" -t /root/nuclei-templates/ -severity low,medium,high -tags ssl | anew "$target/nuclei_results.txt"
echo "finished the nuclei"