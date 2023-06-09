#!/bin/bash

set -u

version=0.41.1
auto_completion=
key_bindings=
update_config=2
shells="bash zsh fish"
prefix='~/.fzf'
prefix_expand=~/.fzf
fish_dir=${XDG_CONFIG_HOME:-$HOME/.config}/fish

help() {
  cat << EOF
usage: $0 [OPTIONS]

    --help               Show this message
    --bin                Download fzf binary only; Do not generate ~/.fzf.{bash,zsh}
    --all                Download fzf binary and update configuration files
                         to enable key bindings and fuzzy completion
    --xdg                Generate files under \$XDG_CONFIG_HOME/fzf
    --[no-]key-bindings  Enable/disable key bindings (CTRL-T, CTRL-R, ALT-C)
    --[no-]completion    Enable/disable fuzzy completion (bash & zsh)
    --[no-]update-rc     Whether or not to update shell configuration files

    --no-bash            Do not set up bash configuration
    --no-zsh             Do not set up zsh configuration
    --no-fish            Do not set up fish configuration
EOF
}

for opt in "$@"; do
  case $opt in
    --help)
      help
      exit 0
      ;;
    --all)
      auto_completion=1
      key_bindings=1
      update_config=1
      ;;
    --xdg)
      prefix='"${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf'
      prefix_expand=${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf
      mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/fzf"
      ;;
    --key-bindings)    key_bindings=1    ;;
    --no-key-bindings) key_bindings=0    ;;
    --completion)      auto_completion=1 ;;
    --no-completion)   auto_completion=0 ;;
    --update-rc)       update_config=1   ;;
    --no-update-rc)    update_config=0   ;;
    --bin)             ;;
    --no-bash)         shells=${shells/bash/} ;;
    --no-zsh)          shells=${shells/zsh/} ;;
    --no-fish)         shells=${shells/fish/} ;;
    *)
      echo "unknown option: $opt"
      help
      exit 1
      ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")"
fzf_base=$(pwd)
fzf_base_esc=$(printf %q "$fzf_base")

ask() {
  while true; do
    read -p "$1 ([y]/n) " -r
    REPLY=${REPLY:-"y"}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 1
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      return 0
    fi
  done
}

check_binary() {
  echo -n "  - Checking fzf executable ... "
  local output
  output=$("$fzf_base"/bin/fzf --version 2>&1)
  if [ $? -ne 0 ]; then
    echo "Error: $output"
    binary_error="Invalid binary"
  else
    output=${output/ */}
    if [ "$version" != "$output" ]; then
      echo "$output != $version"
      binary_error="Invalid version"
    else
      echo "$output"
      binary_error=""
      return 0
    fi
  fi
  rm -f "$fzf_base"/bin/fzf
  return 1
}

link_fzf_in_path() {
  if which_fzf="$(command -v fzf)"; then
    echo "  - Found in \$PATH"
    echo "  - Creating symlink: bin/fzf -> $which_fzf"
    (cd "$fzf_base"/bin && rm -f fzf && ln -sf "$which_fzf" fzf)
    check_binary && return
  fi
  return 1
}

try_curl() {
  command -v curl > /dev/null &&
  if [[ $1 =~ tar.gz$ ]]; then
    curl -fL $1 | tar -xzf -
  else
    local temp=${TMPDIR:-/tmp}/fzf.zip
    curl -fLo "$temp" $1 && unzip -o "$temp" && rm -f "$temp"
  fi
}

try_wget() {
  command -v wget > /dev/null &&
  if [[ $1 =~ tar.gz$ ]]; then
    wget -O - $1 | tar -xzf -
  else
    local temp=${TMPDIR:-/tmp}/fzf.zip
    wget -O "$temp" $1 && unzip -o "$temp" && rm -f "$temp"
  fi
}

