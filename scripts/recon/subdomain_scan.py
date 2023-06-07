import subprocess

def get_subdomains(domain):
    # Defina os comandos para as ferramentas
    commands = [
        ['sublist3r', '-d', domain, '-o', 'subdomains_sublist3r.txt'],
        ['amass', 'enum', '--passive', '-d', domain, '-o', 'subdomains_amass.txt'],
        ['subfinder', '-d', domain, '-o', 'subdomains_subfinder.txt'],
    ]

    # Execute cada comando em um subprocesso
    for command in commands:
        subprocess.run(command)

    # Leia os resultados dos arquivos
    results = set()
    for filename in ['subdomains_sublist3r.txt', 'subdomains_amass.txt', 'subdomains_subfinder.txt']:
        try:
            with open(filename, 'r') as f:
                results.update(f.read().splitlines())
        except Exception as e:
            print(f'Erro ao ler o arquivo {filename}: {e}')

    return results

def main():
    domain = input('Insira o domínio: ')
    subdomains = get_subdomains(domain)
    if subdomains:
        print('Subdomínios encontrados:')
        for subdomain in subdomains:
            print(subdomain)

if __name__ == "__main__":
    main()
