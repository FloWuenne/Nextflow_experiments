# S3 File Handling Comparison Pipeline

This Nextflow pipeline compares two different approaches for handling S3 files in workflows:

1. **Native Nextflow S3 handling** - Uses Nextflow's built-in S3 integration
2. **AWS CLI string-based approach** - Uses explicit AWS CLI commands with string paths

## Overview

The pipeline demonstrates the differences between these approaches by:
- Processing the same S3 file using both methods
- Generating output files and statistics for each approach
- Creating a comparison report highlighting the pros and cons

## Prerequisites

- **Nextflow** (version 22.10.0 or later)
- **Docker** (for containerized execution)
- **AWS credentials** configured (via AWS CLI, environment variables, or IAM role)
- **S3 access** to the test file you want to process

## AWS Setup

Before running the pipeline, ensure your AWS credentials are configured:

```bash
# Option 1: Using AWS CLI
aws configure

# Option 2: Using environment variables
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1

# Option 3: Using IAM role (if running on EC2)
# No additional setup needed
```

## Usage

### Basic Usage

```bash
nextflow run main.nf --s3_file s3://your-bucket/your-file.txt
```

### Advanced Usage

```bash
nextflow run main.nf \
  --s3_file s3://your-bucket/your-file.txt \
  --outdir ./custom_results
```

### Configuration Options

You can modify the `nextflow.config` file to customize:

- **AWS region**: Change the `aws.region` parameter
- **Output directory**: Modify `params.outdir`
- **Resource allocation**: Adjust `process.cpus` and `process.memory`
- **Executor**: Change from `local` to `awsbatch`, `slurm`, etc.

### Example Commands

```bash
# Test with a public S3 file (if available)
nextflow run main.nf --s3_file s3://1000genomes/README.analysis_history

# Run with custom output directory
nextflow run main.nf \
  --s3_file s3://your-bucket/test-data.txt \
  --outdir ./comparison_results

# Run with specific AWS profile
AWS_PROFILE=myprofile nextflow run main.nf --s3_file s3://your-bucket/data.txt
```

## Output

The pipeline generates the following outputs in the results directory:

- `comparison_report.txt` - Detailed comparison of both methods
- `method_outputs/` - Directory containing individual output files
  - `native_output.txt` - Results from native Nextflow handling
  - `awscli_output.txt` - Results from AWS CLI handling
- `execution_report.html` - Nextflow execution report
- `timeline_report.html` - Timeline visualization
- `trace_report.txt` - Execution trace
- `pipeline_dag.html` - Pipeline DAG visualization

## Key Differences Demonstrated

| Aspect | Native Nextflow | AWS CLI Approach |
|--------|----------------|------------------|
| **Setup** | Automatic S3 integration | Requires AWS CLI container |
| **Caching** | Built-in with `-resume` | Manual implementation needed |
| **Error Handling** | Integrated retry logic | Custom error handling required |
| **Credentials** | Uses Nextflow's AWS config | Inherits from container environment |
| **Performance** | Optimized for Nextflow | Direct AWS CLI calls |

## Troubleshooting

### Common Issues

1. **Missing S3 file parameter**
   ```
   ERROR: --s3_file parameter is required
   ```
   **Solution**: Always specify the `--s3_file` parameter

2. **AWS credentials not found**
   ```
   Unable to load AWS credentials
   ```
   **Solution**: Configure AWS credentials as described in the AWS Setup section

3. **Docker not available**
   ```
   Docker daemon not running
   ```
   **Solution**: Start Docker or disable containers in `nextflow.config`

4. **S3 access denied**
   ```
   Access Denied (Service: Amazon S3)
   ```
   **Solution**: Ensure your AWS credentials have read access to the specified S3 bucket/file

### Performance Tips

- Use S3 work directory for better performance: uncomment `workDir` in `nextflow.config`
- For large files, consider using AWS Batch executor instead of local
- Enable Nextflow's built-in caching with `-resume` flag for repeated runs

## Development

To modify or extend this pipeline:

1. Edit `main.nf` to add new processes or modify existing ones
2. Update `nextflow.config` for different execution environments
3. Test changes with the `-resume` flag to avoid re-running completed processes

## License

This is a test/demonstration pipeline for educational purposes.
