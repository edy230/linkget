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
    sed -n 's/.*href="\([^"]*\).*/\1/p' "$input_file" > "$output_file"
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

# Function to extract links from downloaded HTML files
extract_all_links() {
    local download_dir=$1
    local output_links=$2
    
    > "$output_links"  # Clear the output file if it exists

    for file in "$download_dir"/*.php; do
        if [ -e "$file" ]; then
            extract_links "$file" temp_links.txt
            cat temp_links.txt >> "$output_links"
        fi
    done
    rm -f temp_links.txt  # Clean up temporary file
}

# Main script execution starts here
echo '----------***Welcome***----------'
echo '---------------------------------'
echo 'Please introduce your link here: '
read -r link

# Download the initial webpage
download_page "$link" "webpage.html"

# Extract links from the downloaded webpage
extract_links "webpage.html" "wordlist.txt"
rm -f "webpage.html"  # Cleanup temporary file

# Ask for the base URL
echo "Please insert your base link here: "
read -r base_url

# Download each link from the wordlist
download_links "$base_url" "wordlist.txt" "downloaded_pages"
rm -f "wordlist.txt"  # Cleanup wordlist after use

# Extract all links from downloaded pages
extract_all_links "downloaded_pages" "all_links.txt"

echo "All links extracted to: all_links.txt"