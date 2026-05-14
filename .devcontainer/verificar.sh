#!/usr/bin/env bash
source /home/vscode/miniforge3/etc/profile.d/conda.sh 2>/dev/null
conda activate bioinfo 2>/dev/null

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
PASS=0; FAIL=0

check() {
    local name="$1"; local cmd="$2"; local ver_cmd="$3"
    if command -v "$cmd" &>/dev/null; then
        local ver; ver=$(eval "$ver_cmd" 2>&1 | head -1)
        echo -e "  ${GREEN}✔${RESET} ${name} — ${ver}"
        ((PASS++))
    else
        echo -e "  ${RED}✘${RESET} ${name} — NÃO ENCONTRADO"
        ((FAIL++))
    fi
}

check_r() {
    local pkg="$1"
    if Rscript -e "library($pkg)" &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✔${RESET} R::${pkg}"
        ((PASS++))
    else
        echo -e "  ${RED}✘${RESET} R::${pkg} — não instalado"
        ((FAIL++))
    fi
}

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Verificação do ambiente — Bioinformática 2026 ${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo ""

echo -e "${BOLD}── Módulo 1/2: Utilitários e QC ───────────────${RESET}"
check "seqkit"      "seqkit"      "seqkit version"
check "FastQC"      "fastqc"      "fastqc --version"
check "MultiQC"     "multiqc"     "multiqc --version"
check "fastp"       "fastp"       "fastp --version"
check "Trimmomatic" "trimmomatic" "trimmomatic -version"

echo ""
echo -e "${BOLD}── Módulo 2/3: Simulação e montagem ───────────${RESET}"
check "InSilicoSeq" "iss"         "iss --version"
check "SPAdes"      "spades.py"   "spades.py --version"
check "QUAST"       "quast.py"    "quast.py --version"
check "BUSCO"       "busco"       "busco --version"
check "Prokka"      "prokka"      "prokka --version"

echo ""
echo -e "${BOLD}── Módulo 3/5: Alinhamento ─────────────────────${RESET}"
check "BWA-MEM2"    "bwa-mem2"    "bwa-mem2 version"
check "Bowtie2"     "bowtie2"     "bowtie2 --version | head -1"
check "samtools"    "samtools"    "samtools version | head -1"
check "bcftools"    "bcftools"    "bcftools --version | head -1"

echo ""
echo -e "${BOLD}── Módulo 5: SNP Calling ───────────────────────${RESET}"
check "Stacks"      "denovo_map.pl" "denovo_map.pl 2>&1 | grep -i version | head -1"
check "VCFtools"    "vcftools"    "vcftools --version"
check "fasterq-dump" "fasterq-dump" "fasterq-dump --version"

echo ""
echo -e "${BOLD}── R e pacotes ─────────────────────────────────${RESET}"
check "R" "Rscript" "Rscript --version"
check_r "tidyverse"
check_r "ggplot2"
check_r "vegan"
check_r "phyloseq"
check_r "adegenet"
check_r "poppr"
check_r "ape"

echo ""
echo -e "${BOLD}── QIIME2 (Módulo 4 — instalar na semana 2) ───${RESET}"
if conda env list | grep -q "qiime2-amplicon"; then
    echo -e "  ${GREEN}✔${RESET} Ambiente 'qiime2-amplicon' presente"
    ((PASS++))
else
    echo -e "  ${YELLOW}⚠${RESET}  'qiime2-amplicon' não instalado — necessário apenas no Módulo 4"
fi

echo ""
echo -e "${BOLD}── Git e GitHub ────────────────────────────────${RESET}"
check "git" "git" "git --version"
check "gh"  "gh"  "gh --version | head -1"

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "  Resultado: ${GREEN}${PASS} OK${RESET} / ${RED}${FAIL} falhas${RESET}"
if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ Tudo pronto! Pode começar.${RESET}"
else
    echo -e "  ${YELLOW}⚠  Verifique as falhas acima${RESET}"
fi
echo ""
