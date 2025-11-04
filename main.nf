process hello {
    input:
    val name from params.names

    output:
    stdout into result_channel

    """
    echo "Hello, $name!"
    """
}

workflow {
    main:
    hello()
}