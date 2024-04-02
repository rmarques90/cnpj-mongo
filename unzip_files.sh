#!/bin/bash

# Função para descompactar arquivos zip
descompactar_zip () {
  # Pasta de entrada com os arquivos zip
  pasta_entrada="dados-publicos-zip"

  # Pasta de saída para os arquivos descompactados
  pasta_saida="dados-publicos"

  # Loop para ler todos os arquivos zip na pasta de entrada
  for arquivo_zip in "$pasta_entrada"/*.zip; do
    echo "Descompactando $arquivo_zip"

    # Descompactar o arquivo zip na pasta de saída
    unzip -q -d "$pasta_saida" "$arquivo_zip" && rm "$arquivo_zip"

    # Exibir mensagem de sucesso
    echo "Arquivo $arquivo_zip descompactado com sucesso!"
  done
}
descompactar_zip