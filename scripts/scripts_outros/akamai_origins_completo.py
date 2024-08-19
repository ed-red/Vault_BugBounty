import json
import subprocess
import requests
import socket
from urllib3.exceptions import InsecureRequestWarning

# Suprimir avisos de HTTPS não verificados
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Defina sua URL do Webhook do Teams aqui
TEAMS_WEBHOOK_URL = 'https://suzano.webhook.office.com/webhookb2/b51ef5a0-c9de-49e7-a0e1-18b02afc9375@a7109315-9727-4adf-97ad-4849bb63edcb/IncomingWebhook/e51f6b50cfeb4bd8a9ba8754fb37b192/771f5608-c1bc-4480-b881-74cc85bff5f9'

# Defina os arquivos para salvar os resultados
property_file = "property_names.txt"
origin_file = "origins.txt"
ip_property_file = "property_name_origins_IP.txt"
log_file = "script_output.txt"

# Limpar o conteúdo dos arquivos antes de começar
with open(property_file, "w") as pf, open(origin_file, "w") as of, open(ip_property_file, "w") as ipf, open(log_file, "w") as lf:
    pf.write("")  # Limpar o arquivo de property_names
    of.write("")  # Limpar o arquivo de origins
    ipf.write("")  # Limpar o arquivo de property_names com IPs
    lf.write("")  # Limpar o arquivo de log

# Lista para armazenar as entradas adicionadas ao /etc/hosts
hosts_entries_added = []

def send_teams_notification(message, alert_title='DevSecOps Apps sem regra WAF', alert_details='URL Tracking', post_link=''):
    payload = {
        '@type': 'MessageCard',
        '@context': 'http://schema.org/extensions',
        'themeColor': '0072C6',
        'title': f'🚨 {alert_title}' if alert_title else 'Notificação',
        'text': f'**Atenção RedTeam!**\n\n{message}\n\n**Detalhes**: {alert_details}\n\nLink para a postagem: [Clique aqui]({post_link})' if alert_details and post_link else f'**Atenção RedTeam!**\n\n{message}'
    }
    try:
        response = requests.post(TEAMS_WEBHOOK_URL, json=payload, verify=False)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Erro ao enviar notificação para o Microsoft Teams: {e}")

# def get_group_ids():
#     # Retornar um groupId fixo para teste
#     return ["grp_205613"]

