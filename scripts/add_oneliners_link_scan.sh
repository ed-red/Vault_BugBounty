## DNS Enumeration - Find Subdomains
cat "$roots_exist" | haktrails subdomains | anew subs.txt | wc -l
cat "$roots_exist" | subfinder | anew subs.txt | wc -l
cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew subs.txt | wc -l
## DNS Resolution - Resolve Discovered Subdomains
puredns resolve "$scan_path/subs.txt" -r "$ppath/lists/res