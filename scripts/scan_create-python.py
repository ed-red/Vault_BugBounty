import os
import subprocess
import datetime

# Cores
colors = {
    "black": "\033[30m",
    "red": "\033[31m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "blue": "\033[34m",
    "magenta": "\033[35m",
    "cyan": "\033[36m",
    "white": "\033[37m",
    "reset": "\033[0m"
}

# Variáveis
EMPRESA = ""
GIT_ROOT = subprocess.getoutput("git rev-parse --show-toplevel")
SUBDOM_LIST = GIT_ROOT + "/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS = GIT_ROOT + "/resolvers/resolvers.txt"
DOTFILES = os.getcwd()

# Funções
def listar_empresas(start_index, empresas):
    for i in range(start_index, start_index + 25):
        if i < len(empresas):
            print(f"{colors['green']}{i + 1}.{colors['reset']} {empresas[i]}")

def escanear_empresa(EMPRESA):
    # Lógica para escanear a empresa
    pass

# Verifica se o arquivo /root/recons/companies.txt existe
if not os.path.isfile("/root/recons/companies.txt"):
    print(f"{colors['red']}O arquivo /root/recons/companies.txt não existe. Por favor, crie o arquivo com os nomes das empresas.{colors['reset']}")
    exit(1)

# Lê as empresas do arquivo
with open("/root/recons/companies.txt", "r") as file:
    empresas = [line.strip() for line in file.readlines()]

# Lista as empresas e pede ao usuário para selecionar uma
start_index = 0
scan_todas = False

while True:
    print(f"{colors['blue']}Empresas disponíveis:{colors['reset']}")
    listar_empresas(start_index, empresas)
    entrada_empresa = input(f"{colors['yellow']}Digite 'm' para mostrar mais, 'q' para sair, 'a' para escanear todas as empresas, ou selecione o número da empresa ou escreva o nome da empresa que deseja escanear:{colors['reset']}\n")

    if entrada_empresa == 'm':
        start_index += 25
        continue
    elif entrada_empresa == 'q':
        print(f"{colors['red']}Saindo do script.{colors['reset']}")
        exit(0)
    elif entrada_empresa == 'a':
        print(f"{colors['green']}Você selecionou escanear todas as empresas.{colors['reset']}")
        scan_todas = True
        break
    elif entrada_empresa.isdigit() and int(entrada_empresa) <= len(empresas):
        EMPRESA = empresas[int(entrada_empresa) - 1]
        print(f"{colors['green']}Você selecionou a empresa:{colors['reset']} {EMPRESA}")
        break
    elif entrada_empresa in empresas:
        EMPRESA = entrada_empresa
        print(f"{colors['green']}Você selecionou a empresa:{colors['reset']} {EMPRESA}")
        break
    else:
        print(f"{colors['red']}Entrada inválida. Tente novamente.{colors['reset']}")

