## DNS Enumeration - Find Subdomains
cat "$roots_exist" | haktrails subdomains | anew subs.txt
cat "$roots_exist" | subfinder | anew subs.txt
cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew subs.txt
## DNS Resolution - Resolve Discovered Subdomains
puredns resolve "$scan_path/subs.txt" -r "$RESOLVERS" -w "$scan_path/resolved.txt" | wc -l
dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" | jq -r '.a?[]?' | anew "$scan_path/ips.txt" | wc -l
## Port Scanning & HTTP Server Discovery
nmap -T4 -vv -iL "$scan_path/ips.txt" --top-ports 3000 -n --open -oX "$scan_path/nmap.xml"
tew -x "$scan_path/nmap.xml" -dnsx "$scan_path/dns.json" --vhost -o "$scan_path/hostport.txt" | httpx -sr -srd "$scan_path/responses" -json -o "$scan_path/http.json"
cat "$scan_path/http.json" | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u > "$scan_path/http.txt"
## Crawling
gospider -S "$scan_path/http.txt" --json | grep "{" | jq -r '.output?' | tee "$scan_path/crawl.txt"
## Javascript Pulling
cat "$scan_path/crawl.txt" | grep "\\.js" | httpx -sr -srd js