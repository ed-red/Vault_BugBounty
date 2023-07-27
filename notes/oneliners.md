#### Verificar se a url esta ativa e extrai pedaços do conteúdo: 

```bash
# Verificar se esta ativo:
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length
cat lista_sub.txt | httpx -silent -probe -status-code -title -content-length
cat lista_sub.txt | httpx -silent -probe -status-code -title -content-length -ip -cname


# com httpx
echo "vulnweb.com" | httpx -status-code -title -content-length -er 'The requested URL.*'

## Verificar se WAF esta com o certificado quebrado:
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length -er 'The requested URL.*'
cat lista_sub.txt | httpx -silent -probe -status-code -title -content-length -er 'The requested URL.*'
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length -er 'Invalid URL.*' -er 'The requested URL.*' -er 'Reference.*'

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


```