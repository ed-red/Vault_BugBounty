#!/bin/bash

h1name=$H1NAME
apitoken=$HACKERONE_API_KEY

# You can also use wget
next="https://api.hackerone.com/v1/hackers/programs?page%5Bsize%5D=100"

while [ "$next" ]; do
  data=$(curl -s "$next" -u "$h1name:$apitoken")
  next=$(echo $data | jq .links.next -r)
  for l in $(echo $data | jq '.data[] | select( .attributes.state != null and .attributes.submission_state != "disabled" and .attributes.offers_bounties == true) | ( .id + "," + .attributes.handle)' -r); do
    
    p=$(echo $l | cut -d',' -f 2)
# Save the company name to a text file
    echo $p >> /root/recons/companies.txt
    
    # Create a directory for the company under /root/recons/scope
    mkdir -p "/root/recons/scope/$p"
    
    # Get the scope data and save it to a text file
    data_scope=$(curl -g -s 'https://api.hackerone.com/v1/hackers/programs/'$p -u $h1name:$apitoken)
    echo $data_scope | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission == true ) | .asset_identifier' -r | sed -e 's/^http:\/\///' -e 's/^https:\/\///' -e 's/^\*\.//' > "/root/recons/scope/$p/scope_subdominio.txt"
    # echo $data_scope | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r | sed -e 's/^http:\/\///' -e 's/^https:\/\///' -e 's/^\*\.//' >> "/root/recons/scope/$p/scope.txt"
    echo $data_scope | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_bounty and .eligible_for_submission == true ) | .asset_identifier' -r | sed -e 's/^http:\/\///' -e 's/^https:\/\///' -e 's/^\*\.//' > "/root/recons/scope/$p/scope_dominio.txt"
    # echo $data_scope | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r | sed -e 's/^http:\/\///' -e 's/^https:\/\///' -e 's/^\*\.//' >> "/root/recons/scope/$p/scope.txt"
    echo $p

    echo $(cat /root/recons/scope/$p/scope_subdominio.txt)
    cat /root/recons/scope/$p/scope_subdominio.txt >> /root/recons/scope_subdominio.txt
   
    echo $(cat /root/recons/scope/$p/scope_dominio.txt)
    cat /root/recons/scope/$p/scope_dominio.txt >> /root/recons/scope_dominio.txt
  done

done
