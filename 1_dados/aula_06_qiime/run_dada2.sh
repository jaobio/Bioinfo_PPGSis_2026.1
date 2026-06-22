#!/usr/bin/env bash
# =============================================================================
# CHS0007 — Bioinformática | PPGSIS | UFC
# Aula 06 — Script auxiliar: denoising com DADA2
# Executar a partir de ~/aula06 com o ambiente qiime2-2024.10 ativo
# Tempo estimado: 8–10 min com 2 cores (Codespace)
# =============================================================================

# Parâmetros de truncagem baseados na inspeção do demux-trimmed.qzv:
#   --p-trunc-len-f 150 : truncar R1 na posição 150 (qualidade estável até aqui)
#   --p-trunc-len-r 150 : truncar R2 na posição 150
#
# Verificar overlap após truncagem:
#   Amplicon V4 ~ 253 bp → 150 + 150 = 300 → overlap ~ 47 bp ✓ (mínimo: 20 bp)
#
# Se a qualidade do R2 cair antes de 150, reduzir --p-trunc-len-r
# mas garantir sempre: trunc-f + trunc-r > tamanho_amplicon + 20

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs  demux-trimmed.qza \
  --p-trim-left-f         0 \
  --p-trim-left-r         0 \
  --p-trunc-len-f         150 \
  --p-trunc-len-r         140 \
  --p-chimera-method      consensus \
  --p-n-threads           2 \
  --o-table               table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats     denoising-stats.qza
# --i-demultiplexed-seqs  : reads sem primers (saída do Cutadapt)
# --p-trim-left-f         : bases a remover do início do R1 (0 = não remover)
# --p-trim-left-r         : bases a remover do início do R2 (0 = não remover)
# --p-trunc-len-f         : comprimento final do R1 após truncagem
# --p-trunc-len-r         : comprimento final do R2 após truncagem
#                           reads menores que esse valor são descartadas
# --p-chimera-method      : método de remoção de quimeras
#                           consensus = detecta quimeras por consenso entre amostras
#                           pooled    = mais sensível, mais lento
#                           none      = sem remoção (apenas para diagnóstico)
# --p-n-threads           : núcleos paralelos (0 = usar todos disponíveis)
# --o-table               : tabela de frequência ASV × amostra
# --o-representative-sequences: sequência consenso de cada ASV
# --o-denoising-stats     : estatísticas por amostra em cada etapa do pipeline

echo "DADA2 concluído."
echo "Artefatos gerados:"
echo "  table.qza            — tabela ASV × amostra"
echo "  rep-seqs.qza         — sequências representativas das ASVs"
echo "  denoising-stats.qza  — estatísticas de filtragem e remoção de quimeras"
