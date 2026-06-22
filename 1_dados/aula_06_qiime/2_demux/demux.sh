#!/usr/bin/env bash

qiime demux emp-paired \
  --i-seqs               seqs.qza \
  --m-barcodes-file      sample-metadata.tsv \
  --m-barcodes-column    barcode-sequence \
  --p-rev-comp-mapping-barcodes \
  --o-per-sample-sequences demux-full.qza \
  --o-error-correction-details demux-details.qza
# --i-seqs                      : artefato com as reads multiplexadas
# --m-barcodes-file             : arquivo de metadados com os barcodes por amostra
# --m-barcodes-column           : coluna do TSV que contém as sequências de barcode
# --p-rev-comp-mapping-barcodes : os barcodes no arquivo estão no complemento reverso
#                                 em relação ao arquivo de metadados (padrão EMP)
# --o-per-sample-sequences      : reads separadas por amostra (artefato principal)
# --o-error-correction-details  : estatísticas de correção de erro de barcode
