#!/bin/bash

# Update the scope of your HackerOne programs

h1name=$H1NAME
apitoken=$HACKERONE_API_KEY
next='https://api.hackerone.com/v1/hackers/programs?page%5Bsize%5D=100'

for p in $(bbrf programs where platform is hackerone --show-empty-scope); do
  h1id=$(bbrf show $p | jq -r .tags.h1id)
  echo "Updating $p scope..."
  (
  curl -g -s 'https://api.hackerone.com/v1/hackers/programs/'$h1id -u $h1name:$apitoken | tee \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission) | .asset_identifier' -r | bbrf inscope add - -p $p) \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_submission == false) | .asset_identifier' -r | bbrf outscope add - -p $p ) \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_bounty and .eligible_for_submission and .archived_at == null) | .asset_identifier' -r | bbrf inscope add - -p $p) \
       >( jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_submission == false and .archived_at == null) | .asset_identifier' -r | bbrf outscope add - -p $p ) \       
       > /dev/null
  ) &
done