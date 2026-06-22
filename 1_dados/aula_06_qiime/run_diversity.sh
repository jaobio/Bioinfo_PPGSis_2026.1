#!/usr/bin/env bash
# =============================================================================
# CHS0007 — Bioinformática | PPGSIS | UFC
# Aula 06 — Script auxiliar: filogenia + diversidade alfa e beta
# Executar a partir de ~/aula06 com o ambiente qiime2-2024.10 ativo
# Pré-requisito: table.qza e rep-seqs.qza gerados pelo run_dada2.sh
# =============================================================================

# -----------------------------------------------------------------------------
# PARTE 1 — Árvore filogenética das ASVs
# Necessária para métricas que consideram distância evolutiva:
#   Faith's PD (alfa), UniFrac ponderado e não-ponderado (beta)
# -----------------------------------------------------------------------------

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences       rep-seqs.qza \
  --o-alignment       aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree            unrooted-tree.qza \
  --o-rooted-tree     rooted-tree.qza \
  --p-n-threads       2
# --i-sequences        : sequências representativas das ASVs
# --o-alignment        : alinhamento múltiplo com MAFFT
# --o-masked-alignment : alinhamento filtrado (remove posições hipervariáveis)
# --o-tree             : árvore filogenética não-enraizada (FastTree)
# --o-rooted-tree      : árvore enraizada pelo ponto médio (necessária para UniFrac)
# --p-n-threads        : núcleos paralelos para o MAFFT

# -----------------------------------------------------------------------------
# PARTE 2 — Core metrics (alfa + beta diversidade)
# Rarefação: padronizar todas as amostras para o mesmo número de reads
# Definir --p-sampling-depth com base no table.qzv (menor valor que
# preserve o máximo de amostras — verificar histograma em view.qiime2.org)
# -----------------------------------------------------------------------------

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny       rooted-tree.qza \
  --i-table           table.qza \
  --p-sampling-depth  100 \
  --m-metadata-file   sample-metadata.tsv \
  --output-dir        core-metrics-results
# --i-phylogeny       : árvore enraizada (para métricas filogenéticas)
# --i-table           : tabela ASV × amostra
# --p-sampling-depth  : profundidade de rarefação (amostras com menos reads
#                       são descartadas; ajustar após ver table.qzv)
# --m-metadata-file   : metadados para colorir amostras nas visualizações
# --output-dir        : diretório com todos os artefatos de diversidade
#
# Artefatos gerados automaticamente:
#   Alfa: observed_features, shannon, faith_pd, pielou_evenness
#   Beta: bray_curtis, jaccard, unweighted_unifrac, weighted_unifrac
#         + PCoA emperor (.qzv) para cada métrica beta

# -----------------------------------------------------------------------------
# PARTE 3 — Testes estatísticos de diversidade alfa
# -----------------------------------------------------------------------------

# Faith's Phylogenetic Diversity por transecto
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file   sample-metadata.tsv \
  --o-visualization   core-metrics-results/faith-pd-significance.qzv
# --i-alpha-diversity : vetor de diversidade alfa por amostra
# --m-metadata-file   : metadados com as variáveis categóricas para teste
# --o-visualization   : boxplots + teste Kruskal-Wallis por variável categórica

# Equitabilidade de Pielou por transecto
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file   sample-metadata.tsv \
  --o-visualization   core-metrics-results/evenness-significance.qzv

# -----------------------------------------------------------------------------
# PARTE 4 — Testes estatísticos de diversidade beta
# -----------------------------------------------------------------------------

# UniFrac não-ponderado: diferença de composição entre transectos
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file   sample-metadata.tsv \
  --m-metadata-column transect-name \
  --p-pairwise \
  --o-visualization   core-metrics-results/unweighted-unifrac-significance.qzv
# --i-distance-matrix  : matriz de distâncias beta entre amostras
# --m-metadata-column  : coluna categórica para agrupar amostras no teste
# --p-pairwise         : realizar testes pareados entre todos os grupos
# --o-visualization    : boxplots de distâncias intra/inter-grupo + PERMANOVA

# Bray-Curtis: diferença de abundância entre transectos
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
  --m-metadata-file   sample-metadata.tsv \
  --m-metadata-column transect-name \
  --p-pairwise \
  --o-visualization   core-metrics-results/bray-curtis-significance.qzv

# -----------------------------------------------------------------------------
# Listar todos os arquivos de visualização gerados
# -----------------------------------------------------------------------------

echo ""
echo "Arquivos .qzv gerados — abrir em view.qiime2.org:"
ls -lh core-metrics-results/*.qzv
