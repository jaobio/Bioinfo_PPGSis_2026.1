# =============================================================================
# ESPELHO — AULA 05: Anotação e Visualização do Genoma Montado
# CHS0007 Bioinformática · PPGSIS/UFC · Junho 2026
# Dr. Yan Torres
#
# USO: Este arquivo é um GUIA DE AULA, não um script executável.
#      Execute cada bloco manualmente no terminal junto com os alunos.
#      Os comentários são as explicações que você fala em voz alta.
#
# PRÉ-REQUISITO: Aula 04 concluída.
#      2.resultados/aula_04/spades/contigs.fasta deve existir.
# =============================================================================


# =============================================================================
# PARTE 0 — Sincronizar o repositório com o do professor
# =============================================================================

# Garantir que estamos no branch principal
git checkout main

# Buscar as atualizações do repositório do professor
git fetch upstream

# Resetar o main local para ficar idêntico ao do professor
git reset --hard upstream/main

# Publicar no fork pessoal no GitHub
git push origin main --force-with-lease


# =============================================================================
# PARTE 1 — Preparação do ambiente
# =============================================================================

# Confirmar que estamos na raiz do repositório
pwd

# Confirmar que os contigs da Aula 04 estão presentes
ls -lh 2.resultados/aula_04/spades/contigs.fasta

# Criar os diretórios de hoje — na ordem em que vamos usá-los
mkdir -p 3.seqkit/        # passo 2 — filtrar contig principal
mkdir -p 1.genome_ref/    # passo 3 — download da referência NC_045512.2
mkdir -p 3.prokka/        # passo 4 — anotação com Prokka
mkdir -p 4.minimap/       # passo 5 — alinhamento com minimap2
mkdir -p 3.igv/           # passo 6 — screenshots do IGV
mkdir -p 5.quast_com_ref/ # passo 8 — QUAST com referência


# =============================================================================
# PARTE 2 — Inspecionar e filtrar o contig principal
# =============================================================================

# Verificar versão do seqkit
seqkit version

# Listar todos os contigs: nome, comprimento e cobertura
# O SPAdes codifica tudo no cabeçalho: NODE_X_length_Y_cov_Z
seqkit seq --name 2.resultados/aula_04/spades/contigs.fasta

# Quantos contigs temos no total?
seqkit stats 2.resultados/aula_04/spades/contigs.fasta

# O maior contig (~29 kb) é o genoma do SARS-CoV-2.
# Os demais são fragmentos curtos de ruído ou contaminação.
# Vamos isolar apenas o contig principal para a análise.

# Ordenar do maior para o menor e extrair somente o primeiro
# -l = ordenar por comprimento; -r = ordem reversa (descendente)
seqkit sort -l -r \
    2.resultados/aula_04/spades/contigs.fasta \
    | seqkit head -n 1 \
    > 3.seqkit/sars_contig.fasta

# Confirmar: deve ter exatamente 1 sequência, ~29 kb
seqkit stats 3.seqkit/sars_contig.fasta

# Ver o cabeçalho do contig que ficou
grep ">" 3.seqkit/sars_contig.fasta

# seqkit replace substitui o cabeçalho longo gerado pelo SPAdes por um nome limpo.
# O seqkit entende o formato FASTA e opera APENAS no cabeçalho — a sequência não é tocada.
# --pattern ".+"  → expressão regular que casa com qualquer texto (o cabeçalho inteiro)
# --replacement   → o texto que vai substituir: nome do vírus + accession + origem
seqkit replace \
    --pattern ".+" \
    --replacement "SARS-CoV-2_SRR13510367_montado" \
    3.seqkit/sars_contig.fasta \
    > 3.seqkit/sars_contig_clean.fasta

# Confirmar que o cabeçalho mudou
grep ">" 3.seqkit/sars_contig_clean.fasta

# Reverter o contig para a orientação correta em relação à referência.
# O SPAdes pode montar o contig na orientação reversa complementar.
# Diagnóstico: se o Prokka anotar tudo em complement(), o contig está invertido.
# -t dna → especifica que o arquivo contém DNA (T em vez de U) — necessário para o complemento
# --reverse --complement → inverte a sequência e aplica o complemento de cada base
seqkit seq \
    -t dna \
    --reverse --complement \
    3.seqkit/sars_contig_clean.fasta \
    > 3.seqkit/sars_contig_rc.fasta

