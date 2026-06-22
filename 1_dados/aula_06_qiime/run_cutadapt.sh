#!/usr/bin/env bash
# =============================================================================
# CHS0007 — Bioinformática | PPGSIS | UFC
# Aula 06 — Script auxiliar: remoção de primers com Cutadapt
# Executar a partir de ~/aula06 com o ambiente qiime2-2024.10 ativo
# =============================================================================

# Primers EMP versão original (Caporaso), reverse-barcoded:
#   515F: GTGCCAGCMGCCGCGGTAA   (forward)
#   806R: GGACTACHVGGGTWTCTAAT  (reverse)
# Letras IUPAC: M=A/C  H=A/C/T  V=A/C/G  W=A/T  Y=C/T  N=qualquer base

qiime cutadapt trim-paired \
  --i-demultiplexed-sequences demux.qza \
  --p-front-f GTGCCAGCMGCCGCGGTAA \
  --p-front-r GGACTACHVGGGTWTCTAAT \
  --p-cores 2 \
  --o-trimmed-sequences demux-trimmed.qza \
  --verbose
# --i-demultiplexed-sequences : reads já separadas por amostra (pós-demux)
# --p-front-f                 : sequência do primer forward a remover no R1
# --p-front-r                 : sequência do primer reverse a remover no R2
# --p-discard-untrimmed       : descartar reads onde o primer não foi encontrado
#                               (evita contaminar a análise com reads fora do alvo)
# --p-cores                   : número de núcleos paralelos
# --o-trimmed-sequences       : reads sem primers (artefato de saída)
# --verbose                   : mostrar estatísticas de remoção por amostra

echo "Cutadapt concluído — artefato gerado: demux-trimmed.qza"
