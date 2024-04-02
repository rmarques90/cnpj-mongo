# CNPJ para MongoDB

Projeto inspirado no repositório: https://github.com/rictom/cnpj-sqlite e https://github.com/rictom/cnpj-mysql

## Como utilizar

Recomendo utilizar via docker, assim ficará mais fácil para executar.

### Docker

Gerar o build utilizando o Dockerfile `docker build -t cnpj-mongo .`
Depois rodar a imagem configurando um arquivo .env com as propriedades contidas no model.env.

Para executar: `docker run -d --name cnpj-mongo --env-file .env cnpj-mongo`

Esse processo pode levar em torno de 7 a 8 horas. Pode ser que leve mais ou menos dependendo do seu recurso computacional.


### Shell

Antes, você precisa adicionar os pacotes confome informado no Dockerfile. Por isso recomendo via Docker.

Para executar em shell, basta ajustar as variaveis de ambiente conforme model.env, ou entao substituir no inicio do arquivo `entrypoint-mongo.sh`

Recomendo executar `chmod +x get-dados-gov.sh && chmod +x unzip_files.sh && chmod +x entrypoint-mongo.sh` para dar as permissões corretas aos scripts.

Após isso, basta executar `./entrypoint-mongo.sh` e aguardar a finalização. Caso rode em um servidor, recomendo usar screen.
