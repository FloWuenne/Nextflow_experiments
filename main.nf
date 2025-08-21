#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
 * S3 FASTQ File Handling Comparison Pipeline
 * 
 * This pipeline compares three approaches for handling S3 FASTQ files:
 * 1. Native Nextflow S3 file handling
 * 2. String-based AWS CLI approach
 */

process NATIVE_S3_HANDLING {
    tag "native-s3"
    container 'community.wave.seqera.io/library/fastqc_pip_awscli:74c3af0f1ee072db'
    
    input:
    path input_file
    
    output:
    path "native_output.txt"
    path "native_stats.txt"
    path "*_fastqc.html", optional: true
    path "*_fastqc.zip", optional: true
    
    script:
    """
    echo "=== Native S3 FASTQ File Handling ===" > native_output.txt
    echo "Input file: ${input_file}" >> native_output.txt
    echo "File size: \$(stat -c%s ${input_file} 2>/dev/null || stat -f%z ${input_file})" >> native_output.txt
    echo "Processing started: \$(date)" >> native_output.txt
    
    # Extract first 1000 lines (250 reads) for processing
    echo "Extracting first 1000 lines for FastQC analysis..." >> native_output.txt
    zcat ${input_file} | head -1000 > subset_sample.fastq
    
    # Use FastQC to process subset FASTQ file
    echo "Running FastQC on FASTQ subset (1000 lines)..." >> native_output.txt
    fastqc subset_sample.fastq --outdir . 2>&1 | tee fastqc_log.txt || echo "FastQC failed" > fastqc_log.txt
    cat fastqc_log.txt >> native_output.txt
    
    echo "Getting basic FASTQ stats..." >> native_output.txt
    echo "Original file size: \$(stat -c%s ${input_file} 2>/dev/null || stat -f%z ${input_file})" >> native_output.txt
    echo "Subset lines processed: 1000" >> native_output.txt
    echo "Estimated reads in subset: 250" >> native_output.txt
    
    echo "Processing completed: \$(date)" >> native_output.txt
    
    # Create stats file
    echo "Method: Native Nextflow S3 handling with FastQC" > native_stats.txt
    echo "Start time: \$(date)" >> native_stats.txt
    echo "File path: ${input_file}" >> native_stats.txt
    echo "File exists: \$(test -f ${input_file} && echo 'yes' || echo 'no')" >> native_stats.txt
    echo "FastQC HTML exists: \$(ls *_fastqc.html 2>/dev/null && echo 'yes' || echo 'no')" >> native_stats.txt
    """
}

process AWS_CLI_S3_HANDLING {
    tag "aws-cli-s3"
    container 'community.wave.seqera.io/library/fastqc_pip_awscli:74c3af0f1ee072db'
    
    input:
    val s3_path
    
    output:
    path "awscli_output.txt"
    path "awscli_stats.txt"
    path "*_fastqc.html", optional: true
    path "*_fastqc.zip", optional: true
    
    script:
    """
    echo "=== AWS CLI S3 FASTQ File Handling ===" > awscli_output.txt
    echo "S3 path: ${s3_path}" >> awscli_output.txt
    echo "Processing started: \$(date)" >> awscli_output.txt
    
    # Download FASTQ file using AWS CLI
    echo "Downloading FASTQ file from S3..." >> awscli_output.txt
    aws s3 cp "${s3_path}" ./temp_input_file.fastq.gz --no-sign-request
    
    if [ -f ./temp_input_file.fastq.gz ]; then
        echo "FASTQ file downloaded successfully" >> awscli_output.txt
        echo "File size: \$(stat -c%s ./temp_input_file.fastq.gz 2>/dev/null || stat -f%z ./temp_input_file.fastq.gz)" >> awscli_output.txt
        
        # Extract first 1000 lines (250 reads) for processing
        echo "Extracting first 1000 lines for FastQC analysis..." >> awscli_output.txt
        zcat ./temp_input_file.fastq.gz | head -1000 > subset_sample.fastq
        
        # Use FastQC to process subset FASTQ file
        echo "Running FastQC on FASTQ subset (1000 lines)..." >> awscli_output.txt
        fastqc subset_sample.fastq --outdir . 2>&1 | tee fastqc_log.txt || echo "FastQC failed" > fastqc_log.txt
        cat fastqc_log.txt >> awscli_output.txt
        
        echo "Getting basic FASTQ stats..." >> awscli_output.txt
        echo "Original compressed file size: \$(stat -c%s ./temp_input_file.fastq.gz 2>/dev/null || stat -f%z ./temp_input_file.fastq.gz)" >> awscli_output.txt
        echo "Subset lines processed: 1000" >> awscli_output.txt
        echo "Estimated reads in subset: 250" >> awscli_output.txt
    else
        echo "Failed to download FASTQ file" >> awscli_output.txt
    fi
    
    echo "Processing completed: \$(date)" >> awscli_output.txt
    
    # Create stats file
    echo "Method: AWS CLI string-based handling with FastQC" > awscli_stats.txt
    echo "Start time: \$(date)" >> awscli_stats.txt
    echo "S3 path: ${s3_path}" >> awscli_stats.txt
    echo "Local file exists: \$(test -f ./temp_input_file.fastq.gz && echo 'yes' || echo 'no')" >> awscli_stats.txt
    echo "FastQC HTML exists: \$(ls *_fastqc.html 2>/dev/null && echo 'yes' || echo 'no')" >> awscli_stats.txt
    """
}

