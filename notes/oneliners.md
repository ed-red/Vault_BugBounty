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