# =============================================================================
# espelho_aula03_qc_trimmomatic.sh
# Disciplina: Bioinformática – PPGSIS / UFC 2026.1
# Aula 3: QC · Pré-processamento de reads
#
# COMO USAR:
#   Execute este script LINHA A LINHA no terminal (não rode tudo de uma vez)
#   Siga a ordem dos comentários que acompanham os slides
#
# Dados: 4 espécies da biodiversidade brasileira (FASTQs sintéticos realistas)
#   • Arapaima gigas        → boa qualidade (referência)
#   • Bothrops jararaca     → adaptadores ~15%, queda de Q no 3'
#   • Manacus manacus       → R2 com queda severa no meio do read
#   • Podocnemis expansa    → baixa qualidade geral, muitos adaptadores
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# SLIDE 3 – Atualizar o fork antes de começar
# ─────────────────────────────────────────────────────────────────────────────

git remote -v

git fetch upstream
git checkout main
git rebase upstream/main
git push origin main --force

# ─────────────────────────────────────────────────────────────────────────────
# PREPARAÇÃO DO AMBIENTE
# ─────────────────────────────────────────────────────────────────────────────

# Estrutura de diretórios desta aula
mkdir -p 1.dados/1.brutos/aula_03
mkdir -p 1.dados/qc/pre_qc
mkdir -p 1.dados/qc/pos_qc
mkdir -p 1.dados/multiqc/pre
mkdir -p 1.dados/multiqc/pos
mkdir -p 2.limpos/trimmed

# Conferir os dados
ls -lh 1.dados/1.brutos/aula_03/

# ─────────────────────────────────────────────────────────────────────────────
# SLIDE 6 – Revisão do formato FASTQ
# ─────────────────────────────────────────────────────────────────────────────

# Ver as 8 primeiras linhas (= 2 reads completos)
zcat 1.dados/1.brutos/aula_03/Arapaima_gigas_R1.fastq.gz | head -8

# Linha 1: header @  |  Linha 2: sequência  |  Linha 3: +  |  Linha 4: qualidade
# Contar reads: cada read ocupa exatamente 4 linhas
zcat 1.dados/1.brutos/aula_03/Arapaima_gigas_R1.fastq.gz | wc -l

# Dividir por 4 para obter o número de reads
echo $(( $(zcat 1.dados/1.brutos/aula_03/Arapaima_gigas_R1.fastq.gz | wc -l) / 4 )) reads

# Inspecionar só as qualidades (linha 4 de cada read)
zcat 1.dados/1.brutos/aula_03/Arapaima_gigas_R1.fastq.gz | awk 'NR%4==0' | head -3

# Comparar qualidade Arapaima (boa) vs Bothrops (degradada)
echo "--- Arapaima (Q35+) ---"
zcat 1.dados/1.brutos/aula_03/Arapaima_gigas_R1.fastq.gz | awk 'NR%4==0' | head -2
echo "--- Bothrops (queda 3') ---"
zcat 1.dados/1.brutos/aula_03/Bothrops_jararaca_R1.fastq.gz | awk 'NR%4==0' | head -2

# Verificar adaptador Illumina na Bothrops
zcat 1.brutos/aula_03/Bothrops_jararaca_R1.fastq.gz \
    | awk 'NR%4==2' \
    | grep -c "AGATCGGAAGAG"

# ─────────────────────────────────────────────────────────────────────────────
# MÓDULO 1 – SLIDES 7-8  →  FastQC em uma amostra
# ─────────────────────────────────────────────────────────────────────────────

# ── PRIMEIRO UM ARQUIVO, depois automamos para todos ──

# Rodar FastQC só no Arapaima R1 para ver o relatório
fastqc \
    1.dados/1.brutos/aula_03/Arapaima_gigas_R1.fastq.gz \
    -o 2.resultados/qc/pre/

# Ver o que foi gerado
ls -lh 2.resultados/qc/pre/

# O .html é o relatório visual → abrir no browser
# O .zip contém os dados 1.brutos → MultiQC vai ler esse

# ─────────────────────────────────────────────────────────────────────────────
# SLIDE 8 – FastQC em TODOS os arquivos (automatizado)
# ─────────────────────────────────────────────────────────────────────────────

