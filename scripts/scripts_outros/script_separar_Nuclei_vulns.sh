#!/bin/bash
# set -x
# Diretório de saída para os arquivos filtrados
SCAN_DIR=$1

OUTPUT_DIR="$SCAN_DIR/filtered_results_nuclei"
CVE_DIR="/$OUTPUT_DIR/cve"
SEVERITY_DIR="/$OUTPUT_DIR/por_severidade"
NAME_TEMPLATE_DIR="$OUTPUT_DIR/por_nome_templates"
ARQUIVO_NUCLEI_COMBINED="$SCAN_DIR/nuclei_vulns_combined.txt"

# Crie os diretórios se eles não existirem
mkdir -p "$OUTPUT_DIR"
mkdir -p "$CVE_DIR"
mkdir -p "$SEVERITY_DIR"
mkdir -p "$NAME_TEMPLATE_DIR"

# Função para filtrar por severidade
filter_by_severity() {
    local severity="$1"
    egrep -a "\[$severity\]" $ARQUIVO_NUCLEI_COMBINED > "$SEVERITY_DIR/$severity.txt"
    # Criar diretório de severidade dentro de CVE_DIR
    mkdir -p "$CVE_DIR/$severity"
}

# # Função para filtrar por severidade
# filter_by_template() {
#     local template="$1"
#     egrep -a "\[$template\]" $ARQUIVO_NUCLEI_COMBINED > "$OUTPUT_DIR/$NAMETEMPLATE_DIR/$template.txt"
# }

# Filtrar por severidades
filter_by_severity "critical"
filter_by_severity "high"
filter_by_severity "medium"
filter_by_severity "low"
filter_by_severity "unknown"
# Adicione mais chamadas para outras severidades conforme necessário

# filter_by_template "credentials-disclosure"
# filter_by_template "generic-tokens"
# filter_by_template "wordpress-seo-version"

# Filtrar por nome do template e criar arquivos separados para cada nome
egrep -oa '^\[([a-zA-Z0-9_-]+)\]' $ARQUIVO_NUCLEI_COMBINED | sort | uniq | while read -r template; do
    # Remover colchetes do nome do template
    template_name=$(echo "$template" | tr -d '[]')
    # Salvar as entradas correspondentes no arquivo dentro do diretório do nome do template
    egrep -a "$template_name" $ARQUIVO_NUCLEI_COMBINED > "$NAME_TEMPLATE_DIR/$template_name.txt"
done

# Filtrar por CVEs e criar arquivos separados para cada CVE
egrep -oa 'CVE-[0-9]{4}-[0-9]+' $ARQUIVO_NUCLEI_COMBINED | sort | uniq | while read -r cve; do
    # Pegar a severidade da linha atual do CVE
    severity=$(egrep -a "$cve" $ARQUIVO_NUCLEI_COMBINED | egrep -o '\[(low|medium|high|critical|unknown)\]' | head -1 | tr -d '[]')
    # Salvar o arquivo CVE no diretório de severidade correspondente
    egrep -a "$cve" $ARQUIVO_NUCLEI_COMBINED > "$CVE_DIR/$severity/$cve.txt"
done

# Criar um resumo em Markdown
SUMMARY_FILE="$OUTPUT_DIR/summary.md"

echo "# Resumo de Severidades" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Listar o número de entradas para cada severidade
for severity in critical high medium low unknown; do
    count=$(wc -l < "$SEVERITY_DIR/$severity.txt")
    echo "- **$severity**: $count entradas ([ver detalhes](./$severity.txt))" >> "$SUMMARY_FILE"
done

echo "" >> "$SUMMARY_FILE"
echo "# Resumo de CVEs" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Listar o número de entradas para cada CVE
total_cves=0
for cve_file in "$CVE_DIR"/*/*.txt; do
    cve=$(basename "$cve_file" .txt)
    count=$(wc -l < "$cve_file")
    severity=$(basename $(dirname "$cve_file"))
    echo "- **$cve** ($severity): $count entradas ([ver detalhes](./cve/$severity/$cve.txt))" >> "$SUMMARY_FILE"
    total_cves=$((total_cves + 1))
done

echo "" >> "$SUMMARY_FILE"
echo "Total de CVEs únicos: $total_cves" >> "$SUMMARY_FILE"
