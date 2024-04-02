#!/bin/bash

MONGODB_URI="mongodb://$MONGODB_HOST:${MONGODB_PORT}"
DATABASE_NAME="$MONGODB_NAME"

logDateTime() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to handle MongoDB errors
handleMongoError() {
    logDateTime "Error occurred while executing MongoDB command: $1"
    exit 1
}

logDateTime "Starting cnpj script...may the force be with you! You gonna need it!"
logDateTime "Downloading files..."
./get-dados-gov.sh
#curl -o ./dados-publicos-zip/Cnaes.zip http://200.152.38.155/CNPJ/Cnaes.zip

logDateTime "Unzipping them!"
./unzip_files.sh

ls -lah dados-publicos

#Drop collection if exists

# Import CSV function
importCsvSimple() {
    local csvFile="$1"
    local tableName="$2"
    logDateTime "Converting file to utf8..."
    iconv -f ISO-8859-1 -t UTF-8 $csvFile > $csvFile.utf8
    
    logDateTime "removing quotes..."
    
    #remove quotes
    #sed 's/"//g' -i $csvFile.utf8
    #sed 's/;/,/g' -i $csvFile.utf8

    #logDateTime "adding header..."
    #add header
    sed '1i\codigo.string();descricao.auto()' -i $csvFile.utf8

    csvtool -t ';' -u TAB cat $csvFile.utf8 > $csvFile.tsv

    ln -s "$csvFile.tsv" "$tableName.tsv"
    logDateTime "Importing $csvFile into $tableName..."
    
    mongoimport --uri="$MONGODB_URI" --db="$DATABASE_NAME" --collection="$collectionName" --type=tsv --headerline --ignoreBlanks --columnsHaveTypes --file="$tableName.tsv"

    unlink "$tableName.tsv"
    rm "$csvFile.tsv"
    rm "$csvFile.utf8"
}

logDateTime "Creating database..."

# Drop the current database
mongosh "$MONGODB_URI/$DATABASE_NAME" --eval "db.dropDatabase()" || handleMongoError "Dropping database"

# Create a new database
mongosh "$MONGODB_URI" --eval "use $DATABASE_NAME" || handleMongoError "Creating database"

logDateTime "Running initial script..."

# Import the first simple files

for cnaeCsvFile in $(find ./dados-publicos -name "*.CNAECSV"); do
    logDateTime "Importing $cnaeCsvFile..."
    importCsvSimple "$cnaeCsvFile" "cnae"
done

for csvFile in $(find ./dados-publicos -name "*.MUNICCSV"); do
    logDateTime "Importing $csvFile..."
    importCsvSimple "$csvFile" "municipio"
done

for csvFile in $(find ./dados-publicos -name "*.NATJUCSV"); do
    logDateTime "Importing $csvFile..."
    importCsvSimple "$csvFile" "natureza_juridica"
done

for csvFile in $(find ./dados-publicos -name "*.PAISCSV"); do
    logDateTime "Importing $csvFile..."
    importCsvSimple "$csvFile" "pais"
done

for csvFile in $(find ./dados-publicos -name "*.QUALSCSV"); do
    logDateTime "Importing $csvFile..."
    importCsvSimple "$csvFile" "qualificacao_socio"
done

for csvFile in $(find ./dados-publicos -name "*.MOTICSV"); do
    logDateTime "Importing $csvFile..."
    importCsvSimple "$csvFile" "motivo"
done

colunas_estabelecimento=(
    'cnpj_basico.string()'
    'cnpj_ordem.string()'
    'cnpj_dv.string()'
    'matriz_filial.auto()'
    'nome_fantasia.auto()'
    'situacao_cadastral.auto()'
    'data_situacao_cadastral.auto()'
    'motivo_situacao_cadastral.auto()'
    'nome_cidade_exterior.auto()'
    'pais.auto()'
    'data_inicio_atividades.auto()'
    'cnae_fiscal.string()'
    'cnae_fiscal_secundaria.auto()'
    'tipo_logradouro.auto()'
    'logradouro.auto()'
    'numero.auto()'
    'complemento.auto()'
    'bairro.auto()'
    'cep.auto()'
    'uf.auto()'
    'municipio.auto()'
    'ddd1.auto()'
    'telefone1.auto()'
    'ddd2.auto()'
    'telefone2.auto()'
    'ddd_fax.auto()'
    'fax.auto()'
    'correio_eletronico.auto()'
    'situacao_especial.auto()'
    'data_situacao_especial.auto()'
)

colunas_estabelecimento_comma=$(IFS=';'; echo "${colunas_estabelecimento[*]}")

colunas_empresas=(
    'cnpj_basico.string()'
    'razao_social.auto()'
    'natureza_juridica.auto()'
    'qualificacao_responsavel.auto()'
    'capital_social_str.string()'
    'porte_empresa.auto()'
    'ente_federativo_responsavel.auto()'
)

colunas_empresas_comma=$(IFS=';'; echo "${colunas_empresas[*]}")

colunas_socios=(
    'cnpj_basico.string()'
    'identificador_de_socio.auto()'
    'nome_socio.auto()'
    'cnpj_cpf_socio.auto()'
    'qualificacao_socio.auto()'
    'data_entrada_sociedade.auto()'
    'pais.auto()'
    'representante_legal.auto()'
    'nome_representante.auto()'
    'qualificacao_representante_legal.auto()'
    'faixa_etaria.auto()'
)

colunas_socios_comma=$(IFS=';'; echo "${colunas_socios[*]}")

colunas_simples=(
    'cnpj_basico.string()'
    'opcao_simples.auto()'
    'data_opcao_simples.auto()'
    'data_exclusao_simples.auto()'
    'opcao_mei.auto()'
    'data_opcao_mei.auto()'
    'data_exclusao_mei.auto()'
)

