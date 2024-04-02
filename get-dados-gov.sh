#!/bin/bash

echo "Script to download files from receita..."

qtd='5'
download='dados-publicos-zip'

if [ ! -d "$download" ]; then
  echo "Pasta de download '$download' não existe. Finalizando o script."
  exit 1
fi

url='http://200.152.38.155/CNPJ/'
agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0"

curl -s $url | sed -e 's|"|\n|g' | grep -i '.zip$' | sort -u | sed -e "s|^|$url|g" |
while read item; do

        stat=$(ps -ef | grep "$url" | grep -v grep | wc -l)
        file=$(echo $item | sed -e 's|.*/||g')

        if [ $stat -lt $qtd ];then
                curl -s --user-agent "$agent" -o "$download/$file" $item &
        else
                until [ $stat -lt $qtd ]; do
                        stat=$(ps -ef | grep "$url" | grep -v grep | wc -l)
                        sleep 5
                done
                curl -s --user-agent "$agent" -o "$download/$file" $item &
        fi
done