download() {
  echo "Downloading bin/fzf ..."
  if [ -x "$fzf_base"/bin/fzf ]; then
    echo "  - Already exists"
    check_binary && return
  fi
  link_fzf_in_path && return
  mkdir -p "$fzf_base"/bin && cd "$fzf_base"/bin
  if [ $? -ne 0 ]; then
    binary_error="Failed to create bin directory"
    return
  fi

  local url
  url=https://github.com/junegunn/fzf/releases/download/$version/${1}
  set -o pipefail
  if ! (try_curl $url || try_wget $url); then
    set +o pipefail
    binary_error="Failed to download with curl and wget"
    return
  fi
  set +o pipefail

  if [ ! -f fzf ]; then
    binary_error="Failed to download ${1}"
    return
  fi

  chmod +x fzf && check_binary
}

# Try to download binary executable
archi=$(uname -sm)
binary_available=1
binary_error=""
case "$archi" in
  Darwin\ arm64)      download fzf-$version-darwin_arm64.zip     ;;
  Darwin\ x86_64)     download fzf-$version-darwin_amd64.zip     ;;
  Linux\ armv5*)      download fzf-$version-linux_armv5.tar.gz   ;;
  Linux\ armv6*)      download fzf-$version-linux_armv6.tar.gz   ;;
  Linux\ armv7*)      download fzf-$version-linux_armv7.tar.gz   ;;
  Linux\ armv8*)      download fzf-$version-linux_arm64.tar.gz   ;;
  Linux\ aarch64*)    download fzf-$version-linux_arm64.tar.gz   ;;
  Linux\ loongarch64) download fzf-$version-linux_loong64.tar.gz ;;
  Linux\ ppc64le)     download fzf-$version-linux_ppc64le.tar.gz ;;
  Linux\ *64)         download fzf-$version-linux_amd64.tar.gz   ;;
  Linux\ s390x)       download fzf-$version-linux_s390x.tar.gz   ;;
  FreeBSD\ *64)       download fzf-$version-freebsd_amd64.tar.gz ;;
  OpenBSD\ *64)       download fzf-$version-openbsd_amd64.tar.gz ;;
  CYGWIN*\ *64)       download fzf-$version-windows_amd64.zip    ;;
  MINGW*\ *64)        download fzf-$version-windows_amd64.zip    ;;
  MSYS*\ *64)         download fzf-$version-windows_amd64.zip    ;;
  Windows*\ *64)      download fzf-$version-windows_amd64.zip    ;;
  *)                  binary_available=0 binary_error=1          ;;
esac

cd "$fzf_base"
if [ -n "$binary_error" ]; then
  if [ $binary_available -eq 0 ]; then
    echo "No prebuilt binary for $archi ..."
  else
    echo "  - $binary_error !!!"
  fi
  if command -v go > /dev/null; then
    echo -n "Building binary (go get -u github.com/junegunn/fzf) ... "
    if [ -z "${GOPATH-}" ]; then
      export GOPATH="${TMPDIR:-/tmp}/fzf-gopath"
      mkdir -p "$GOPATH"
    fi
    if go get -ldflags "-s -w -X main.version=$version -X main.revision=go-get" github.com/junegunn/fzf; then
      echo "OK"
      cp "$GOPATH/bin/fzf" "$fzf_base/bin/"
    else
      echo "Failed to build binary. Installation failed."
      exit 1
    fi
  else
    echo "go executable not found. Installation failed."
    exit 1
  fi
fi

[[ "$*" =~ "--bin" ]] && exit 0

for s in $shells; do
  if ! command -v "$s" > /dev/null; then
    shells=${shells/$s/}
  fi
done

