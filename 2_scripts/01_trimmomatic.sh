#!/usr/bin/env bash
# =============================================================================
# 3.scripts/01_trimmomatic.sh
# Disciplina: Bioinformática – PPGSIS / UFC 2026.1
#
# Roda Trimmomatic PE em TODAS as amostras da aula_03
# Salva o log de cada amostra em logs/
#
# Uso:
#   bash 3.scripts/01_trimmomatic.sh
# =============================================================================

set -euo pipefail

# ─── Configurações ────────────────────────────────────────────────────────────
DIR_IN="1.dados/brutos/aula_03"
DIR_OUT="2.resultados/trimmed"
DIR_LOGS="logs"
ADAPTERS="TruSeq3-PE.fa"   # arquivo de adaptadores do Trimmomatic
THREADS=4

# Parâmetros de trimagem
ILLUMINACLIP="${ADAPTERS}:2:30:10"
LEADING=3
TRAILING=3
SLIDINGWINDOW="4:20"
MINLEN=50

mkdir -p "$DIR_OUT" "$DIR_LOGS"

# ─── Encontrar amostras (baseado nos R1) ──────────────────────────────────────
AMOSTRAS=()
for r1 in "${DIR_IN}"/*_R1.fastq.gz; do
    nome=$(basename "$r1" _R1.fastq.gz)
    AMOSTRAS+=("$nome")
done

echo "════════════════════════════════════════════════════"
echo "  Trimmomatic PE – ${#AMOSTRAS[@]} amostras"
echo "  $(trimmomatic -version 2>&1 | head -1)"
echo "  Parâmetros: ILLUMINACLIP=${ILLUMINACLIP} LEADING=${LEADING}"
echo "              TRAILING=${TRAILING} SLIDINGWINDOW=${SLIDINGWINDOW}"
echo "              MINLEN=${MINLEN}"
echo "════════════════════════════════════════════════════"
echo ""

# ─── Loop por amostra ─────────────────────────────────────────────────────────
for AMOSTRA in "${AMOSTRAS[@]}"; do

    R1_IN="${DIR_IN}/${AMOSTRA}_R1.fastq.gz"
    R2_IN="${DIR_IN}/${AMOSTRA}_R2.fastq.gz"

    R1_PAIRED="${DIR_OUT}/${AMOSTRA}_R1.paired.fastq.gz"
    R1_UNPAIRED="${DIR_OUT}/${AMOSTRA}_R1.unpaired.fastq.gz"
    R2_PAIRED="${DIR_OUT}/${AMOSTRA}_R2.paired.fastq.gz"
    R2_UNPAIRED="${DIR_OUT}/${AMOSTRA}_R2.unpaired.fastq.gz"

    LOG="${DIR_LOGS}/${AMOSTRA}_trimmomatic.log"

    echo "▶ ${AMOSTRA}"

    # Verificar se R2 existe
    if [[ ! -f "$R2_IN" ]]; then
        echo "  [AVISO] R2 não encontrado para ${AMOSTRA} – pulando"
        continue
    fi

    # Rodar Trimmomatic – stderr vai para o log
    trimmomatic PE \
        -threads "$THREADS" \
        "$R1_IN" "$R2_IN" \
        "$R1_PAIRED" "$R1_UNPAIRED" \
        "$R2_PAIRED" "$R2_UNPAIRED" \
        ILLUMINACLIP:"$ILLUMINACLIP" \
        LEADING:"$LEADING" \
        TRAILING:"$TRAILING" \
        SLIDINGWINDOW:"$SLIDINGWINDOW" \
        MINLEN:"$MINLEN" \
        2> "$LOG"

    # Extrair resumo do log e mostrar na tela
    SURVIVING=$(grep "Both Surviving" "$LOG" | awk '{print $3, $4}')
    DROPPED=$(grep "Dropped" "$LOG" | awk '{print $2, $3}')
    echo "  Both Surviving: ${SURVIVING}"
    echo "  Dropped:        ${DROPPED}"
    echo "  Log salvo em:   ${LOG}"
    echo ""

done

# ─── Resumo final ─────────────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════"
echo "  RESUMO – Both Surviving por amostra"
echo "════════════════════════════════════════════════════"

printf "%-30s %s\n" "Amostra" "Both Surviving"
printf "%-30s %s\n" "──────────────────────────────" "──────────────"

for AMOSTRA in "${AMOSTRAS[@]}"; do
    LOG="${DIR_LOGS}/${AMOSTRA}_trimmomatic.log"
    if [[ -f "$LOG" ]]; then
        SURV=$(grep "Both Surviving" "$LOG" | awk '{print $3, $4}')
        printf "%-30s %s\n" "$AMOSTRA" "$SURV"
    fi
done

echo ""
echo "Arquivos trimados em: ${DIR_OUT}/"
echo "Logs salvos em:       ${DIR_LOGS}/"
echo ""
echo "Próximo passo:"
echo "  fastqc ${DIR_OUT}/*.paired.fastq.gz -o 2.resultados/qc/pos/ -t 4"
