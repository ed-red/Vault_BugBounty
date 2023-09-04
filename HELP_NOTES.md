## Referências em Geral:
- pry0cc/lazy - https://github.com/pry0cc/lazy
- building-one-shot-recon - https://blog.projectdiscovery.io/building-one-shot-recon/
- One-Liner-Collections - https://github.com/thecybertix/One-Liner-Collections
- recommended-bash-scripting-extensions-for-vs-code - https://medium.com/devops-and-sre-learning/recommended-bash-scripting-extensions-for-vs-code-67c62a132978
- Para configurar repositório externo no Nuclei - https://nuclei.projectdiscovery.io/nuclei/get-started/#custom-templates

## Tools:
### Recon subdomains:
- https://github.com/Dheerajmadhukar/subzzZ

### Ferramentas Teste de Vulns:
#### XSS:


## Resolver alguns problemas do Git:
#### Quando começar a dar erro de permissão:
- Referencia:
    https://stackoverflow.com/questions/5335197/gits-famous-error-permission-to-git-denied-to-user/40907049#40907049
```bash
git remote set-url origin git@github.com:ed-red/Vault_BugBounty.git
```

## TMUX comandos:
https://www.hostinger.com.br/tutoriais/como-usar-tmux-lista-de-comandos
https://tmuxcheatsheet.com/

Criar nova sessão:
`tmux new -s [session_name]`

Agora precisamos voltar para nossa sessão “attach”. Para fazer isto, executamos o seguinte comando no terminal:
`tmux attach -t [session_name]`

Já que não temos um nome para a sessão, usaremos o valor 0. O comando será assim:
`tmux attach -t 0`

Podemos ver quantas sessões Tmux estão abertas com o seguinte comando:
`tmux ls`

kill/delete session "session_name":
`tmux kill-session -t [session_name]`

kill/delete all sessions but the current:
`tmux kill-session -a -t [session_name]`

Por padrão, o prefixo é CTRL+B.


## CronTab
### Exemplos de Crontabs:
```bash
59 10 * * * nuclei -update-templates ; echo NUCLEI ATUALIZADO | /usr/bin/notify >/dev/null 2>&1 >/dev/null 2>81
0 8,20 * * * ~/Vault_BugBounty/scripts/scripts_atualizar_templates_nuclei/setup_atualizar_templates_nuclei.sh ; echo NUCLEI ATUALIZADO - $(date) | $HOME/go/bin/notify >/dev/null 2>&1 >/dev/null 2>81

```
### Crontab que estou usando:
```bash
##-- NUCLEI
0 */6 * * * ~/Vault_BugBounty/scripts/scripts_atualizar_templates_nuclei/setup_atualizar_templates_nuclei.sh ; echo NUCLEI ATUALIZADO - $(date) | $HOME/go/bin/notify >/dev/null 2>&1 >/dev/null 2>81

##-- BBRF
0 0 * * * ~/Vault_BugBounty/scripts/scripts_bbrf/hackerone-update-program-scopes.sh ; echo UPDATE PROGRAMAS H1 - BBRF - $(date)\ncat ~/Vault_BugBounty/scripts/scripts_bbrf/qnt_empresas_dominios_h1.txt | $HOME/go/bin/notify -silent -bulk >/dev/null 2>&1 >/dev/null 2>81

##-- UPDATE SCOPES H1
0 0 * * * ~/Vault_BugBounty/scripts/scripts_scopes_hackerone/hackerone_program_api.sh ; echo UPDATE PROGRAMAS H1 - BBRF - $(date)\n$(cat ~/Vault_BugBounty/scripts/scripts_scopes_hackerone/qnt_empresas_dominios_h1.txt) | notify -silent -bulk >/dev/null 2>&1 >/dev/null 2>81


```


## Usar o BBRF
https://medium.com/@ataidejunior/utilizando-bbrf-com-foco-em-reconnaissance-bugbounty-affc99663bc1

### Commands / Oneliners
#### BBRF
```bash
# bbrf scope in -p tiktok --wildcard --top | subfinder | bbrf domain add - --show-new | notify -silent

bbrf scope in -p tiktok --wildcard --top | subfinder >> domains.txt && addInChunks domains.txt domains | notify -silent

bbrf scope in -p github --wildcard --top | subfinder >> domains.txt && addInChunks domains.txt domains | notify -silent -bulk

bbrf scope in --all --wildcard --top

bbrf scope in --all --wildcard --top | subfinder >> domains.txt && addInChunks domains.txt domains | notify -silent

bbrf scope in --all --wildcard --top | subfinder | bbrf domain add - --show-new | notify -silent

bbrf show tiktok | jq -r '.inscope | arrays'

cat urls.txt | bbrf url add - --show-new

##-- Add portas
bbrf ips -p yelp | naabu | bbrf service add - --show-new
##-- Add portas e serviços
bbrf ips -p yelp | naabu -sD | bbrf service add - --show-new

```

## Usar API da HackerOne:
Acessar um programa pela api da HackerOne:
https://api.hackerone.com/v1/hacketmuxrs/programs/yuga_labs


## Automatizar BBRF scan

1. Um menu que traga as opções:
   1. Lista os Programas da H1:
      1. Vai usar o seguinte comando `bbrf programs`, vai listar os nomes dos programa.
      2. depois que listar, vai aparece para selecionar um programa ou escrever o nome: 
      3. Depois vai usar a informação que eu selecionei ou escrevi como variavel para o <nome do programa>:
         1. Vai usar o seguinte comando `bbrf use <nome do programa>`
      4. Quer ver o scope completo do program <nome do programa>, listando tudo, domains e wildcard:
         1. Pergunta se quer listar tudo, Domains e Wildcards:
            1. Vai usar o seguinte comando para listar tudo `bbrf scope in -p <nome do programa>`
         2. Pergunta se quer apenas os Wildcards:
            1. Vai usar o seguinte comando para listar apenas os wildcards `bbrf scope in -p <nome do programa> --wildcard`