process COMPARE_RESULTS {
    tag "comparison"
    publishDir params.outdir, mode: 'copy'
    
    input:
    path native_output
    path native_stats
    path awscli_output
    path awscli_stats
    
    output:
    path "comparison_report.txt"
    path "method_outputs"
    
    script:
    """
    echo "=== S3 FASTQ File Handling Comparison Report ===" > comparison_report.txt
    echo "Generated on: \$(date)" >> comparison_report.txt
    echo "" >> comparison_report.txt
    
    echo "## Native Nextflow S3 Handling Stats:" >> comparison_report.txt
    cat ${native_stats} >> comparison_report.txt
    echo "" >> comparison_report.txt
    
    echo "## AWS CLI String-based Handling Stats:" >> comparison_report.txt
    cat ${awscli_stats} >> comparison_report.txt
    echo "" >> comparison_report.txt
    
    echo "## Performance Notes:" >> comparison_report.txt
    echo "- Native handling: Nextflow manages S3 credentials and caching automatically" >> comparison_report.txt
    echo "- AWS CLI handling: Requires explicit AWS CLI commands and manual file management" >> comparison_report.txt
    echo "- FastQC native S3: Tool attempts direct S3 access (may fall back to streaming)" >> comparison_report.txt
    echo "- Native handling: Better integration with Nextflow's resume functionality" >> comparison_report.txt
    echo "- AWS CLI handling: More explicit control over S3 operations and guaranteed local access" >> comparison_report.txt
    
    # Create output directories
    mkdir -p method_outputs
    cp ${native_output} method_outputs/
    cp ${awscli_output} method_outputs/
    
    echo "Note: FastQC HTML/ZIP reports are published separately by individual processes" >> comparison_report.txt
    """
}

workflow {
    // Parameters
    if (!params.s3_fastq_file) {
        error "ERROR: --s3_fastq_file parameter is required. Please specify an S3 FASTQ file path (e.g., --s3_fastq_file s3://your-bucket/your-file.fastq.gz)"
    }
    s3_fastq_file_path = params.s3_fastq_file
    
    // Channel for native S3 handling (Nextflow treats this as a file)
    native_input_ch = Channel.fromPath(s3_fastq_file_path)
    
    // Channel for AWS CLI handling (treated as string)
    awscli_input_ch = Channel.of(s3_fastq_file_path)
    
    // Run all three processes
    native_results = NATIVE_S3_HANDLING(native_input_ch)
    awscli_results = AWS_CLI_S3_HANDLING(awscli_input_ch)
    
    // Compare results
    COMPARE_RESULTS(
        native_results[0],  // native_output.txt
        native_results[1],  // native_stats.txt
        awscli_results[0],  // awscli_output.txt
        awscli_results[1]   // awscli_stats.txt
    )
}