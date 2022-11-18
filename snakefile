'''
quick check of miRNA pipeline

command snakemake -p fastqc_post/XXXXXXSRAXXXXXX_fastqc.zip --cores XX


''' 

SAMPLES = ['SRA837506' ,'SRA837506']

rule all_samples:
    ''' all_samples: rule to run every other rule in pipeline'''
    input:
        expand("fastqc_post/{sample}_fastqc.zip" , sample = SAMPLES),
        expand("fastqc/{sample}_fastqc.zip" , sample = SAMPLES),


rule fasterq_dump:
    output:
        "fastq/{sample}.fastq"

    shell:
        "fasterq-dump -p -o {output} {wildcards.sample}; "

rule fastqc:
    input:
        "fastq/{sample}.fastq"
    output:
        "fastqc/{sample}_fastqc.zip",
        "fastqc{sample}_fastqc.html"

    shell:
        "fastqc --nogroup {input}"

rule cutadapt_se:
    """Trims given single-end reads with given parameters"""
    input:
        "fastq/{sample}.fastq"
    output:
        "trimmed/{sample}_trimmed.fastq"

    shell:
        "cutadapt --cores=0 --adapter=TGGAATTCTCGGGTGCCAAGG --maximum-length=50 --minimum-length=15 -o {output} {input};"

rule fastqc_2:
    input:
        "trimmed/{sample}_trimmed.fastq"
    output:
        "fastqc_post/{sample}_fastqc.zip",
        "fastqc_post/{sample}_fastqc.html"

    shell:
        "fastqc --nogroup {input}"