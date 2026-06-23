#!/usr/bin/env bash
# =============================================================================
# CHS0007 — Bioinformática | PPGSIS | UFC
# Aula 06 — Script de download dos dados e referência
# Dataset : Atacama Soil Microbiome (Neilson et al. 2017)
# Referência: SILVA 138 99% OTUs full-length (sklearn 1.4.2)
# Executar a partir de: ~/aula06_qiime/
# =============================================================================

# -----------------------------------------------------------------------------
# Criar estrutura de diretórios
# -----------------------------------------------------------------------------
mkdir -p 1_seqs
mkdir -p 2_demux
mkdir -p 3_ref_silva

# -----------------------------------------------------------------------------
# Metadados das amostras
# Colunas: sample-id, barcode-sequence, elevação, umidade, transecto...
# -----------------------------------------------------------------------------
wget \
  --output-document sample-metadata.tsv \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/sample_metadata.tsv"

# -----------------------------------------------------------------------------
# Reads multiplexadas — subset 10% do estudo original
# 3 arquivos: forward (R1), reverse (R2) e barcodes (índices)
# Todas as amostras misturadas — separação feita pelo demux
# -----------------------------------------------------------------------------
wget \
  --output-document 1_seqs/forward.fastq.gz \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/10p/forward.fastq.gz"

wget \
  --output-document 1_seqs/reverse.fastq.gz \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/10p/reverse.fastq.gz"

wget \
  --output-document 1_seqs/barcodes.fastq.gz \
  "https://data.qiime2.org/2024.10/tutorials/atacama-soils/10p/barcodes.fastq.gz"

# Verificar integridade dos 3 arquivos — devem ter o mesmo número de reads
echo "--- verificando integridade ---"
for f in forward reverse barcodes; do
  echo -n "1_seqs/${f}.fastq.gz: "
  gzip -t 1_seqs/${f}.fastq.gz && echo "OK" || echo "CORROMPIDO"
done

# Confirmar que os 3 arquivos têm o mesmo número de reads
echo "--- contando reads ---"
for f in forward reverse barcodes; do
  echo -n "1_seqs/${f}.fastq.gz: "
  zcat 1_seqs/${f}.fastq.gz | awk 'END{print NR/4, "reads"}'
done

# -----------------------------------------------------------------------------
# Classificador SILVA 138 full-length
# Naive Bayes pré-treinado | sklearn 1.4.2 | compatível com QIIME2 2024.10
# Nota: versão region-specific (515F/806R) não disponível na 2024.10
# -----------------------------------------------------------------------------
wget \
  --output-document 3_ref_silva/silva-138-99-nb-classifier.qza \
  "https://data.qiime2.org/classifiers/sklearn-1.4.2/silva/silva-138-99-nb-classifier.qza"

# Verificar integridade do classificador
echo "--- verificando classificador ---"
gzip -t 3_ref_silva/silva-138-99-nb-classifier.qza && echo "OK" || echo "CORROMPIDO"

# -----------------------------------------------------------------------------
# Verificar estrutura final
# -----------------------------------------------------------------------------
echo "--- estrutura de arquivos ---"
tree .

echo ""
echo "Download concluído. Próximo passo: aula06_espelho.sh"
