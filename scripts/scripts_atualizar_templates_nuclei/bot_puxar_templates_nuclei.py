import requests
import os
import re
import hashlib
import pickle
from urllib.parse import unquote

# Use a pickle file to store the hashes
hashes_file = 'file_hashes.pkl'

# Load the saved hashes
if os.path.exists(hashes_file):
    with open(hashes_file, 'rb') as f:
        saved_hashes = pickle.load(f)
else:
    saved_hashes = {}

# Calculate the hash of a file
def calculate_hash(file_path):
    h = hashlib.sha256()
    with open(file_path, 'rb') as file:
        while True:
            # Read the file in chunks of 4096 bytes
            chunk = file.read(4096)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()

def download_content(url, output_path):
    response = requests.get(url)
    if response.status_code == 200:
        os.makedirs(os.path.dirname(output_path), exist_ok=True) # Cria os diretórios necessários
        with open(output_path, 'wb') as file:
            file.write(response.content)
        print(f"Downloaded content from {url} saved to {output_path}")
    else:
        print(f"Failed to download content from {url}")

file_path = "links.txt"

output_directory = "/root/Vault_BugBounty/redmc_custom_templates_nuclei"

with open(file_path, 'r') as file:
    links = file.read().splitlines()

# Regex pattern to extract the relevant part of the URL
pattern = re.compile(r"https://github.com/projectdiscovery/nuclei-templates/raw/.+/(.+)")

# Loop para fazer o download de cada link
for link in links:
    # Use regex to get the relevant part of the URL, then decode the URL-encoded characters
    match = pattern.search(link)
    if match:
        path = unquote(match.group(1))
        output_path = os.path.join(output_directory, path)

        if os.path.exists(output_path) and saved_hashes.get(output_path) == calculate_hash(output_path):
            # print(f"Skipping download for {output_path}, file already exists and has not been modified.")
            continue  # Skip this file

        download_content(link, output_path)

        # Update the hash
        saved_hashes[output_path] = calculate_hash(output_path)
    else:
        print(f"Could not parse URL: {link}")

# Save the hashes for next time
with open(hashes_file, 'wb') as f:
    pickle.dump(saved_hashes, f)
