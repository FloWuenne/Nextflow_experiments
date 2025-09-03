#!/usr/bin/env nextflow

process DISK_INSPECTION {
    container 'ubuntu:22.04'
    
    output:
    stdout

    script:
    """
    echo "=== AWS EC2 Disk Inspection Report ==="
    echo "Instance: \$(hostname)"
    echo "Date: \$(date)"
    echo ""
    
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
    DISK_INSPECTION() | view
}