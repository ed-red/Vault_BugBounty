#!/bin/bash

# Inspiration from the blog https://blog.projectdiscovery.io/building-one-shot-recon/

#--- set colors
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

# set vars
COMPANY="$1"
GIT_ROOT="/root/Vault_BugBounty"
echo $GIT_ROOT

SUBDOM_LIST="$GIT_ROOT/wordlists/assetnote.io_best-dns-wordlist.txt"
RESOLVERS="$GIT_ROOT/resolvers/resolvers.txt"
export DOTFILES=$PWD
COMPANIES_H1="/root/recons/companies.txt"

# Check if /root/recons/ directory exists
if [ ! -d "/root/recons/" ]; then
  echo "${yellow}The directory /root/recons/ does not exist.${reset}"
  read -p "Do you want to create the /root/recons/ directory? (y/N): " create_dir
  case $create_dir in
    [Yy]* ) mkdir -p /root/recons/; echo "${green}/root/recons/ directory created.${reset}";;
    * ) echo "${red}Exiting script.${reset}"; exit 1;;
  esac
fi

# Check if $COMPANIES_H1 file exists
if [ ! -f "$COMPANIES_H1" ]; then
  echo "${yellow}The file $COMPANIES_H1 does not exist.${reset}"
  read -p "Do you want to create the companies.txt file in /root/recons/? (y/N): " create_file
  case $create_file in
    [Yy]* ) touch "$COMPANIES_H1"; echo "${green}companies.txt file created.${reset}";;
    * ) echo "${red}Exiting script.${reset}"; exit 1;;
  esac
fi

# Read companies from file
readarray -t companies < $COMPANIES_H1

# Function to list companies with pagination
list_companies() {
  local start_index=$1
  for ((i=start_index; i<start_index+25 && i<${#companies[@]}; i++)); do
    echo "${green}$((i+1)).${reset} ${companies[i]}"
  done
}

confirmed=false
confirmed_option2=false

scan_company() {
  COMPANY=$1
  CONFIRMED=$2
  confirmed_option2=$3
  # Remove domain suffix to create the directory
  COMPANY_DIR=$(echo $COMPANY | sed 's/\..*//')
  
  # Set the ppath to the first existing recons directory
  if [ -d "$HOME/recons" ]; then
    ppath="$HOME/recons"
  elif [ -d "$GIT_ROOT/recons" ]; then
    ppath="$GIT_ROOT/recons"
  else
    # Ask the user where they want to create the directories
    echo "${blue}[+] Where would you like to create the directories?${reset}"
    echo "${green}1) In the directory $HOME/recons${reset}"
    echo "${green}2) In the current git directory${reset}"
    read -p "Please choose an option (1-2): " option

    # Verify user input and set ppath accordingly
    case $option in
      1) ppath="$HOME/recons";;
      2) ppath="$GIT_ROOT/recons";;
      * ) echo "${red}Invalid option, exiting script.${reset}"; exit 1;;
    esac
  fi

  # Path for the company's scan files
  scan_path="$ppath/scans/$COMPANY_DIR"
  roots_exist="$scan_path/scope.txt" # Points to the domain file

  # Create scan_path if it does not exist
  if [ ! -d "$scan_path" ]; then
    echo "${yellow}[+] Creating directory $scan_path...${reset}"
    mkdir -p "$scan_path"
  fi

  # Create roots_exist if it does not exist
  if [ ! -f "$roots_exist" ]; then
    echo "${yellow}[+] Creating file $roots_exist for $COMPANY...${reset}"
    touch "$roots_exist"
    echo "$COMPANY" >> $roots_exist
  fi

  ### PERFORM SCAN ###
  echo "${yellow}[+]${reset}"

  # Function to manage URLs
  manage_urls() {
      echo "${blue}[+] URLs currently in scope:${reset}"
      cat "$roots_exist"
      echo "${yellow}[+]${reset}"
      echo "${blue}[+] Choose an option:${reset}"
      echo "1. Add URL"
      echo "2. Remove URL"
      echo "3. Back"
      read -r choice
      case $choice in
      1)
          echo "${blue}[+] URLs currently in scope:${reset}"
          cat "$roots_exist"
          echo "${yellow}[+]${reset}"
          echo "${blue}[+] Enter the URL to add (type 'end' to finish):${reset}"
          while read url; do
              # Check if 'end' was typed
              if [[ "$url" == "end" ]]; then
                  break
              fi
              # Check if the URL is already in the file
              if ! grep -Fxq "$url" "$roots_exist"; then
                  echo "$url" >> "$roots_exist"
              fi
          done
          ;;
      2)
          echo "${blue}[+] URLs currently in scope:${reset}"
          cat "$roots_exist"
          echo "${yellow}[+]${reset}"
          echo "${blue}[+] Enter the URL to remove (type 'end' to finish):${reset}"
          while read url; do
              # Check if 'end' was typed
              if [[ "$url" == "end" ]]; then
                  break
              fi
              # Check if the URL is in the file and remove it
              if grep -Fxq "$url" "$roots_exist"; then
                  sed -i "/$url/d" "$roots_exist"
              fi
          done
          ;;
      3)
          # Return to the main menu
          ;;
      *)
          echo "Invalid option."
          manage_urls
          ;;
      esac
      echo "${blue}Contents of scope.txt:${reset}"
      cat "$scan_path/scope.txt"
  }

  # Main menu
  if [ "$confirmed_option2" != "true" ]; then
    while true; do
      echo "${blue}[+] URLs currently in scope:${reset}"
      cat "$roots_exist"
      echo "${yellow}[+]${reset}"
      echo "${blue}[+] Choose an option:${reset}"
      echo "1. Manage Scope"
      echo "2. Start Scan"
      echo "3. Exit"
      read -r choice
      case $choice in
      1)
          manage_urls
          ;;
      2)
          # Start the scan
          confirmed_option2=true
          break
          ;;
      3)
          # Exit the script
          exit 0
          ;;
      *)
          echo "Invalid option."
          ;;
      esac
    done
  fi

  echo "${blue}Contents of scope.txt:${reset}"
  cat "$scan_path/scope.txt"

  echo "${blue}Starting scan against roots:${reset}"
  cat "$roots_exist"
  # cp -v "$roots_exist" "$scan_path/subs.txt"
  cd "$scan_path"

  ##################### ADD SCAN LOGIC HERE #####################
  source /root/Vault_BugBounty/scripts/bot_scan_recon_vuln.sh

}

