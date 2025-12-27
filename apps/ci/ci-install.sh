#!/bin/bash

set -e

cat >>conf/config.sh <<CONFIG_SH
MTHREADS=$(($(grep -c ^processor /proc/cpuinfo) + 2))
CWARNINGS=ON
CDEBUG=OFF
CTYPE=Release
CSCRIPTS=static
CBUILD_TESTING=ON
CSERVERS=ON
CTOOLS=ON
CSCRIPTPCH=OFF
CCOREPCH=OFF
CCUSTOMOPTIONS='-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_FLAGS="-Werror" -DCMAKE_CXX_FLAGS="-Werror"'
CONFIG_SH

# cross-distro helpers
function is_fedora() {
  grep -qi "fedora" /etc/os-release 2>/dev/null || [ -f /etc/fedora-release ]
}

function pkg_update() {
  if is_fedora; then
    sudo dnf -y makecache
    sudo dnf -y upgrade
  else
    sudo apt-get update -y
  fi
}

function pkg_install() {
  if is_fedora; then
    sudo dnf -y install "$@"
  else
    sudo apt-get -y install "$@"
  fi
}

# Update package cache and install basic dependencies
time pkg_update
# time sudo apt-get upgrade -y
if is_fedora; then
  time pkg_install git dnf-plugins-core sudo
else
  time pkg_install git lsb-release sudo
fi

time ./acore.sh install-deps

case $COMPILER in

  # this is in order to use the "default" gcc version of the OS, without forcing a specific version
  "gcc" )
    if is_fedora; then
      time sudo dnf -y install gcc gcc-c++
      echo "CCOMPILERC=\"gcc\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"g++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y gcc g++
      echo "CCOMPILERC=\"gcc\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"g++\"" >> ./conf/config.sh
    fi
    ;;

  "gcc8" )
    if is_fedora; then
      echo "Requested gcc-8. Fedora usually ships newer compilers; installing default gcc instead."
      time sudo dnf -y install gcc gcc-c++
      echo "CCOMPILERC=\"gcc\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"g++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y gcc-8 g++-8
      echo "CCOMPILERC=\"gcc-8\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"g++-8\"" >> ./conf/config.sh
    fi
    ;;

  "gcc10" )
    if is_fedora; then
      echo "Requested gcc-10. Fedora usually ships newer compilers; installing default gcc instead."
      time sudo dnf -y install gcc gcc-c++
      echo "CCOMPILERC=\"gcc\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"g++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y gcc-10 g++-10
      echo "CCOMPILERC=\"gcc-10\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"g++-10\"" >> ./conf/config.sh
    fi
    ;;

  # this is in order to use the "default" clang version of the OS, without forcing a specific version
  "clang" )
    if is_fedora; then
      time sudo dnf -y install clang
      echo "CCOMPILERC=\"clang\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y clang
      echo "CCOMPILERC=\"clang\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++\"" >> ./conf/config.sh
    fi
    ;;

  "clang10" )
    if is_fedora; then
      echo "Requested clang-10. Installing default clang instead."
      time sudo dnf -y install clang
      echo "CCOMPILERC=\"clang\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y clang-10
      echo "CCOMPILERC=\"clang-10\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++-10\"" >> ./conf/config.sh
    fi
    ;;

  "clang11" )
    if is_fedora; then
      echo "Requested clang-11. Installing default clang instead."
      time sudo dnf -y install clang
      echo "CCOMPILERC=\"clang\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y clang-11
      echo "CCOMPILERC=\"clang-11\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++-11\"" >> ./conf/config.sh
    fi
    ;;

  "clang12" )
    if is_fedora; then
      echo "Requested clang-12. Installing default clang instead."
      time sudo dnf -y install clang
      echo "CCOMPILERC=\"clang\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++\"" >> ./conf/config.sh
    else
      time sudo apt-get install -y clang-12
      echo "CCOMPILERC=\"clang-12\"" >> ./conf/config.sh
      echo "CCOMPILERCXX=\"clang++-12\"" >> ./conf/config.sh
    fi
    ;;

  * )
    echo "Unknown compiler $COMPILER"
    exit 1
    ;;
esac
