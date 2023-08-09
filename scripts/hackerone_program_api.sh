#!/bin/bash

h1name=$H1NAME
apitoken=$HACKERONE_API_KEY

# You can also use wget
next="https://api.hackerone.com/v1/hackers/programs?page%5Bsize%5D=100"

while [ "$next" ]; do
  data=$(curl -s "$next" -u "$h1name:$apitoken")
  next=$(echo $data | jq .links.next -r)
  for l in $(echo $data | jq '.data[] | select( .attributes.state != null and .attributes.submission_state != "disabled") | ( .id + "," + .attributes.handle)' -r); do
    
    p=$(echo $l | cut -d',' -f 2)
    echo $p
    
    

    data_scope=$(curl -g -s 'https://api.hackerone.com/v1/hackers/programs/'$p -u $h1name:$apitoken)
    echo $data | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r
    echo $data | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r
    echo $data | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r
    echo $data | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r
    
    (
    curl -g -s 'https://api.hackerone.com/v1/hackers/programs/'$p -u $h1name:$apitoken | tee \
      >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r ) \
      >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r ) \
      >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r ) \
      >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r ) \
      > /dev/null
    ) &
  done

done
