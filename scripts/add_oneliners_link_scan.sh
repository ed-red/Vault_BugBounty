## DNS Enumeration - Find Subdomains
cat "$roots_exist" | haktrails subdomains | anew subs.txt
cat "$roots_exist" | subfinder | anew subs.txt
cat "$roots_exist" | shuffledns -w "$SUBDOM_LIST" -r "$RESOLVERS" | anew subs.txt
## DNS Resolution - Resolve Discovered Subdomains
puredns resolve "$scan_path/subs.txt" -r "$ppath/lists/res

