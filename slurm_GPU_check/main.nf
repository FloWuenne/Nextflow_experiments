#!/usr/bin/env nextflow

process TEST_GPU_UTILIZATION {

    container "cr.seqera.io/scidev/proteinmpnn:1.0.1"

    input:
    tuple val(id), path(input_structure)

    output:
    tuple val(id) , path("seqs/*.fa")    , emit: design_fasta
    tuple val(id) , path("scores/*.npz") , emit: design_scores
    
    script:
    """
    python3 /home/ProteinMPNN/protein_mpnn_run.py \\
        --pdb_path $input_structure \\
        --num_seq_per_target 10 \\
        --out_folder . \\
        --seed 0 \\
        --batch_size 10 \\
        --model_name v_48_020 \\
        --save_score 1
    """
}

process CHECK_GPU {
    debug false

    input:
    val x
    
    output:
    stdout
    
    script:
    """
    echo "PROCESS,TASK_INDEX,SLOT,TIMESTAMP,GPU_NAME,GPU_UTILIZATION,MEMORY_USED,MEMORY_TOTAL,GPU_UUID,DRIVER_VERSION,GPU_INDEX"
    echo -n "${task.process},${task.index},${x}," && nvidia-smi --query-gpu=timestamp,name,utilization.gpu,memory.used,memory.total,gpu_uuid,driver_version,,index --format=csv,noheader
    """
}

process CHECK_CPU {
    debug false
    
    input:
    val x
    
    output:
    stdout
    
    script:
    """
    sleep 5
    """
}

workflow {
    // Run GPU stress test and metrics collection in parallel
    Channel.of(["test","https://files.rcsb.org/download/2P4E.pdb"]) | TEST_GPU_UTILIZATION
    Channel.of(1,2) | CHECK_GPU | collectFile(name: 'gpu_info.csv', keepHeader: false, skip: 0, storeDir: "${projectDir}/results")
    Channel.of(1,2) | CHECK_CPU
}