#!/usr/bin/env nextflow

include { KRAKEN2 as KRAKEN2_MEMORYMAPPING } from './modules/kraken2/main.nf'
include { KRAKEN2 as KRAKEN2 }               from './modules/kraken2/main.nf'

workflow {

    // Parameter validation
    if (!params.input) {
        error "Missing required parameter: --input"
    }

    // CSV format: sample_id,read1,read2 (read2 optional for single-end)
    input_ch = channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def sample_id = row.sample_id
            def reads = row.read2 ? [file(row.read1), file(row.read2)] : file(row.read1)
            tuple(sample_id, reads)
        }

    kraken_db_ch = channel
        .of(file(params.kraken2_db))

    // Run KRAKEN2 with memory mapping enabled
    KRAKEN2_MEMORYMAPPING(
        input_ch,
        kraken_db_ch,
        true
    )

    // Run KRAKEN2 without memory mapping
    KRAKEN2(
        input_ch,
        kraken_db_ch,
        false
    )
}
