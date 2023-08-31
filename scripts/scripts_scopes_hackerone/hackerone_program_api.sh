#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # Sem cor

h1name=$H1NAME
apitoken=$HACKERONE_API_KEY
next="https://api.hackerone.com/v1/hackers/programs?page%5Bsize%5D=100"
deleted_companies=""
date="$(date +%d-%m-%Y-%H:%M:%S)"

echo -e "\n${YELLOW}========================================${NC}"
echo -e "${GREEN}Iniciando o reconhecimento...${NC}"
echo -e "${YELLOW}========================================${NC}\n"

# Remove previous files if they exist
if [ -s "/root/recons/companies.txt" ]; then
  echo -e "${BLUE}Tamanho do arquivo de empresas existente:${NC} $(cat /root/recons/companies.txt | wc -l)"
  rm -rf /root/recons/companies.txt
fi

if [ -s "/root/recons/scope.txt" ]; then
  rm -rf /root/recons/scope.txt
fi

if [ -d "/root/recons/scope/0_h1_completo" ]; then
  rm -rf "/root/recons/scope/0_h1_completo"
fi
mkdir -p "/root/recons/scope/0_h1_completo"

# Loop through HackerOne API
while [ "$next" ]; do
  data=$(curl -s "$next" -u "$h1name:$apitoken")
  next=$(echo $data | jq .links.next -r)

  # Loop through data
  for l in $(echo $data | jq '.data[] | select(.attributes.state != null and .attributes.submission_state != "disabled" and .attributes.offers_bounties == true) | ( .id + "," + .attributes.handle)' -r); do
    p=$(echo $l | cut -d',' -f 2)

    echo -e "${YELLOW}----------------------------------------${NC}"
    echo -e "${GREEN}Processando empresa:${NC} $p"
    echo -e "${YELLOW}----------------------------------------${NC}"

    # Create a directory for the company under /root/recons/scope
    mkdir -p "/root/recons/scope/$p"

    # Save the company name to a text file
    echo "$p" >> /root/recons/companies.txt

    # Get the scope data and save it to a text file
    data_scope=$(curl -g -s "https://api.hackerone.com/v1/hackers/programs/$p" -u "$h1name:$apitoken")
    url_scope=$(echo $data_scope | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "URL" and .eligible_for_bounty and .eligible_for_submission == true ) | .asset_identifier' -r | sed -e 's#^http://##' -e 's#^https://##' -e 's#^*\.##')
    wildcard_scope=$(echo $data_scope | jq '.relationships.structured_scopes.data[].attributes | select(.asset_type == "WILDCARD" and .eligible_for_bounty and .eligible_for_submission == true ) | .asset_identifier' -r | sed -E 's#^(\*\.?|http://|https://)?([^/]*).*#\2#' | sed -e 's/^http:\/\///' -e 's/^https:\/\///' -e 's/^\*\.//')

    # Check if both URL and WILDCARD scopes are empty
    if [[ -z "$url_scope" && -z "$wildcard_scope" ]]; then
      echo -e "${RED}Arquivos de domínio e subdomínio estão vazios. Excluindo a pasta $p...${NC}"
      echo -e "${YELLOW}----------------------------------------${NC}\n"
      rm -rf "/root/recons/scope/$p"
      sed -i "/^$p$/d" /root/recons/companies.txt
      deleted_companies+="$p\n"
      continue
    fi

    echo -e "$url_scope\n$wildcard_scope" | sed '/^$/d' | sed 's#/.*##' > "/root/recons/scope/$p/scope.txt"

    # Print the processed scope data
    echo -e "${BLUE}Escopo URL:${NC}\n$url_scope"
    echo -e "${BLUE}Escopo WILDCARD:${NC}\n$wildcard_scope"
    echo -e "${YELLOW}----------------------------------------${NC}\n"

    echo -e "$url_scope\n$wildcard_scope" | sed '/^$/d' | sed 's#/.*##' >> /root/recons/scope/0_h1_completo/scope_completo.txt | anew
    echo -e "$url_scope" | sed '/^$/d' | sed 's#/.*##' >> /root/recons/scope/0_h1_completo/scope.txt | anew
    echo -e "$wildcard_scope" | sed '/^$/d' >> /root/recons/scope/0_h1_completo/wildcards.txt | anew
  done
done

total_empresa_count_h1=$(echo -e "${RED}$date - Tamanho total de empresas coletadas na H1:${NC} $(cat /root/recons/companies.txt | wc -l)")
total_dominio_count_h1=$(echo -e "${RED}$date - Tamanho total de Dominios/URL coletados na H1:${NC} $(cat /root/recons/scope/0_h1_completo/scope_completo.txt | wc -l)")
total_URL_count_h1=$(echo -e "${RED}$date - Tamanho total de URL coletados na H1:${NC} $(cat /root/recons/scope/0_h1_completo/scope.txt | wc -l)")
total_WILDCARD_count_h1=$(echo -e "${RED}$date - Tamanho total de WILDCARD coletados na H1:${NC} $(cat /root/recons/scope/0_h1_completo/wildcards.txt | wc -l)")

echo -e "$total_empresa_count_h1\n$total_dominio_count_h1\n$total_URL_count_h1\n$total_WILDCARD_count_h1\n"
echo -e "\n$total_empresa_count_h1\n$total_dominio_count_h1\n$total_URL_count_h1\n$total_WILDCARD_count_h1\n" | sed "s/\x1B\[[0-9;]*[JKmsu]//g" >> /root/Vault_BugBounty/scripts/scripts_scopes_hackerone/qnt_empresas_dominios_h1.txt
echo -e "${YELLOW}========================================${NC}\n"

echo -e "${GREEN}Reconhecimento concluído!${NC}"
echo -e "${YELLOW}========================================${NC}"
if [ -n "$deleted_companies" ]; then
  echo -e "${RED}Empresas excluídas:${NC}\n$deleted_companies" # Mostra cada empresa em uma nova linha
  echo -e "${RED}$date - Empresas excluídas:${NC}\n$deleted_companies\n=================================================================\n" | sed "s/\x1B\[[0-9;]*[JKmsu]//g" >> /root/Vault_BugBounty/scripts/scripts_scopes_hackerone/qnt_empresas_dominios_h1.txt
else
  echo -e "${RED}Nenhuma empresa foi excluída.${NC}"
fi

