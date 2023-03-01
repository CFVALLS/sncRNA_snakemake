'''
quick check of miRNA pipeline

command snakemake -p --cores XX


'''
# Download al FASTQ
with open('SRR_Acc_List.txt') as file:
    SAMPLES = [line.rstrip() for line in file]

rule all_samples:
    ''' all_samples: rule to run every other rule in pipeline'''
    input:
        expand("fastqc_post/{sample}_trimmed_fastqc.zip", sample=SAMPLES),
        expand("fastqc/{sample}_fastqc.zip", sample=SAMPLES),
        "config.txt",
        expand("trimmed/{sample}_trimmed.fastq", sample=SAMPLES),
        "mapper/mirdeep2_reads.fa",
        "quantifier",

rule fasterq_dump:
    ''' download FASTQ using fastq-dump from SRA-tools'''
    output:
        "fastq/{sample}.fastq"
    priority: 50

    shell:
        "fasterq-dump -p -o {output} {wildcards.sample}; "

rule fastqc:
    ''' run quality control before trimming'''
    input:
        "fastq/{sample}.fastq"
    output:
        "fastqc/{sample}_fastqc.zip",
        "fastqc/{sample}_fastqc.html"

    shell:
        "mkdir -p fastqc ; fastqc --nogroup -o fastqc {input}"

rule cutadapt_se:
    ''' Trims single-end reads with given parameters '''
    input:
        "fastq/{sample}.fastq"
    output:
        trimmed_fastq = "trimmed/{sample}_trimmed.fastq",

    params:
        max_length = '27',
        # trim_to_length = '28', --length {params.trim_to_length}
        seq_trimming = 'AGATCGGAAGAGCACACGTCT',
        min_length = '17',
        quality_trimming = '30',
    priority: 25

    shell:
        """
        cutadapt --cores=0 -q {params.quality_trimming} \
        --minimum-length={params.min_length} -a {params.seq_trimming} {input} |  \
        cutadapt --maximum-length={params.max_length} \
         -o  {output.trimmed_fastq} -
        """

rule fastqc_2:
    ''' run quality control post trimming'''
    input:
        "trimmed/{sample}_trimmed.fastq"
    output:
        "fastqc_post/{sample}_trimmed_fastqc.zip",
        "fastqc_post/{sample}_trimmed_fastqc.html",
    priority: 25

    shell:
        "mkdir -p fastqc_post ; fastqc --nogroup -o fastqc_post {input}"

rule list_fastqfiles:
    ''' lists all downloaded and trimmed fastq files'''
    input:
        trimmed_files = expand(rules.cutadapt_se.output, sample=SAMPLES)
    output:
        "config.txt",
    run:
        import os
        dir_path = os.getcwd()
        dir_path = dir_path + "/trimmed"
        # list to store files
        res = []
        # Iterate directory
        for file in os.listdir(dir_path):
            # check only text files
            if file.endswith('_trimmed.fastq'):
                res.append(file)

        for i in range(0, len(res)):
            res[i] = 'trimmed/' + res[i] + ' {0:0>3}'.format(i)

        with open('config.txt', 'w') as filehandle:
            for listitem in res:
                filehandle.write('%s\n' % listitem)

rule mapper:
    ''' mirdeep2 package mapper. maps reads to reference genome'''
    input:
        config = "config.txt",
    output:
        reads = "mapper/mirdeep2_reads.fa",
        mappings = "mapper/mapped_reads.arf",
    params:
        preindex_genome_dir = "BowtieIndex/genome"

    shell:
        "mapper.pl {input.config} -d -e -m -j -h -p {params.preindex_genome_dir} -s {output.reads} -t {output.mappings}"

rule quantifier:
    input:
        config = "config.txt",
        precursors_fa = "mirbase_fa/hairpin_hsa.fa",
        mature_fa = "mirbase_fa/mature_hsa.fa",
        reads = "mapper/mirdeep2_reads.fa",

    output:
        # "miRNAs_expressed_all_samples.csv"
        # "expression.html"
        directory("quantifier")
    params:
        species = "hsa"
    shell:
        "mkdir -p quantifier ; quantifier.pl -g 1 -d -c {input.config} -p {input.precursors_fa} -m {input.mature_fa} -r {input.reads} -t {params.species}"
