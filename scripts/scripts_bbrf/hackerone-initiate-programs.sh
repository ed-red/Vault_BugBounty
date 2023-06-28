#!/bin/bash

# Initiate new BBRF programs from your public and private HackerOne programs

h1name=$H1NAME
apitoken=$HACKERONE_API_KEY
next='https://api.hackerone.com/v1/hackers/programs?page%5Bsize%5D=100'

while [ "$next" ]; do

  data=$(curl -s "$next" -u "$h1name:$apitoken")
  next=$(echo $data | jq .links.next -r)
  for l in $(echo $data | jq '.data[] | select( .attributes.state != null and .attributes.submission_state != "disabled") | ( .id + "," + .attributes.handle)' -r); do

    p=$(echo $l | cut -d',' -f 2)

    exists=$(bbrf programs where h1id is $p --show-empty-scope --show-disabled)
    if [ -z "$exists" ]; then
      echo "Adding new program $p to BBRF..."
      bbrf new $p -t platform:hackerone -t h1id:$p
      
      (
      curl -g -s 'https://api.hackerone.com/v1/hackers/programs/'$p -u $h1name:$apitoken | tee \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r | bbrf inscope add - -p $p) \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r | bbrf outscope add - -p $p ) \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r | bbrf inscope add - -p $p) \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r | bbrf outscope add - -p $p ) \
       > /dev/null
      ) &
    fi
  done

done