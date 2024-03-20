#!/bin/bash

#     _________
#    / ======= \
#   / __________\
#  | ___________ |
#  | | -       | |
#  | |         | |
#  | |_________| |_____________________________________
#  \=____________/   Rodrigo <Sud0Pirat3> Brasil       )
#  / """"""""""" \                                    /
# / ::::::::::::: \                               =D-'
#(_________________)

# Date created: 20/03/2024
# Last Revision: 20/03/2024

# Purpose: This script uses speedtest and expands on it adding some options like outputing the results into a txt file, number of tests and converting the speed from megabits to megabytes 
# This script was made for testing purposes on my network but tought other people might find it usefull 

# Must have speedtest installed | Check speedtest cli page for more info https://www.speedtest.net/apps/cli

# Function to animate loading
function animate_loading {
    local chars="/-\|"
    local delay=0.1

    while true; do
        for ((i = 0; i < ${#chars}; i++)); do
            echo -en "\rTesting speeds ${chars:$i:1}"
            sleep $delay
        done
    done
}

# Function to convert Mbps to MBps
function mbps_to_mbps {
    local mbps=$1
    local mbps=$(echo "$mbps * 0.125" | bc -l)
    echo "$mbps"
}

# Display usage information
function display_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -o <output_file>   Specify the output file"
    echo "  -n <num_tests>     Number of tests to run (default: 3)"
    echo "  -b                 Output speeds in MB/s instead of Mbit/s"
    echo "  -h                 Display this help message"
}

# Default output file
output_file=""
# Default number of tests
num_tests=3
# Default unit
unit="mbps"

# Parse command-line options
while getopts "o:n:bh" opt; do
    case $opt in
        o) output_file="$OPTARG"
           ;;
        n) num_tests="$OPTARG"
           ;;
        b) unit="b"
           ;;
        h) display_usage
           exit 0
           ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            display_usage
            exit 1
            ;;
    esac
done

# Function to run speed test and capture results
function run_speedtest {
    local result=$(speedtest)
    echo "$result"
}

# Function to extract download speed from speedtest result
function extract_download_speed {
    local result="$1"
    local download_speed=$(echo "$result" | grep -oP '(?<=Download:\s)[0-9.]+')
    echo "$download_speed"
}

# Function to extract upload speed from speedtest result
function extract_upload_speed {
    local result="$1"
    local upload_speed=$(echo "$result" | grep -oP '(?<=Upload:\s)[0-9.]+')
    echo "$upload_speed"
}

# Array to store download and upload speeds
download_speeds=()
upload_speeds=()

# Run speed test multiple times and capture results
animate_loading &   # Start the loading animation in the background
loading_pid=$!      # Get the process ID of the loading animation

for ((i = 0; i < num_tests; i++)); do
    speedtest_result=$(run_speedtest)
    download_speed=$(extract_download_speed "$speedtest_result")
    upload_speed=$(extract_upload_speed "$speedtest_result")

    # Check if download and upload speeds are not empty
    if [[ -n "$download_speed" && -n "$upload_speed" ]]; then
        download_speeds+=("$download_speed")
        upload_speeds+=("$upload_speed")
    else
        echo "Error: Unable to retrieve speedtest results. Skipping test $((i + 1))"
    fi
done

# Kill the loading animation process
kill $loading_pid &> /dev/null

# Print a newline to move to the next line
echo

# Calculate average download speed
total_download_speed=0
for speed in "${download_speeds[@]}"; do
    total_download_speed=$(echo "$total_download_speed + $speed" | bc)
done
average_download_speed=$(echo "scale=2; $total_download_speed / ${#download_speeds[@]}" | bc)

# Calculate average upload speed
total_upload_speed=0
for speed in "${upload_speeds[@]}"; do
    total_upload_speed=$(echo "$total_upload_speed + $speed" | bc)
done
average_upload_speed=$(echo "scale=2; $total_upload_speed / ${#upload_speeds[@]}" | bc)

# Convert speeds to MBps if necessary
if [ "$unit" = "b" ]; then
    average_download_speed=$(mbps_to_mbps $average_download_speed)
    average_upload_speed=$(mbps_to_mbps $average_upload_speed)
fi

# Print average speeds
if [ "$unit" = "b" ]; then
    echo "Average Download Speed: $average_download_speed MB/s"
    echo "Average Upload Speed: $average_upload_speed MB/s"
else
    echo "Average Download Speed: $average_download_speed Mbit/s"
    echo "Average Upload Speed: $average_upload_speed Mbit/s"
fi

# Save results to output file if specified
if [ -n "$output_file" ]; then
    if [ "$unit" = "b" ]; then
        echo "Average Download Speed: $average_download_speed MB/s" > "$output_file"
        echo "Average Upload Speed: $average_upload_speed MB/s" >> "$output_file"
    else
        echo "Average Download Speed: $average_download_speed Mbit/s" > "$output_file"
        echo "Average Upload Speed: $average_upload_speed Mbit/s" >> "$output_file"
    fi
    echo "Speedtest results saved to $output_file"
fi










