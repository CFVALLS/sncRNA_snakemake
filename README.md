##	sncRNAseq_snakemake

Snakemake pipeline para identificacion de microRNAs usando miRDEEP2. Tiene la ventaja de usar paralelismos y tareas concurrentes. Ademas de tener checkpoints para cada tarea.

Como correr el pipeline:
Una vez instalado los requisitos y snakemake
ejecutar en la terminal: 'snakemake --cores = 0 --dry-run' 
Esto indicara el tumero de trabajos a realizar.

Este pipeline fue creado para realizar meta-analisis por lo que contempla la descarga de archivos fastq. De cualquier manera si, no es necesario descargar los archivos se pueden poner en una carpeta fastq que se encuentre al mismo nivel/ruta del archivo snakemake y los procesos de descarga  


Input: - Archivo 'SRR_Acc_List.txt' con los archivos fastq a procesar. Uno por linea. 
	   - Genoma de referencia pre-indexado por Bowtie en carpeta BowtieIndex
	   - microRNAs hairspins y maduros de miRBASe v22 u otra en formato fasta en carpeta mirbase_fa

Output: - descarga de todos los archivos fastq de GEO (opcional)
	    - FASTQC pre-Trimming para todos los archivos.
	    - FASTQ_trimmeados
	    - FASTQC post-trimming
	    - Tabla de Conteo de miRNAs encontrados
	    - outputs standard de mirdeep2

NOTA: 

Herramientas:
* SRA-tools
* CutAdapt
* quantifier
* mapper

El ambiente python de trabajo esta registrado en el archivo .yml


El flujo de trabajo es el siguiente:

1) Si los archivos fastq indicados en el archivo SRR_Acc_List.txt, no se encuentran localmente en la carpeta fastq, estos son descargados usando el modulo fasterq-dump de SRA-tools.
2) Luego se realiza un control de calidad usando fastQC. Es aconsejable evaluar la presencia de adaptadores y otros artefactos antes de correr el pipeline completo.
3) Se realiza un trimmeo para eliminar adaptadores, lecturas de mala calidad y lecturas de tamaño no deseado. Cutadapt.
4) Segundo control de calidad con fastQC, verificar trimming.
5) mappeo de lecutras contra el genoma de referencia usando Mapper.pl (modulo de miRDeep2, que funciona como wrapper de Bowtie)
6) Cuantificacion de aliniamiento usando quantifier.pl (modulo de miRDeep2)
