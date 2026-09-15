#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ====================================================================================

// Parameters
params.projectDir = ""
params.outdir = ""
params.inputCSV = ""
params.resources = ""
params.scripts = ""
params.adapter = "${params.resources}/adapter"
params.kraken2_db = ""          // path to a pre-built Kraken2 database
params.bracken_read_len = 150   // read length used to build the Bracken kmer distribution
params.abricate_db = "ncbi"     // ncbi | card | resfinder | argannot | megares | vfdb ...

params.FASTQC_THREAD  = params.FASTQC_THREAD  ?: 4
params.TRIM_THREAD    = params.TRIM_THREAD    ?: 4
params.KRAKEN_THREAD  = params.KRAKEN_THREAD  ?: 8
params.MEGAHIT_THREAD = params.MEGAHIT_THREAD ?: 8

// ====================================================================================
// log
log.info """\
    TAXONOMY + AMR PIPELINE
    FASTQ -> QC/TRIM -> TAXONOMY (Kraken2/Bracken) -> ASSEMBLY -> AMR (ABRicate)
    ============================================================================
    projectDir   : ${params.projectDir}
    inputCSV     : ${params.inputCSV}
    outdir       : ${params.outdir}
    kraken2 db   : ${params.kraken2_db}
    abricate db  : ${params.abricate_db}
    """
    .stripIndent(true)

// ====================================================================================
// Modules

process FastQC1 {
    container = 'fastqc_0.12.1.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/fastqc1", mode: 'link'
    maxForks 20
    cpus = 4
    memory = {2.GB * task.attempt}

    input:
        tuple val(sample_id), path(reads)
    output:
        tuple path("*${sample_id}*R1*_fastqc.zip"), \
            path("*${sample_id}*R2*_fastqc.zip"), \
            path("*${sample_id}*R1*_fastqc.html"), \
            path("*${sample_id}*R2*_fastqc.html")

    script:
    """
    fastqc \
        -t ${params.FASTQC_THREAD} \
        --outdir \$(pwd) \
        ${reads[0]} \
        ${reads[1]}
    """
}

process Trim {
    container = 'trimmomatic_0.39.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    maxForks 20
    cpus = 4
    memory = {1.GB * task.attempt}

    input:
        path adapter
        tuple val(sample_id), path(reads)

    output:
        tuple val(sample_id), \
            path("${sample_id}_R1.fastq.gz"), \
            path("${sample_id}_R2.fastq.gz"), \
            path("${sample_id}_report.log")

    script:
    """
        trimmomatic PE -phred33 ${reads[0]} ${reads[1]} \
            ${sample_id}_R1.fastq.gz ${sample_id}_R1_unpaired.fastq.gz \
            ${sample_id}_R2.fastq.gz ${sample_id}_R2_unpaired.fastq.gz \
            ILLUMINACLIP:${adapter}/TruSeq3-PE-2.fa:2:30:10 \
            LEADING:3 \
            TRAILING:3 \
            SLIDINGWINDOW:4:20 \
            MINLEN:36 \
            -threads ${params.TRIM_THREAD} \
            2> ${sample_id}_report.log
        rm -rf ${sample_id}_R{1,2}_unpaired.fastq.gz
    """
}

process FastQC2 {
    container = 'fastqc_0.12.1.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/fastqc2", mode: 'link'
    maxForks 20
    cpus = 4
    memory = {2.GB * task.attempt}

    input:
        tuple val(sample_id), path(r1), path(r2), path(trim_log)
    output:
        tuple path("*${sample_id}*R1*_fastqc.zip"), \
            path("*${sample_id}*R2*_fastqc.zip"), \
            path("*${sample_id}*R1*_fastqc.html"), \
            path("*${sample_id}*R2*_fastqc.html")

    script:
    """
    fastqc \
        -t ${params.FASTQC_THREAD} \
        --outdir \$(pwd) \
        ${r1} \
        ${r2}
    """
}

// ----------------------------------------------------------------------------------
// Taxonomic profiling: Kraken2 + Bracken
// ----------------------------------------------------------------------------------

process Kraken2 {
    container = 'kraken2_2.1.3.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/kraken2", mode: 'link'
    maxForks 10
    cpus = params.KRAKEN_THREAD
    memory = {32.GB * task.attempt}   // Kraken2 loads the whole DB into RAM; size to your DB

    input:
        val kraken2_db
        tuple val(sample_id), \
            path("${sample_id}_R1.fastq.gz"), \
            path("${sample_id}_R2.fastq.gz"), \
            path("${sample_id}_report.log")

    output:
        tuple val(sample_id), \
            path("${sample_id}.kraken2.out"), \
            path("${sample_id}.kraken2.report")

    script:
    """
        kraken2 \
            --db ${kraken2_db} \
            --threads ${task.cpus} \
            --paired \
            --gzip-compressed \
            --output ${sample_id}.kraken2.out \
            --report ${sample_id}.kraken2.report \
            --use-names \
            ${sample_id}_R1.fastq.gz \
            ${sample_id}_R2.fastq.gz
    """
}