fastqc \
    1.dados/1.brutos/aula_03/*.fastq.gz \
    -o 2.resultados/qc/pre/ \
    -t 4

ls -lh 2.resultados/qc/pre/

# ─────────────────────────────────────────────────────────────────────────────
# SLIDES 9-11 – MultiQC: agregar todos os relatórios
# ─────────────────────────────────────────────────────────────────────────────

multiqc \
    2.resultados/qc/pre/ \
    -o 2.resultados/multiqc/pre/ \
    --title 'Aula 03 - Pré-processamento (antes)'

ls -lh 2.resultados/multiqc/pre/

# ─────────────────────────────────────────────────────────────────────────────
# MÓDULO 2 – SLIDES 13-15  →  Trimmomatic
# ─────────────────────────────────────────────────────────────────────────────

# ── PRIMEIRO UM ARQUIVO: Arapaima gigas ──

# Variáveis para facilitar a leitura do comando
AMOSTRA="Arapaima_gigas"
R1_IN="1.dados/1.brutos/aula_03/${AMOSTRA}_R1.fastq.gz"
R2_IN="1.dados/1.brutos/aula_03/${AMOSTRA}_R2.fastq.gz"
R1_PAIRED="2.resultados/trimmed/${AMOSTRA}_R1.paired.fastq.gz"
R1_UNPAIRED="2.resultados/trimmed/${AMOSTRA}_R1.unpaired.fastq.gz"
R2_PAIRED="2.resultados/trimmed/${AMOSTRA}_R2.paired.fastq.gz"
R2_UNPAIRED="2.resultados/trimmed/${AMOSTRA}_R2.unpaired.fastq.gz"

# Rodar Trimmomatic – salvar o log com 2>
trimmomatic PE \
    -threads 4 \
    "$R1_IN" "$R2_IN" \
    "$R1_PAIRED" "$R1_UNPAIRED" \
    "$R2_PAIRED" "$R2_UNPAIRED" \
    ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:20 \
    MINLEN:50 \
    2> logs/${AMOSTRA}_trimmomatic.log

# ── Ler o log ──
cat logs/${AMOSTRA}_trimmomatic.log

# Interpretar as linhas chave:
# Input Read Pairs: 5000
# Both Surviving: XXXX (XX%) → pares que ficaram ← o que importa
# Forward Only:   XXXX (XX%) → reads orphan R1
# Reverse Only:   XXXX (XX%) → reads orphan R2
# Dropped:        XXXX (XX%) → descartados

# Conferir os arquivos de saída (4 arquivos por amostra)
ls -lh 2.resultados/trimmed/

# ─────────────────────────────────────────────────────────────────────────────
# SLIDE 18 – Trade-off: experimentar parâmetros diferentes
# ─────────────────────────────────────────────────────────────────────────────

# Versão MAIS RESTRITIVA (mais limpeza, menos reads)
trimmomatic PE \
    -threads 4 \
    "$R1_IN" "$R2_IN" \
    2.resultados/trimmed/${AMOSTRA}_R1.paired.restritivo.fastq.gz \
    2.resultados/trimmed/${AMOSTRA}_R1.unpaired.restritivo.fastq.gz \
    2.resultados/trimmed/${AMOSTRA}_R2.paired.restritivo.fastq.gz \
    2.resultados/trimmed/${AMOSTRA}_R2.unpaired.restritivo.fastq.gz \
    ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
    LEADING:5 \
    TRAILING:5 \
    SLIDINGWINDOW:4:25 \
    MINLEN:75 \
    2> logs/${AMOSTRA}_trimmomatic_restritivo.log

# Comparar os dois logs
echo "=== PADRÃO ==="
grep "Input\|Surviving\|Dropped" logs/${AMOSTRA}_trimmomatic.log

echo "=== RESTRITIVO ==="
grep "Input\|Surviving\|Dropped" logs/${AMOSTRA}_trimmomatic_restritivo.log

# ─────────────────────────────────────────────────────────────────────────────
# AUTOMATIZAR PARA TODAS AS AMOSTRAS  →  script.sh
# ─────────────────────────────────────────────────────────────────────────────

# Substituir o loop manual pelo script dedicado:
bash 3.scripts/01_trimmomatic.sh

# ─────────────────────────────────────────────────────────────────────────────
# FastQC PÓS-TRIMAGEM e comparação com MultiQC
# ─────────────────────────────────────────────────────────────────────────────

fastqc \
    2.resultados/trimmed/*.paired.fastq.gz \
    -o 2.resultados/qc/pos/ \
    -t 4

# MultiQC comparando ANTES e DEPOIS lado a lado
multiqc \
    2.resultados/qc/pre/ \
    2.resultados/qc/pos/ \
    -o 2.resultados/multiqc/ \
    --title 'Aula 03 - Antes vs Depois da Trimagem'

# O que deve melhorar no relatório pós-trimagem?
# ✓ Adapter content → zerado ou próximo de zero
# ✓ Per base quality nas extremidades → curva mais estável
# ✓ Sequence length distribution → variável (normal: reads com tamanhos diferentes)

# ─────────────────────────────────────────────────────────────────────────────
# SLIDE 18 – Boas práticas: registrar versão e salvar o comando
# ─────────────────────────────────────────────────────────────────────────────

trimmomatic -version

# O log já foi salvo em logs/ automaticamente pelo script
ls -lh logs/

# ─────────────────────────────────────────────────────────────────────────────
# GIT – Commit da análise
# ─────────────────────────────────────────────────────────────────────────────

git add 3.scripts/01_trimmomatic.sh
git add logs/
git status

git commit -m "feat(aula03): adiciona script Trimmomatic e logs de QC"
git push origin main