if [[ ${#shells} -lt 3 ]]; then
  echo "No shell configuration to be updated."
  exit 0
fi

# Auto-completion
if [ -z "$auto_completion" ]; then
  ask "Do you want to enable fuzzy auto-completion?"
  auto_completion=$?
fi

# Key-bindings
if [ -z "$key_bindings" ]; then
  ask "Do you want to enable key bindings?"
  key_bindings=$?
fi

echo
for shell in $shells; do
  [[ "$shell" = fish ]] && continue
  src=${prefix_expand}.${shell}
  echo -n "Generate $src ... "

  fzf_completion="[[ \$- == *i* ]] && source \"$fzf_base/shell/completion.${shell}\" 2> /dev/null"
  if [ $auto_completion -eq 0 ]; then
    fzf_completion="# $fzf_completion"
  fi

  fzf_key_bindings="source \"$fzf_base/shell/key-bindings.${shell}\""
  if [ $key_bindings -eq 0 ]; then
    fzf_key_bindings="# $fzf_key_bindings"
  fi

  cat > "$src" << EOF
# Setup fzf
# ---------
if [[ ! "\$PATH" == *$fzf_base_esc/bin* ]]; then
  PATH="\${PATH:+\${PATH}:}$fzf_base/bin"
fi

# Auto-completion
# ---------------
$fzf_completion

# Key bindings
# ------------
$fzf_key_bindings
EOF
  echo "OK"
done

# fish
if [[ "$shells" =~ fish ]]; then
  echo -n "Update fish_user_paths ... "
  fish << EOF
  echo \$fish_user_paths | \grep "$fzf_base"/bin > /dev/null
  or set --universal fish_user_paths \$fish_user_paths "$fzf_base"/bin
EOF
  [ $? -eq 0 ] && echo "OK" || echo "Failed"

  mkdir -p "${fish_dir}/functions"
  fish_binding="${fish_dir}/functions/fzf_key_bindings.fish"
  if [ $key_bindings -ne 0 ]; then
    echo -n "Symlink $fish_binding ... "
    ln -sf "$fzf_base/shell/key-bindings.fish" \
           "$fish_binding" && echo "OK" || echo "Failed"
  else
    echo -n "Removing $fish_binding ... "
    rm -f "$fish_binding"
    echo "OK"
  fi
fi

append_line() {
  set -e

  local update line file pat lno
  update="$1"
  line="$2"
  file="$3"
  pat="${4:-}"
  lno=""

  echo "Update $file:"
  echo "  - $line"
  if [ -f "$file" ]; then
    if [ $# -lt 4 ]; then
      lno=$(\grep -nF "$line" "$file" | sed 's/:.*//' | tr '\n' ' ')
    else
      lno=$(\grep -nF "$pat" "$file" | sed 's/:.*//' | tr '\n' ' ')
    fi
  fi
  if [ -n "$lno" ]; then
    echo "    - Already exists: line #$lno"
  else
    if [ $update -eq 1 ]; then
      [ -f "$file" ] && echo >> "$file"
      echo "$line" >> "$file"
      echo "    + Added"
    else
      echo "    ~ Skipped"
    fi
  fi
  echo
  set +e
}

create_file() {
  local file="$1"
  shift
  echo "Create $file:"
  for line in "$@"; do
    echo "    $line"
    echo "$line" >> "$file"
  done
  echo
}

if [ $update_config -eq 2 ]; then
  echo
  ask "Do you want to update your shell configuration files?"
  update_config=$?
fi
echo
for shell in $shells; do
  [[ "$shell" = fish ]] && continue
  [ $shell = zsh ] && dest=${ZDOTDIR:-~}/.zshrc || dest=~/.bashrc
  append_line $update_config "[ -f ${prefix}.${shell} ] && source ${prefix}.${shell}" "$dest" "${prefix}.${shell}"
done

if [ $key_bindings -eq 1 ] && [[ "$shells" =~ fish ]]; then
  bind_file="${fish_dir}/functions/fish_user_key_bindings.fish"
  if [ ! -e "$bind_file" ]; then
    create_file "$bind_file" \
      'function fish_user_key_bindings' \
      '  fzf_key_bindings' \
      'end'
  else
    append_line $update_config "fzf_key_bindings" "$bind_file"
  fi
fi

if [ $update_config -eq 1 ]; then
  echo 'Finished. Restart your shell or reload config file.'
  if [[ "$shells" =~ bash ]]; then
    echo -n '   source ~/.bashrc  # bash'
    [[ "$archi" =~ Darwin ]] && echo -n '  (.bashrc should be loaded from .bash_profile)'
    echo
  fi
  [[ "$shells" =~ zsh ]]  && echo "   source ${ZDOTDIR:-~}/.zshrc   # zsh"
  [[ "$shells" =~ fish ]] && [ $key_bindings -eq 1 ] && echo '   fzf_key_bindings  # fish'
  echo
  echo 'Use uninstall script to remove fzf.'
  echo
fi
echo 'For more information, see: https://github.com/junegunn/fzf'
