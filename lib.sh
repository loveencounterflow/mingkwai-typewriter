#!/bin/bash
set -euo pipefail


#-----------------------------------------------------------------------------------------------------------
grey='\x1b[38;05;240m'
blue='\x1b[38;05;27m'
lime='\x1b[38;05;118m'
orange='\x1b[38;05;208m'
red='\x1b[38;05;124m'
reset='\x1b[0m'
function info    () { set +u;  printf "$grey""SQLITE INSTALLER ""$blue%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function help    () { set +u;  printf "$grey""SQLITE INSTALLER ""$lime%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function urge    () { set +u;  printf "$grey""SQLITE INSTALLER ""$orange%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function warn    () { set +u;  printf "$grey""SQLITE INSTALLER ""$red%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function whisper () { set +u;  printf "$grey""SQLITE INSTALLER ""$grey%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }

#-----------------------------------------------------------------------------------------------------------
# if [ -z "${1+x}" ]; then
#   urge "usage:"
#   urge "$0 path/to/sqlite-amalgamation"
#   # exit 1
#   fi

#-----------------------------------------------------------------------------------------------------------
sqltfmki_path='./sqlite-for-mingkwai-ime'
sqltfmki_url='https://github.com/loveencounterflow/sqlite-for-mingkwai-ime.git'
bsql3_name='better-sqlite3'
bsql3_path='./better-sqlite3'
bsql3_url='https://github.com/JoshuaWise/better-sqlite3'
# help "looking for $bsql3_path"


#-----------------------------------------------------------------------------------------------------------
function procure_package {
  path="$1"
  url="$2"
  if [ -d "$path" ]; then
    help "exists: $path"
    warn "updating from $url"
    ( cd "$path" && git pull origin master )
  else
    warn "missing: $path"
    warn "retrieving $url"
    git clone "$url"
    fi
  }

#-----------------------------------------------------------------------------------------------------------
function build_sqlite_for_mingkwai_ime {
  help "building sqlite-for-mingkwai-ime"
  cd "$sqltfmki_path"; whisper "cd $(pwd)"
  ./build.sh
  ./build-extensions.sh
  cd "$home"; whisper "cd $(pwd)"
  }

#-----------------------------------------------------------------------------------------------------------
function build_better_sqlite3_with_sqlite_for_mingkwai_ime {
  path="$1"
  help "building better-sqlite3 using SQLite sources in $path"
  path="$(realpath $path)"
  cd "$bsql3_path"; whisper "cd $(pwd)"
  C_INCLUDE_PATH="$path" npm install --sqlite3="$path"
  cd "$home"; whisper "cd $(pwd)"
  }


#-----------------------------------------------------------------------------------------------------------
function link_better_sqlite3 {
  path="$bsql3_path"
  help "creating symlink in node_modules to $bsql3_path"
  path="$(realpath $path)"
  mkdir -p node_modules
  cd node_modules; whisper "cd $(pwd)"
  if [ -e "$bsql3_name" ]; then
    help "exists: $path"
    if [ -L "$bsql3_name" ]; then
      help "$bsql3_name --> $(readlink $bsql3_name)"
    else
      warn "$bsql3_name is not a symlink; did you already install better-sqlite3?"
      fi
  else
    ln -s "$(realpath --relative-to=. "$path")"
    fi
  cd "$home"; whisper "cd $(pwd)"
  }

