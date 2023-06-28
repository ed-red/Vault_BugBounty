#!/bin/bash

# for p in $(bbrf programs); do
#   bbrf domains --view unresolved -p $p | \
#   dnsx -silent -a -resp | tr -d '[]' | tee \
#       >(awk '{print $1":"$2}' | bbrf domain update - -p $p -s dnsx) \
#       >(awk '{print $1":"$2}' | bbrf domain add - -p $p -s dnsx) \
#       >(awk '{print $2":"$1}' | bbrf ip add - -p $p -s dnsx) \
#       >(awk '{print $2":"$1}' | bbrf ip update - -p $p -s dnsx)
# done

for p in $nome_programa; do
  bbrf domains --view unresolved -p $p | \
  dnsx -silent -a -resp | tr -d '[]' | tee \
      >(awk '{print $1":"$2}' | bbrf domain update - -p $p -s dnsx) \
      >(awk '{print $1":"$2}' | bbrf domain add - -p $p -s dnsx) \
      >(awk '{print $2":"$1}' | bbrf ip add - -p $p -s dnsx) \
      >(awk '{print $2":"$1}' | bbrf ip update - -p $p -s dnsx)
  echo "${green}Resolvendo Domínios com DNSx com sucesso!${reset}"
  echo "---------------------------------------------"
done