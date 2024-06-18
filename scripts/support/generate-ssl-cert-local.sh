#!/bin/bash

rootDir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OS=$(uname -s)

case "$OS" in
	Linux)
        RED="\e[31m"
		BLUE="\e[34m"
		MAGENTA="\e[35m"
		NO_COLOR="\e[0m"
		;;
	Darwin)
        RED="\033[31m"
		BLUE="\033[34m"
		MAGENTA="\033[35m"
		NO_COLOR="\033[m"
		;;
esac

sslPath="$rootDir/.ssl"
if [ ! -d "$sslPath" ]; then
    mkdir -p "$sslPath"
    echo -e "${BLUE}created $sslPath${NO_COLOR}"
fi

while read -r line || [[ -n "$line" ]]; do
    if [[ $line == SSL_PFX_PATH=* ]]; then
        pfxPath="${line#*=}"
    elif [[ $line == SSL_PFX_PASSWORD=* ]]; then
        pfxPassword="${line#*=}"
    fi
done < "$rootDir/.env"

if [ -z "$pfxPath" ] || [ ! -f "$pfxPath" ]; then
    echo -e "${RED}Unable to generate SSL certificate files. PFX file not found.${NO_COLOR}"
    exit 1
fi

if [ -z "$pfxPassword" ]; then
    echo -e "${RED}Unable to generate SSL certificate files. PFX file password not found.${NO_COLOR}"
    exit 1
fi

keyPath=$(grep '^SSL_KEY_FILE=' "$rootDir/.env" | cut -d'=' -f2)

if [ -z "$keyPath" ]; then
    echo -e "${RED}Unable to generate SSL certificate KEY file. Destination path not specified.${NO_COLOR}"
    exit 1
fi

if [ ! -f "$keyPath" ]; then
    openssl pkcs12 -nocerts -nodes \
      -in "$pfxPath" \
      -out "$keyPath" \
      -passin pass:$pfxPassword

    echo -e "${BLUE}Created $keyPath.${NO_COLOR}"
fi

crtPath=$(grep '^SSL_CRT_FILE=' "$rootDir/.env" | cut -d'=' -f2)

if [ -z "$crtPath" ]; then
    echo -e "${RED}Unable to generate SSL certificate CER file. Destination path not specified.${NO_COLOR}"
    exit 1
fi

if [ ! -f "$crtPath" ]; then
    openssl pkcs12 -clcerts -nokeys \
      -in "$pfxPath" \
      -out "$crtPath" \
      -passin pass:$pfxPassword

    echo -e "${BLUE}Created $crtPath.${NO_COLOR}"
fi
