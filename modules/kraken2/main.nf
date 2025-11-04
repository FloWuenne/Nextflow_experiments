process KRAKEN2 {
    tag "${sample_id}"
    publishDir "${params.outdir}/kraken2", mode: 'copy'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0f/0f827dcea51be6b5c32255167caa2dfb65607caecdc8b067abd6b71c267e2e82/data' :
        'community.wave.seqera.io/library/kraken2_coreutils_pigz:920ecc6b96e2ba71' }"

    input:
    tuple val(sample_id), path(reads)
    path kraken2_db
    val memory_mapping

    output:
    path('*.classified{.,_}*')     , optional:true, emit: classified_reads_fastq
    path('*.unclassified{.,_}*')   , optional:true, emit: unclassified_reads_fastq
    path('*classifiedreads.txt')   , optional:true, emit: classified_reads_assignment
    path('*report.txt')                           , emit: report

    script:
    def classified_out = reads instanceof List ?
        "--classified-out ${sample_id}.kraken2.classified#.fastq.gz" :
        "--classified-out ${sample_id}.kraken2.classified.fastq.gz"
    def input_reads = reads instanceof List ?
        "--paired ${reads[0]} ${reads[1]}" :
        reads
    def memory_mapping_arg = memory_mapping ? '--memory-mapping' : ''
    """
    export OMP_NUM_THREADS=${task.cpus - 2}
    export OMP_PROC_BIND=close
    export GOMP_CPU_AFFINITY="0-N"

    kraken2 \\
        --use-names \\
        --gzip-compressed \\
        --db ${kraken2_db} \\
        --threads ${task.cpus - 2} \\
        --report ${sample_id}.kraken2.report.txt \\
        --output - \\
        ${memory_mapping_arg} \\
        ${classified_out} \\
        ${input_reads}
    """
}