process Bracken {
    container = 'bracken_2.9.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/bracken", mode: 'link'
    maxForks 10
    cpus = 2
    memory = {4.GB * task.attempt}

    input:
        val kraken2_db
        tuple val(sample_id), path(kraken_out), path(kraken_report)

    output:
        tuple val(sample_id), \
            path("${sample_id}.bracken.species.tsv"), \
            path("${sample_id}.bracken.report")

    script:
    """
        bracken \
            -d ${kraken2_db} \
            -i ${kraken_report} \
            -o ${sample_id}.bracken.species.tsv \
            -w ${sample_id}.bracken.report \
            -r ${params.bracken_read_len} \
            -l S \
            -t 10
    """
}

// ----------------------------------------------------------------------------------
// AMR detection: lightweight assembly (MEGAHIT) + ABRicate
// ----------------------------------------------------------------------------------

process Megahit {
    container = 'megahit_1.2.9.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/assembly", mode: 'link', pattern: "${sample_id}_assembly/${sample_id}.contigs.fa"
    maxForks 5
    cpus = params.MEGAHIT_THREAD
    memory = {32.GB * task.attempt}

    input:
        tuple val(sample_id), \
            path("${sample_id}_R1.fastq.gz"), \
            path("${sample_id}_R2.fastq.gz"), \
            path("${sample_id}_report.log")

    output:
        tuple val(sample_id), path("${sample_id}_assembly/${sample_id}.contigs.fa")

    script:
    """
        megahit \
            -1 ${sample_id}_R1.fastq.gz \
            -2 ${sample_id}_R2.fastq.gz \
            -t ${task.cpus} \
            --out-dir ${sample_id}_assembly \
            --out-prefix ${sample_id} \
            --min-contig-len 500
    """
}

process Abricate {
    container = 'abricate_1.4.0.sif'
    tag "$sample_id"
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/abricate", mode: 'link'
    maxForks 10
    cpus = 4
    memory = {4.GB * task.attempt}

    input:
        val abricate_db
        tuple val(sample_id), path(contigs)

    output:
        tuple val(sample_id), path("${sample_id}.abricate.${abricate_db}.tsv")

    script:
    """
        abricate \
            --db ${abricate_db} \
            --threads ${task.cpus} \
            --minid 80 \
            --mincov 80 \
            ${contigs} \
            > ${sample_id}.abricate.${abricate_db}.tsv
    """
}

process AbricateSummary {
    container = 'abricate_1.4.0.sif'
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/abricate", mode: 'link'
    maxForks 1
    cpus = 2
    memory = {2.GB * task.attempt}

    input:
        path(reports)

    output:
        path "abricate_summary.tsv"

    script:
    """
        abricate --summary ${reports} > abricate_summary.tsv
    """
}

process MultiQC {
    container = 'multiqc_1.18.sif'
    errorStrategy 'retry'
    maxRetries 1
    publishDir "${params.outdir}/multiqc", mode: 'link'
    maxForks 1
    cpus = 8
    memory = {8.GB * task.attempt}

    input:
        path fastqc1_chr
        path fastqc2_chr

    output:
        path "multiqc*"

    script:
    """
        multiqc -f -o . -n multiqc_report.html \
            ${fastqc1_chr} \
            ${fastqc2_chr}

        chmod 777 multiqc_report_data
        mv multiqc_report_data/multiqc* .
        rm -rf multiqc_report_data
    """
}

// ====================================================================================
// Main Workflow
workflow {
    fastq_ch = Channel
        .fromPath("$params.inputCSV")
        .splitCsv(header:true, sep: ',')
        .map { row -> tuple(row.labcode, tuple(file(row.dir_r1), file(row.dir_r2))) }

    // ---- QC ----
    fastqc1_chr = FastQC1(fastq_ch)

    // ---- Trim ----
    trim_ch = Trim(params.resources, fastq_ch)

    // ---- QC on trimmed reads ----
    fastqc2_chr = FastQC2(trim_ch)

    // ---- Taxonomic profiling ----
    kraken_ch  = Kraken2(params.kraken2_db, trim_ch)
    bracken_ch = Bracken(params.kraken2_db, kraken_ch)

    // ---- AMR detection: assemble trimmed reads, then screen contigs ----
    assembly_ch = Megahit(trim_ch)
    abricate_ch = Abricate(params.abricate_db, assembly_ch)

    abricate_reports = abricate_ch.map { sample_id, report -> report }.collect()
    AbricateSummary(abricate_reports)

    // ---- MultiQC across before/after trim QC ----
    MultiQC(
        fastqc1_chr.collect(),
        fastqc2_chr.collect()
    )
}