# Confirmar que o arquivo não está vazio e o cabeçalho foi preservado
seqkit stats 3.seqkit/sars_contig_rc.fasta
grep ">" 3.seqkit/sars_contig_rc.fasta


# =============================================================================
# PARTE 3 — Baixar o genoma de referência NC_045512.2 (Wuhan-Hu-1)
# =============================================================================

# NC_045512.2 é a sequência de referência canônica do SARS-CoV-2
# Depositada pelo grupo de Wuhan em janeiro de 2020
# Tamanho: 29.903 bp · GC: 37,97%

# Baixar a referência em formato FASTA do NCBI
# -o → nome do arquivo de saída
# rettype=fasta → formato FASTA
# retmode=text  → texto simples (não XML)
curl -o 1.genome_ref/ref_NC_045512.2.fasta \
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_045512.2&rettype=fasta&retmode=text"

# Confirmar o download: tamanho esperado ~29.903 bp
seqkit stats 1.genome_ref/ref_NC_045512.2.fasta

# Ver as primeiras linhas: cabeçalho e início da sequência
head -3 1.genome_ref/ref_NC_045512.2.fasta

# Baixar as proteínas da referência para guiar a anotação com Prokka
# rettype=fasta_cds_aa → proteínas codificadas em FASTA de aminoácidos
# O NCBI entrega cabeçalhos longos com colchetes — precisamos converter
# para o formato gene~~~product que o Prokka entende como banco de âncora
curl -o 1.genome_ref/ref_NC_045512.2_proteinas.faa \
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_045512.2&rettype=fasta_cds_aa&retmode=text"



# Confirmar que o formato ficou correto
grep ">" 1.genome_ref/ref_NC_045512.2_proteinas_prokka.faa | head -5
# Esperado:


# Quantas proteínas tem o genoma de referência?
grep -c ">" 1.genome_ref/ref_NC_045512.2_proteinas_prokka.faa


# =============================================================================
# PARTE 4 — Anotação funcional com Prokka
# =============================================================================

# Verificar versão do Prokka
prokka --version

# O Prokka é um anotador automático de genomas procarióticos —
# mas com a flag --kingdom Viruses ele funciona bem para vírus pequenos.
# A chave pedagógica: anotação = dar FUNÇÃO a cada região do genoma.
# Sem anotação, temos apenas letras. Com anotação, temos genes, proteínas, ORFs.

# Rodar o Prokka no contig na orientação correta
# --kingdom Viruses  → ajusta o banco de dados interno para vírus
# --proteins         → usa as proteínas da referência NC_045512.2 como âncora principal
#                      o Prokka faz blastp dos CDS preditos contra esse banco antes
#                      de consultar o banco interno — aumenta a especificidade
# --prefix           → nome base de todos os arquivos de saída
# --outdir           → pasta de saída
# --force            → sobrescrever se rodar mais de uma vez
# --cpus 2           → número de núcleos disponíveis no Codespace
prokka \
    3.seqkit/sars_contig_rc.fasta \
    --kingdom Viruses \
    --proteins 1.genome_ref/ref_NC_045512.2_proteinas_prokka.faa \
    --prefix sars_anotado \
    --outdir 3.prokka/ \
    --force \
    --cpus 2

# Listar os arquivos gerados pelo Prokka
ls -lh 3.prokka/

# Prokka gera vários formatos — cada um serve para uma finalidade:
#   .gff  → anotação em formato tabular (usado pelo IGV e R)
#   .gbk  → GenBank — formato rico com sequência + anotação (usado pelo Proksee e CGView)
#   .faa  → proteínas preditas em FASTA (para BLAST, alinhamentos)
#   .ffn  → genes em FASTA de nucleotídeos
#   .tsv  → tabela resumo das ORFs anotadas
#   .txt  → estatísticas gerais da anotação
#   .log  → log completo do Prokka

# Quantas ORFs/CDS foram anotadas?
grep -c "CDS" 3.prokka/sars_anotado.gff

# Listar posição de início, fim e strand de cada CDS
# $1=sequência · $4=início · $5=fim · $7=strand (+/-)
grep "CDS" 3.prokka/sars_anotado.gff \
    | awk '{print $1, $4, $5, $7}' \
    | column -t

# Ver o arquivo TSV — mais fácil de ler: locus, EC, COG, produto
# less -S → não quebra linhas longas; use ← → para rolar; q para sair
column -t 3.prokka/sars_anotado.tsv | less -S

