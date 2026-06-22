#!/usr/bin/env bash
# Criando Variaveis
SP="SRR13510367"
R1="seqs/${SP}_1.fastq.gz"
R2="seqs/${SP}_2.fastq.gz"
R1_paired="2.limpos/${SP}_R1_paired.fastq.gz"
R1_unpaired="2.limpos/${SP}_R1_unpaired.fastq.gz"
R2_paired="2.limpos/${SP}_R2_paired.fastq.gz"
R2_unpaired="2.limpos/${SP}_R2_unpaired.fastq.gz"
ls 2.
# Rodando o Trimmomatic
# Arquivos FASTQ - Origem: "$R1" "$R2"
# Onde vai salvar os arquivos R1: "$R1_paired" "$R1_unpaired"
# Onde vai salvar os arquivos R2: "$R2_paired" "$R2_unpaired"
# Menores valores ILLUMINACLIP, mais restrito mas pode perder bases
trimmomatic PE \
    "$R1" "$R2" \
    "$R1_paired" "$R1_unpaired" \
    "$R2_paired" "$R2_unpaired" \
    ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:20 \
    MINLEN:100
