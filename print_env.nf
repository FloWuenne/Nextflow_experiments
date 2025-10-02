#!/usr/bin/env nextflow

process PRINT_ENV {
    debug true

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