def get_group_ids():
    command = ["akamai", "property-manager", "-f", "json", "lg"]
    result = subprocess.run(command, stdout=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print("Erro ao obter groupIds.")
        return []
    
    try:
        group_ids = json.loads(result.stdout)
        return [group['groupId'] for group in group_ids]
    except json.JSONDecodeError:
        print("Erro ao decodificar JSON ao obter groupIds.")
        return []

def get_properties_and_origins(group_ids):
    property_origin_map = {}  # Dicionário para armazenar property_name -> origin
    
    with open(property_file, "a") as pf, open(origin_file, "a") as of:
        # Primeiro, coleta todos os propertyName para cada groupId
        for group_id in group_ids:
            print(f"\nExecutando comando para groupId: {group_id}")
            command = ["akamai", "property-manager", "-f", "json", "-c", "ctr_V-3WET01Y", "-g", group_id, "lpr"]
            result = subprocess.run(command, stdout=subprocess.PIPE, text=True)
            
            if result.returncode == 0 and result.stdout.strip():
                try:
                    property_list = json.loads(result.stdout)
                    for prop in property_list:
                        property_name = prop['propertyName']
                        print(f"Coletado propertyName: {property_name}")
                        # Armazena o propertyName para processamento posterior
                        property_origin_map[property_name] = None  # Inicialmente sem origin
                except json.JSONDecodeError:
                    print(f"Erro ao decodificar JSON ao obter properties para groupId {group_id}.")
            else:
                print(f"A resposta não é um JSON válido para groupId: {group_id}")
        
        # Agora, processa todos os propertyNames coletados
        for property_name in property_origin_map.keys():
            print(f"\nExecutando comando para propertyName: {property_name}")
            
            # Executa o comando com jq para obter o origin diretamente
            command_sr = ["akamai", "property-manager", "sr", "-p", property_name]
            result_sr = subprocess.run(command_sr, stdout=subprocess.PIPE, text=True)
            
            if result_sr.returncode == 0 and result_sr.stdout.strip():
                try:
                    origin_info = json.loads(result_sr.stdout)
                    origin = next((behavior['options']['hostname'] for behavior in origin_info['rules']['behaviors'] if behavior['name'] == 'origin'), "Not Found")
                    
                    if origin != "Not Found":
                        print(f"{property_name} - origin = {origin}")
                        property_origin_map[property_name] = origin  # Atualiza o dicionário com o origin
                        pf.write(f"{property_name}\n")  # Salva propertyName no arquivo
                        of.write(f"{origin}\n")  # Salva origin no arquivo
                    else:
                        print(f"{property_name} - origin = Not Found")
                except json.JSONDecodeError:
                    print(f"Erro ao decodificar JSON ao obter origin para {property_name}.")
            else:
                print(f"Erro ao obter origin para {property_name}.")
    
    return property_origin_map

def is_ip_address(origin):
    try:
        socket.inet_aton(origin)
        return True
    except socket.error:
        return False

def add_entry_to_hosts(origin, property_name):
    entry = f"{origin} {property_name}\n"
    with open("/etc/hosts", "a") as hosts_file:
        hosts_file.write(entry)
    hosts_entries_added.append(entry)

def remove_entries_from_hosts():
    with open("/etc/hosts", "r") as hosts_file:
        lines = hosts_file.readlines()
    with open("/etc/hosts", "w") as hosts_file:
        for line in lines:
            if line not in hosts_entries_added:
                hosts_file.write(line)

def check_urls_with_httpx(property_origin_map):
    all_messages = ""
    with open(ip_property_file, "a") as ipf:
        for property_name, origin in property_origin_map.items():
            if is_ip_address(origin):
                # Adicionar ao /etc/hosts e armazenar a entrada
                add_entry_to_hosts(origin, property_name)
                
                # Salvar apenas property_name no arquivo de IPs
                ipf.write(f"{property_name}\n")
                ipf.flush()  # Garantir que a escrita seja imediata

            # Verificação com httpx para o origin
            command_httpx = ["httpx", "-u", origin, "-probe", "-sc", "-cname", "-mc", "200,301", "-j"]
            result_httpx = subprocess.run(command_httpx, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            
            print(result_httpx)
            
            if result_httpx.returncode == 0 and result_httpx.stdout.strip():
                try:
                    # Carregar o JSON diretamente
                    httpx_output = json.loads(result_httpx.stdout.strip())
                    url = httpx_output.get("url")
                    status_code = httpx_output.get("status_code")
                    message = f"\n➡️{property_name} - **Server:** {url} - **Code:** {status_code}"
                    all_messages += message + "\n\n"
                    print(f"➡️  {property_name} - **Server:** {url} - **Code:** {status_code}")
                except json.JSONDecodeError:
                    print(f"Erro ao decodificar JSON na verificação HTTPX para {origin}.")
        
        # Verificação com curl para os property_name no arquivo IP
        with open(ip_property_file, "r") as ipf_read:
            property_names = ipf_read.readlines()
            for property_name in property_names:
                property_name = property_name.strip()
                url = f"https://{property_name}"
                command_curl = ["curl", "--max-time", "5", "-k","-o", "/dev/null", "-s", "-w", "HTTP Code: %{http_code}\nIPv4: %{remote_ip}\n", url]
                # print(command_curl)                
                result_curl = subprocess.run(command_curl, stdout=subprocess.PIPE, text=True)
                # print(result_curl)
                
                if result_curl.returncode == 0:
                    output = result_curl.stdout.strip()
                    status_code = output.split('\n')[0].split(': ')[1]
                    ipv4 = output.split('\n')[1].split(': ')[1]

                    # Só notifica se o código de status for diferente de "000"
                    # if status_code != "000" and status_code != "403" and status_code != "404" and status_code != "503":
                    if status_code == "200" or status_code == "301" or status_code == "302":
                        message = f"\n➡️{property_name} - **IPv4:** {ipv4} - **Code:** {status_code}"
                        all_messages += message + "\n\n"
                        print(f"➡️  {property_name} - **IPv4:** https://{ipv4} - **Code:** {status_code}")
                else:
                    print(f"Erro ao verificar o property_name com curl: {property_name}")

    return all_messages

def main():
    # Obter todos os groupIds
    group_ids = get_group_ids()
    if not group_ids:
        print("Nenhum groupId encontrado!")
        return
    
    # Obter properties e origins para os groupIds
    property_origin_map = get_properties_and_origins(group_ids)
    
    if not property_origin_map:
        print("Nenhum propertyName e origin encontrado!")
        return
    
    try:
        # Checar URLs com httpx e enviar notificações
        all_messages = check_urls_with_httpx(property_origin_map)
        
        if all_messages:
            send_teams_notification(all_messages)
        else:
            print("Nenhuma URL válida retornada pelo httpx.")
    finally:
        # Remover as entradas adicionadas ao /etc/hosts
        remove_entries_from_hosts()

if __name__ == "__main__":
    main()