# List companies and ask the user to select one
start_index=0
scan_all=false
while true; do
  echo "${blue}Available companies:${reset}"
  list_companies $start_index
  echo "---------------------------------------------"
  echo "${yellow}Type 'm' to show more, 'q' to quit, 'a' to scan all companies, or select the company number or write the company name you want to scan:${reset}"
  read -r company_input
  echo "---------------------------------------------"

  if [[ $company_input == 'm' ]]; then
    start_index=$((start_index + 25))
    continue
  elif [[ $company_input == 'q' ]]; then
    echo "${red}Exiting script.${reset}"
    exit 0
  elif [[ $company_input == 'a' ]]; then
    echo "${green}You selected to scan all $(wc -l < $COMPANIES_H1) companies.${reset}"
    scan_all=true
    break
  elif [[ $company_input =~ ^[0-9]+$ ]] && [ "$company_input" -le "${#companies[@]}" ]; then
    COMPANY=${companies[$((company_input-1))]}
    echo "${green}You selected the company:${reset} $COMPANY"
    break
  elif [[ " ${companies[@]} " =~ " ${company_input} " ]]; then
    COMPANY=$company_input
    echo "${green}You selected the company:${reset} $COMPANY"
    break
  else
    echo "${yellow}The company $company_input is not in the list. Do you want to add it? (y/N)${reset}"
    read -r add_company
    if [[ $add_company =~ ^[Yy]$ ]]; then
      echo $company_input >> $COMPANIES_H1
      companies+=("$company_input")
      COMPANY=$company_input
      echo "${green}Company added and selected: ${reset}$COMPANY"
      break
    else
      echo "${red}Invalid input. Please try again.${reset}"
    fi
  fi
done

if $scan_all; then
  for COMPANY in "${companies[@]}"; do
    echo "${green}Scanning the company:${reset} $COMPANY"
    scan_company $COMPANY $confirmed $confirmed_option2
    confirmed=true
    confirmed_option2=true
  done
else
  scan_company $COMPANY false false
fi
