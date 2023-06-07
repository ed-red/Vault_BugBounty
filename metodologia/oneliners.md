#### Verificar se a url esta ativa e extrai pedaços do conteúdo 

```bash
# com httpx
echo "vulnweb.com" | httpx -status-code -title -content-length -er 'The requested URL.*'
## Verificar se WAF esta com o certificado quebrado:
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length -er 'The requested URL.*'
echo "vulnweb.com" | httpx -silent -probe -status-code -title -content-length -er 'Invalid URL.*' -er 'The requested URL.*' -er 'Reference.*'

# com curl
curl -s vulnweb.com | grep -o 'The requested URL.*'
```

