#### Verificar se a url esta ativa e extrai pedaços do conteúdo: 

```bash
# Verificar se esta ativo:
echo "vulnweb.com" | httpx -silent -probe -status-code -title -ip -cname -content-length
cat lista_sub.txt | httpx -silent -probe -status-code -title -content-length
cat lista_sub.txt | httpx -silent -probe -status-code -title -content-length -ip -cname


# com httpx
echo "vulnweb.com" | httpx -status-code -title -content-length -er 'The requested URL.*'

## Verificar se WAF esta com o certificado quebrado:
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length -er 'The requested URL.*'
cat lista_sub.txt | httpx -silent -probe -status-code -title -content-length -er 'The requested URL.*'
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length -er 'Invalid URL.*' -er 'The requested URL.*' -er 'Reference.*'

## Verificar WAF AKamai
cat sub.txt | httpx -silent -probe -status-code -title -content-length -ip -cname |grep "<NOME_EMPRESA ou DOMINIO>.edgekey.net"

# com curl
curl -s vulnweb.com | grep -o 'The requested URL.*'
```

#### Verificar as entradas de DNS em massa:
```bash
## com saida "<Hostname> <TLS> IN A <IP>"
for i in $(cat lista_sub.txt); do dig $i +noall +answer; done
for i in $(cat lista_sub.txt); do dig CNAME $i +noall +answer; done

## com saida apenas o "<IP>"
for i in $(cat lista_sub.txt); do dig $i +short; done

for i in $(cat lista_sub.txt); do host $i ; done
```

#### Nuclei commands:

```bash
nuclei -u https://testphp.vulnweb.com -t nuclei-templates/github/redmc_custom_templates_nuclei/
cat domains_only_newegg.txt | nuclei -rl 60 -uc -es info -o nuclei_repor_newegg


```

#### Netlas commands:
```bash
netlas download -d domain -c 7 -i domain domain:"*.target.com" | jq -r .data.domain

```

```bash

xargs -a params/params.txt -I@ bash -c 'python3 /root/Tools/XSStrike/xsstrike.py -u @ --fuzzer'
xargs -a params/params.txt -I@ bash -c 'echo "Lendo: @" && python3 /root/Tools/XSStrike/xsstrike.py -u @ --fuzzer'
xargs -a params/params.txt -I@ bash -c 'echo "Processando: @" && python3 /root/Tools/XSStrike/xsstrike.py -u @ --fuzzer'

xargs -a /root/recons/scans/vulnweb/vulnweb-29-08-2023/output_xss_vibes.txt -I@ bash -c 'echo "Processando: @" && python3 /root/Tools/XSStrike/xsstrike.py -u @ --file-log-level 'GOOD','CRITICAL','VULN' --log-file /root/recons/scans/vulnweb/vulnweb-29-08-2023/output_xsstrike.txt'




xargs -P 500 -a dominios.txt -I@ sh -c 'nc -w1 -z -v @ 443 2>/dev/null && echo @' | xargs -I@ -P10 sh -c './gospider -a -s "http://@" -d 2 | grep -Eo "(http|https)://[^/\"].*\.js+" | sed "s#\] \- #\n#g" | ./unew'

echo testphp.vulnweb.com | httpx -silent | hakrawler -subs | grep "=" | qsreplace '"><svg onload=confirm(1)>' | airixss -payload "confirm(1)" | egrep -v 'Not'


```