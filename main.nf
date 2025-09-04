#!/usr/bin/env nextflow

params.input_file = null

process DISK_INSPECTION {
    container 'ubuntu:22.04'
    
    input:
    path input_file, stageAs: 'staged_input.dat'
    
    output:
    stdout

    script:
    """
    if [ -f "staged_input.dat" ]; then
        echo "=== Staged File Information ==="
        echo "File: staged_input.dat"
        echo "Size (bytes): \$(stat -c%s staged_input.dat)"
        echo "Size (human readable): \$(du -h staged_input.dat | cut -f1)"
        echo "File type: \$(file staged_input.dat)"
        echo ""
    fi
    echo "=== AWS EC2 Disk Inspection Report ==="
    echo "Instance: \$(hostname)"
    echo "Date: \$(date)"
    echo ""
    
    if [ -f "staged_input.dat" ]; then
        echo "=== Input File Staging Test ==="
        echo "Input file staged as: staged_input.dat"
        echo "File size: \$(du -h staged_input.dat | cut -f1)"
        echo "Staging location: \$(pwd)"
        echo "Testing read speed of staged file..."
        time dd if=staged_input.dat of=/dev/null bs=1M 2>&1 | grep -E 'copied|MB/s|GB/s|real|user|sys'
        echo ""
    else
        echo "=== No Input File Provided ==="
        echo "Use --input_file parameter to test file staging performance"
        echo ""
    fi
    
    echo "=== Mounted Disks Information ==="
    df -h
    echo ""
    
    echo "=== Mount Points Detail ==="
    mount | grep -E '^/dev/'
    echo ""
    
    echo "=== Block Devices ==="
    lsblk
    echo ""
    
    echo "=== Disk Write Speed Test ==="
    echo "Testing write speed to current directory..."
    dd if=/dev/zero of=test_write.tmp bs=1M count=100 2>&1 | grep -E 'copied|MB/s|GB/s'
    rm -f test_write.tmp
    echo ""
    
    echo "Testing write speed to /tmp..."
    dd if=/dev/zero of=/tmp/test_write.tmp bs=1M count=100 2>&1 | grep -E 'copied|MB/s|GB/s'
    rm -f /tmp/test_write.tmp
    echo ""
    
    echo "=== Disk Read Speed Test ==="
    echo "Creating test file for read test..."
    dd if=/dev/zero of=test_read.tmp bs=1M count=100 2>/dev/null
    sync
    echo "Testing read speed from current directory..."
    dd if=test_read.tmp of=/dev/null bs=1M 2>&1 | grep -E 'copied|MB/s|GB/s'
    rm -f test_read.tmp
    echo ""
    
    echo "Creating test file in /tmp for read test..."
    dd if=/dev/zero of=/tmp/test_read.tmp bs=1M count=100 2>/dev/null
    sync
    echo "Testing read speed from /tmp..."
    dd if=/tmp/test_read.tmp of=/dev/null bs=1M 2>&1 | grep -E 'copied|MB/s|GB/s'
    rm -f /tmp/test_read.tmp
    echo ""
    
    echo "=== Report Complete ==="
    """
}

workflow {
    input_ch = params.input_file ? Channel.fromPath(params.input_file) : Channel.of(file('NO_FILE'))
    DISK_INSPECTION(input_ch) | view
}