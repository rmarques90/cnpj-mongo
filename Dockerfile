FROM ubuntu:latest
WORKDIR /usr/app

RUN apt-get update && apt-get install -y curl unzip csvtool
RUN curl -O https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb
RUN apt install ./mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb
RUN curl -O https://downloads.mongodb.com/compass/mongodb-mongosh_2.2.2_amd64.deb
RUN apt install ./mongodb-mongosh_2.2.2_amd64.deb

RUN mkdir dados-publicos && mkdir dados-publicos-zip

COPY ./get-dados-gov.sh /usr/app
COPY ./unzip_files.sh /usr/app
COPY ./entrypoint-mongo.sh /usr/app

CMD ["bash", "entrypoint-mongo.sh"]