# Ver o resumo estatístico da anotação
cat 3.prokka/sars_anotado.txt


# =============================================================================
# PARTE 5 — Alinhamento ao genoma de referência com minimap2
# =============================================================================

# Verificar versões
minimap2 --version
samtools version

# Por que alinhar à referência depois de já ter montado de novo?
# A montagem de novo nos dá o genoma do isolado.
# O alinhamento à referência nos diz:
#   - Onde no genoma de referência cada parte do nosso contig se encaixa
#   - Regiões que faltam (gaps de cobertura)
#   - Diferenças de nucleotídeo (SNPs, indels) entre o isolado e o Wuhan-Hu-1

# Alinhar o contig montado à referência NC_045512.2
# -a  → saída em formato SAM (necessário para o pipe com samtools)
# -x asm5 → preset para alinhamento de montagens contra referência (divergência < 5%)
#            diferente de -x sr (reads curtos) — aqui alinhamos contigs inteiros
# samtools sort → converte SAM para BAM ordenado por posição
# -o → arquivo de saída BAM
minimap2 \
    -ax asm5 \
    1.genome_ref/ref_NC_045512.2.fasta \
    3.seqkit/sars_contig_rc.fasta \
    | samtools sort -o 4.minimap/sars_vs_ref.bam

# Indexar o BAM — cria o arquivo .bai necessário para o IGV e consultas rápidas
# Sem o índice o IGV recusa o arquivo
samtools index 4.minimap/sars_vs_ref.bam

# Verificar o alinhamento: estatísticas gerais
# flagstat foi projetado para reads, não contigs — por isso várias linhas mostram 0.
# O que importa são duas linhas:
#   1 + 0 in total      → entrou 1 sequência (nosso contig)
#   1 + 0 mapped (100%) → alinhou completamente contra NC_045512.2
# Isso confirma que a montagem foi bem-sucedida.
samtools flagstat 4.minimap/sars_vs_ref.bam

# Proporção do genoma de referência coberta pelo contig (posições com profundidade > 0)
# $3 = profundidade em cada posição; contamos só as posições onde $3 > 0
samtools depth \
    4.minimap/sars_vs_ref.bam \
    | awk '$3>0{coberto++} END{printf "Posições cobertas: %d / 29903 (%.1f%%)\n", coberto, coberto/29903*100}'
# 28.951 de 29.903 posições cobertas (96,8%) — o contig montado representa
# quase o genoma completo do SARS-CoV-2. Os ~3,2% ausentes correspondem
# às regiões 5' e 3' UTR, que o protocolo ARTIC amplifica com menor eficiência.

# Indexar a referência FASTA — cria o arquivo .fai necessário para o IGV
# O .fai mapeia o nome de cada sequência para a posição em bytes no arquivo
# permitindo acesso direto a qualquer região sem ler o arquivo inteiro
samtools faidx 1.genome_ref/ref_NC_045512.2.fasta


# =============================================================================
# PARTE 6 — Visualização no IGV (browser)
# =============================================================================

# IGV (Integrative Genomics Viewer) roda direto no navegador:
# https://igv.org/app/
#
# Não precisa instalar nada — usa o Codespace só para os arquivos.
#
# PASSO A PASSO PARA OS ALUNOS:
#
# 1. Abrir https://igv.org/app/ no navegador
#
# 2. Carregar o genoma de referência:
#    Genome → Local File → selecionar:
#      1.genome_ref/ref_NC_045512.2.fasta
#      1.genome_ref/ref_NC_045512.2.fasta.fai
#
# 3. Carregar o alinhamento do contig:
#    Tracks → Local File → selecionar:
#      4.minimap/sars_vs_ref.bam
#      4.minimap/sars_vs_ref.bam.bai
#
# 4. Carregar a anotação do Prokka:
#    Tracks → Local File → selecionar:
#      3.prokka/sars_anotado.gff
#
# Com três camadas sobrepostas, os alunos verão:
#   camada 1 (fundo) → NC_045512.2 — referência canônica Wuhan-Hu-1
#   camada 2 (meio)  → BAM — onde o nosso contig se alinha
#   camada 3 (cima)  → GFF — quais genes foram anotados pelo Prokka
#
# ATENÇÃO: o GFF usa o nome "SARS-CoV-2_SRR13510367_montado" — para que
# os genes apareçam corretamente é necessário substituir pelo nome da referência:
# sed 's/SARS-CoV-2_SRR13510367_montado/NC_045512.2/g' \
#     3.prokka/sars_anotado.gff > 3.prokka/sars_anotado_igv.gff
# Carregar o sars_anotado_igv.gff no lugar do original.
#
# PERGUNTAS PARA DISCUSSÃO NA TELA:
#   - O contig cobre o genoma inteiro ou há regiões ausentes?
#     → 96,8% cobertos; UTRs 5' e 3' descobertas (esperado no protocolo ARTIC)
#   - Há diferenças de cor no BAM?
#     → Sim — barrinhas coloridas são SNPs entre o isolado e o Wuhan-Hu-1
#   - Qual gene ocupa mais espaço?
#     → orf1ab (~21 kb, ~70% do genoma) — maquinaria completa de replicação viral
#   - As bordas 5' e 3' estão cobertas?
#     → Não completamente — UTRs descobertas pelo protocolo ARTIC




