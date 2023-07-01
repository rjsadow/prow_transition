#!/bin/bash

# Initialize variables
prev_output=""
consecutive_same_output=0

# Function to check if the output remains the same
output_changed() {
    if [[ "$1" != "$prev_output" ]]; then
        prev_output="$1"
        consecutive_same_output=0
        return 0
    else
        consecutive_same_output=$((consecutive_same_output+1))
        return 1
    fi
}

# Main loop
while true; do
    # Run the psql command and store the output in a variable
    output=$(psql -U infrasnoop -h infrasnoop -At -c "SELECT SUM(count(*)) OVER () FROM prow.job_spec;")
    
    # Check if the output remains the same
    if output_changed "$output"; then
        echo "Loaded: $output"
    fi
    
    # Check if the output has remained the same for three consecutive times
    if [[ $consecutive_same_output -eq 3 ]]; then
        echo "Output has remained the same for three consecutive times. Exiting..."
        break
    fi
    
    sleep 5
done

