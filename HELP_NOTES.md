## Referências:
- pry0cc/lazy - https://github.com/pry0cc/lazy
- building-one-shot-recon - https://blog.projectdiscovery.io/building-one-shot-recon/
- One-Liner-Collections - https://github.com/thecybertix/One-Liner-Collections
- recommended-bash-scripting-extensions-for-vs-code - https://medium.com/devops-and-sre-learning/recommended-bash-scripting-extensions-for-vs-code-67c62a132978

## Subdomain Referencia
- https://github.com/Dheerajmadhukar/subzzZ

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
59 10 * * * nuclei -update-templates ; echo NUCLEI ATUALIZADO | /usr/bin/notify >/dev/null 2>&1 >/dev/null 2>81
59 10 * * * ~/Vault_BugBounty/scripts/scripts_atualizar_templates_nuclei/setup_atualizar_templates_nuclei.sh ; echo NUCLEI ATUALIZADO | /usr/bin/notify >/dev/null 2>&1 >/dev/null 2>81
