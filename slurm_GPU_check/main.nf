#!/usr/bin/env nextflow
process CHECK_GPU {
    debug false

    input:
    val x
    
    output:
    stdout
    
    
    script:
    """
    echo -n "${task.process},${task.index},${x}," && nvidia-smi --query-gpu=timestamp,name,gpu_uuid,driver_version,index --format=csv,noheader
    """
}

workflow {
    Channel.of(1,2,3,4) | CHECK_GPU | collectFile(name: 'gpu_info.csv', keepHeader: false, skip: 0, storeDir: "${projectDir}/results")
}