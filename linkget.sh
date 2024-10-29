#!/bin/bash

# Function to download a webpage
download_page() {
    local link=$1
    local output_file=$2
    
    echo "Downloading webpage: $link"
    if wget -q "$link" -O "$output_file"; then
        echo "Downloaded: $link"
    else
        echo "Error: Failed to download $link"
        exit 1
    fi
}

# Function to extract links from a webpage
extract_links() {
    local input_file=$1
    local output_file=$2
    
    echo "Extracting links from: $input_file"
    sed -n 's/.*href="\([^"]*\).*/\1/p' "$input_file" | grep -E '^http' > "$output_file"
}

# Function to extract JavaScript from a webpage
extract_javascript() {
    local input_file=$1
    local output_file=$2
    
    echo "Extracting JavaScript from: $input_file"
    grep -oP '<script.*?>\K(.*?)(?=</script>)' "$input_file" >> "$output_file"
}

# Function to download each link and store in a specified directory
download_links() {
    local base_url=$1
    local link_file=$2
    local download_dir=$3
    
    mkdir -p "$download_dir"
    
    while IFS= read -r endpoint; do
        # Construct the full URL
        url="${base_url}/${endpoint}"
        
        # Download the page and save it to the downloaded_pages directory
        local output_file="${download_dir}/${endpoint}"
        wget -q -O "$output_file" "$url"
        
        # Check if the file was downloaded successfully
        if [ -s "$output_file" ]; then
            echo "Downloaded: $url -> $output_file"
        else
            echo "Failed to download: $url"
        fi
    done < "$link_file"
}

# Function to extract either links or JavaScript from downloaded HTML files
extract_all() {
    local download_dir=$1
    local output_file=$2
    local extract_type=$3

    > "$output_file"  # Clear the output file if it exists

    for file in "$download_dir"/*.{php,html}; do
        if [ -e "$file" ]; then
            if [[ $extract_type == "links" ]]; then
                extract_links "$file" temp_output.txt
            elif [[ $extract_type == "javascript" ]]; then
                extract_javascript "$file" temp_output.txt
            fi
            cat temp_output.txt >> "$output_file"
        fi
    done
    rm -f temp_output.txt  # Clean up temporary file
}

# Main script execution starts here
echo '----------***Welcome***----------'
echo '---------------------------------'
echo 'Please introduce your link here: '
read -r link

# Download the initial webpage
download_page "$link" "webpage.html"

# Ask user for extraction type
echo "What would you like to extract? (links/javascript): "
read -r extract_type

# Extract based on user choice
if [[ $extract_type == "links" ]]; then
    extract_links "webpage.html" "wordlist.txt"
    output_file="all_links.txt"
elif [[ $extract_type == "javascript" ]]; then
    extract_javascript "webpage.html" "js_code.txt"
    output_file="all_js_code.txt"
else
    echo "Invalid choice. Please choose 'links' or 'javascript'."
    exit 1
fi

rm -f "webpage.html"  # Cleanup temporary file

# Ask for the base URL for downloading links if links were extracted
if [[ $extract_type == "links" ]]; then
    echo "Please insert your base link here: "
    read -r base_url

    # Download each link from the wordlist
    download_links "$base_url" "wordlist.txt" "downloaded_pages"
    rm -f "wordlist.txt"  # Cleanup wordlist after use

    # Extract all links from downloaded pages
    extract_all "downloaded_pages" "$output_file" "links"
fi

# Extract all JavaScript from downloaded pages if JavaScript was extracted
if [[ $extract_type == "javascript" ]]; then
    extract_all "downloaded_pages" "$output_file" "javascript"
fi

echo "Extraction completed. Output saved to: $output_file"
