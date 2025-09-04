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
    
    echo "=== EBS Volume Information ==="
    echo "NVMe devices (EBS volumes):"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | grep -E 'nvme|xvd' || echo "No NVMe/EBS volumes found"
    echo ""
    
    echo "Block device details:"
    for dev in \$(lsblk -lno NAME | grep -E '^(nvme|xvd)'); do
        if [ -b "/dev/\$dev" ]; then
            echo "Device: /dev/\$dev"
            echo "  Size: \$(lsblk -lno SIZE /dev/\$dev 2>/dev/null || echo 'unknown')"
            echo "  Model: \$(lsblk -lno MODEL /dev/\$dev 2>/dev/null || echo 'unknown')"
            echo "  Serial: \$(lsblk -lno SERIAL /dev/\$dev 2>/dev/null || echo 'unknown')"
            echo "  Scheduler: \$(cat /sys/block/\$dev/queue/scheduler 2>/dev/null || echo 'unknown')"
            echo "  Queue depth: \$(cat /sys/block/\$dev/queue/nr_requests 2>/dev/null || echo 'unknown')"
        fi
    done
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
    
    echo "=== I/O Performance Metrics ==="
    echo "Current I/O statistics (before tests):"
    cat /proc/diskstats | grep -E 'nvme|xvd' | head -5 || echo "No EBS volume stats found"
    echo ""
    
    echo "=== IOPS and Latency Test ==="
    echo "Random write IOPS test (4K blocks, 10 seconds):"
    timeout 10 dd if=/dev/zero of=iops_test.tmp bs=4k count=10000 oflag=direct 2>&1 | grep -E 'copied|MB/s|GB/s' || echo "IOPS test completed"
    rm -f iops_test.tmp
    echo ""
    
    echo "Sequential vs Random I/O comparison:"
    echo "Sequential read (1MB blocks):"
    dd if=/dev/zero of=seq_test.tmp bs=1M count=50 2>/dev/null
    sync
    dd if=seq_test.tmp of=/dev/null bs=1M 2>&1 | grep -E 'copied|MB/s|GB/s'
    echo "Random read (4K blocks):"
    dd if=seq_test.tmp of=/dev/null bs=4k skip=\$((RANDOM % 1000)) count=1000 2>&1 | grep -E 'copied|MB/s|GB/s'
    rm -f seq_test.tmp
    echo ""
    
    echo "=== Instance and Network Information ==="
    echo "Instance metadata (if available):"
    timeout 2 curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null | head -1 || echo "Instance type: unavailable"
    timeout 2 curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null | head -1 || echo "AZ: unavailable"
    echo ""
    echo "Network interfaces:"
    ip link show | grep -E '^[0-9]+:' | head -5
    echo ""
    echo "EBS-optimized indicator (network throughput):"
    timeout 2 curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ 2>/dev/null | head -1 | xargs -I {} timeout 2 curl -s "http://169.254.169.254/latest/meta-data/network/interfaces/macs/{}/interface-type" 2>/dev/null || echo "Network info unavailable"
    echo ""
    
    echo "=== System Resource Usage ==="
    echo "Memory usage:"
    free -h
    echo ""
    echo "CPU info:"
    grep -E 'processor|model name|cpu MHz' /proc/cpuinfo | head -6
    echo ""
    echo "Load average:"
    uptime
    echo ""
    
    echo "=== Report Complete ==="
    """
}

workflow {
    input_ch = params.input_file ? Channel.fromPath(params.input_file) : Channel.of(file('NO_FILE'))
    DISK_INSPECTION(input_ch) | view
}