# =============================================================================
# PARTE 7 — Mapa circular com Proksee (web, zero instalação)
# =============================================================================

# Proksee (proksee.ca) gera mapas circulares interativos e permite rodar
# ferramentas de anotação e comparação diretamente na interface web.
# Usaremos o .gbk gerado pelo Prokka como entrada.
#
# PASSO A PASSO:
#
# 1. Abrir https://proksee.ca no navegador → New Project
#
# 2. Carregar o genoma anotado:
#    Upload → selecionar: 3.prokka/sars_anotado.gbk
#
# 3. O mapa circular mostra automaticamente os CDS anotados pelo Prokka
#
# 4. Adicionar camadas via Tools (painel direito):
#    → GC Content (Add) — variação do conteúdo GC ao longo do genoma
#    → GC Skew (Add)    — desvio GC, indica viés de mutação por strand
#    → BLAST (Start)    — comparar CDS contra as proteínas da referência
#       Query: Translated DNA · Subject: ref_NC_045512.2_proteinas.faa
#       Isso identifica cada gene pelo nome da proteína correspondente
#
# 5. Exportar via Snapshot para PNG ou SVG
#
# DISCUSSÃO:
#   - O orf1ab domina o mapa — ocupa ~2/3 do círculo (~21 kb)
#   - Os genes estruturais (S, E, M, N) ficam no último terço
#   - O BLAST mostra 100% de identidade nos genes estruturais
#   - As únicas mutações estão no orf1ab e na proteína S — genes sob pressão seletiva


# =============================================================================
# PARTE 8 — Integrar com QUAST usando referência
# =============================================================================

# Agora que temos a referência, podemos rodar o QUAST de forma mais completa.
# Na Aula 04 rodamos sem referência — QUAST trabalhava "no escuro".
# Com referência, o QUAST calcula cobertura, misassemblies e identidade.

# Rodar QUAST comparando o contig com NC_045512.2
# --reference → genoma de referência para comparação
# --threads 2 → núcleos disponíveis no Codespace
quast.py \
    3.seqkit/sars_contig_rc.fasta \
    --reference 1.genome_ref/ref_NC_045512.2.fasta \
    --output-dir 3.quast_com_ref/ \
    --threads 2

# Ver o relatório completo
cat 3.quast_com_ref/report.txt

# Métricas novas que aparecem só com referência:
#   Genome fraction (%) → % do genoma de referência coberta pelo contig
#   Duplication ratio   → se > 1.0, há regiões duplicadas na montagem
#   Largest alignment   → maior bloco alinhado de forma contínua
#   Misassemblies       → rearranjos, inversões ou translocações detectadas
#   Mismatches/100kbp   → SNPs entre o isolado e o Wuhan-Hu-1
#   Indels/100kbp       → inserções e deleções em relação à referência

# O QUAST também gera um alinhamento visual (Icarus browser):
echo "Relatório visual: 3.quast_com_ref/icarus.html"


# =============================================================================
# PARTE 9 — Salvar e versionar os resultados
# =============================================================================

# Verificar o que foi gerado hoje
tree
git add .
# Commit descritivo
git commit -m "aula05: seqkit + Prokka + minimap2 + IGV + Proksee + QUAST · SARS-CoV-2 SRR13510367"

# Enviar para o fork pessoal no GitHub
git push origin main


# =============================================================================
# FIM DO ESPELHO — AULA 05
# =============================================================================
