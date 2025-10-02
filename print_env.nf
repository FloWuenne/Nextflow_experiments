#!/usr/bin/env nextflow

process PRINT_ENV {
    debug true

    container 'community.wave.seqera.io/library/quilt:3.0.6--27d993ec4409ffc4'

    output:
    stdout

    script:
    """
    echo "\$TEST_NXF_SECRET"
    """
}

workflow {
    PRINT_ENV()
}