colunas_simples_comma=$(IFS=';'; echo "${colunas_simples[*]}")

# Export Bash arrays as environment variables
export colunas_estabelecimento
export colunas_empresas
export colunas_socios
export colunas_simples

# Define importCsv function to import CSV files into MySQL
importCsvFull() {
    local csvFile="$1"
    local tableName="$2"
    local columns="$3"  # Using bash variable indirection to access array values

    iconv -f ISO-8859-1 -t UTF-8 $csvFile > $csvFile.utf8
    
    logDateTime "Removing quotes..."
    #remove quotes
    #sed 's/"//g' -i $csvFile.utf8
    #sed 's/;/,/g' -i $csvFile.utf8
    
    logDateTime "Adding columns to header..."
    #add header
    sed "1i\\$columns" -i $csvFile.utf8

    csvtool -t ';' -u TAB cat $csvFile.utf8 > $csvFile.tsv

    ln -s "$csvFile.tsv" "$tableName.tsv"

    logDateTime "Importing $csvFile into $tableName..."

    mongoimport --uri="$MONGODB_URI" --db="$DATABASE_NAME" --collection="$collectionName" --type=tsv --ignoreBlanks --headerline --columnsHaveTypes --file="$tableName.tsv"
    
    unlink "$tableName.tsv"
    rm "$csvFile.tsv"
    rm "$csvFile.utf8"
}

logDateTime "Importing big files now..."

for csvFile in $(find ./dados-publicos -name "*.ESTABELE"); do
    echo "Importing $csvFile..."
    importCsvFull "$csvFile" "estabelecimento" $colunas_estabelecimento_comma
done

for csvFile in $(find ./dados-publicos -name "*.SOCIOCSV"); do
    echo "Importing $csvFile..."
    importCsvFull "$csvFile" "socios_original" $colunas_socios_comma
done

for csvFile in $(find ./dados-publicos -name "*.EMPRECSV"); do
    echo "Importing $csvFile..."
    importCsvFull "$csvFile" "empresas" $colunas_empresas_comma
done

for csvFile in $(find ./dados-publicos -name "*.SIMPLES.CSV.*"); do
    echo "Importing $csvFile..."
    importCsvFull "$csvFile" "simples" $colunas_simples_comma
done

logDateTime "Done importing the big ones. Now lets do heavy updates..."

logDateTime "2 - Update the colum capital social..."

# Define the MongoDB update operation
MONGO_UPDATE_OPERATION_CAPITAL='
db.empresas.updateMany(
    { capital_social: { $exists: false } },
    [
        { 
            $set: { 
                capital_social: {
                    $toDouble: {
                        $cond: {
                            if: { $eq: ["$capital_social_str", ""] },
                            then: 0,
                            else: { $toDouble: { $replaceAll: { input: "$capital_social_str", find: ",", replacement: "" } } }
                        }
                    }
                }
            } 
        }
    ]
);
'

# Execute the MongoDB update operation
mongosh "$MONGODB_URI/$DATABASE_NAME" --eval "$MONGO_UPDATE_OPERATION_CAPITAL" || handleMongoError "Updating capital social"


logDateTime "5 - Update cnpj full column..."

MONGO_UPDATE_OPERATION_CNPJ='
db.estabelecimento.updateMany(
    { cnpj: { $exists: false } },
    [
        { 
            $set: { 
                cnpj: { 
                    $concat: [ "$cnpj_basico", "$cnpj_ordem", "$cnpj_dv" ]
                } 
            } 
        }
    ]
);
'

# Execute the MongoDB update operation
mongosh "$MONGODB_URI/$DATABASE_NAME" --eval "$MONGO_UPDATE_OPERATION_CNPJ" || handleMongoError "Updating cnpj"


logDateTime "6 - Final indexes and creating table..."

MONGO_FINAL_OPERATIONS='
db.empresas.createIndex({ cnpj_basico: 1 }, { background: true });
db.empresas.createIndex({ cnpj_: 1 }, { background: true });
db.empresas.createIndex({ razao_social: 1 }, { background: true });
db.estabelecimento.createIndex({ cnpj_basico: 1 }, { background: true });

db.socios_original.createIndex({ cnpj_basico: 1 }, { background: true });

db.socios.drop();

db.socios.aggregate([
    {
        $lookup: {
            from: "estabelecimento",
            localField: "cnpj_basico",
            foreignField: "cnpj_basico",
            as: "estabelecimento"
        }
    },
    {
        $unwind: "$estabelecimento"
    },
    {
        $match: { "estabelecimento.matriz_filial": "1" }
    },
    {
        $project: {
            _id: 0,
            cnpj: "$estabelecimento.cnpj",
            cnpj_basico: "$cnpj_basico",
            identificador_de_socio: 1,
            nome_socio: 1,
            cnpj_cpf_socio: 1,
            qualificacao_socio: 1,
            data_entrada_sociedade: 1,
            pais: 1,
            representante_legal: 1,
            nome_representante: 1,
            qualificacao_representante_legal: 1,
            faixa_etaria: 1
        }
    },
    {
        $out: "socios"
    }
]);

db.socios.createIndex({ cnpj: 1 }, { background: true });
db.socios.createIndex({ cnpj_basico: 1 }, { background: true });
db.socios.createIndex({ cnpj_cpf_socio: 1 }, { background: true });
db.socios.createIndex({ nome_socio: 1 }, { background: true });

db.simples.createIndex({ cnpj_basico: 1 }, { background: true });
'

# Execute the MongoDB operations
mongosh "$MONGODB_URI/$DATABASE_NAME" --eval "$MONGO_FINAL_OPERATIONS" || handleMongoError "FInal operations"

logDateTime "Finished!!!"
exit 0
