### Referências:
- pry0cc/lazy - https://github.com/pry0cc/lazy
- building-one-shot-recon - https://blog.projectdiscovery.io/building-one-shot-recon/
- One-Liner-Collections - https://github.com/thecybertix/One-Liner-Collections

### TMUX comandos:
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