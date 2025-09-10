#!/bin/bash

# MKV Video Summarizer - System Wide Installation
# Uses OpenAI Whisper for transcription and Claude for summarization

set -e

# Configuration
OPENAI_API_KEY="${OPENAI_API_KEY}"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
TEMP_DIR="/tmp/mkv_summarizer_$$"
CHUNK_DURATION=1200  # 20 minutes in seconds for safe chunking
KEEP_TRANSCRIPT="${KEEP_TRANSCRIPT:-true}"  # Default: keep transcript
ENABLE_SPEAKERS="${ENABLE_SPEAKERS:-false}"  # Default: no speaker diarization
INSTALL_PATH="/usr/local/bin/mkv-summarize"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation function
install_script() {
    echo -e "${BLUE}=== Installing MKV Summarizer ===${NC}"

    # Check if running as install mode
    if [ "$1" == "--install" ]; then
        # Check dependencies first
        local deps=("ffmpeg" "curl" "jq")
        for dep in "${deps[@]}"; do
            if ! command -v $dep &> /dev/null; then
                echo -e "${RED}Error: $dep is not installed${NC}"
                echo "Install with: brew install $dep"
                exit 1
            fi
        done

        # Copy script to /usr/local/bin
        echo -e "${GREEN}Installing to $INSTALL_PATH${NC}"
        sudo cp "$0" "$INSTALL_PATH"
        sudo chmod +x "$INSTALL_PATH"

        # Create config file
        local config_dir="$HOME/.config/mkv-summarizer"
        mkdir -p "$config_dir"

        if [ ! -f "$config_dir/config" ]; then
            echo -e "${YELLOW}Creating config file at $config_dir/config${NC}"
            cat > "$config_dir/config" << EOF
# MKV Summarizer Configuration
# Set your API keys here or export them in your shell profile

# OpenAI API Key for Whisper transcription
#OPENAI_API_KEY="your-openai-key-here"

# Anthropic API Key for Claude summarization
#ANTHROPIC_API_KEY="your-anthropic-key-here"

# Keep transcript file (true/false)
KEEP_TRANSCRIPT=true

# Enable speaker identification and timestamps (true/false)
ENABLE_SPEAKERS=false

# Audio quality for extraction (lower = smaller file)
AUDIO_BITRATE=64k

# Chunk duration in seconds (default 20 minutes)
CHUNK_DURATION=1200
EOF
            echo -e "${GREEN}Config file created. Please edit: $config_dir/config${NC}"
        fi

        echo -e "${GREEN}Installation complete!${NC}"
        echo ""
        echo "Usage:"
        echo "  mkv-summarize <video.mkv>              # Process with transcript (Russian summary)"
        echo "  mkv-summarize --no-transcript <video.mkv>  # Skip transcript saving"
        echo "  mkv-summarize --help                   # Show help"
        echo ""
        echo "Don't forget to set your API keys in:"
        echo "  $config_dir/config"
        echo "Or export them in your shell profile"
        exit 0
    fi
}

# Load configuration
load_config() {
    # Set defaults first
    AUDIO_BITRATE="64k"
    CHUNK_DURATION="1200"
    KEEP_TRANSCRIPT="true"
    ENABLE_SPEAKERS="true"

    # Load config file if exists
    local config_file="$HOME/.config/mkv-summarizer/config"
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi

    # Override with environment variables if set
    OPENAI_API_KEY="${OPENAI_API_KEY:-$OPENAI_API_KEY}"
    ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$ANTHROPIC_API_KEY}"
    AUDIO_BITRATE="${AUDIO_BITRATE:-64k}"
    CHUNK_DURATION="${CHUNK_DURATION:-1200}"
    ENABLE_SPEAKERS="${ENABLE_SPEAKERS:-true}"
}

# Help function
show_help() {
    cat << EOF
MKV Video Summarizer
====================

Usage: $(basename $0) [OPTIONS] <video.mkv>

OPTIONS:
    --no-transcript     Don't save the transcript file
    --transcript        Save the transcript file (default)
    --speakers          Enable speaker identification and timestamps
    --no-speakers       Disable speaker identification (default)
    --install          Install script system-wide
    --help             Show this help message

ENVIRONMENT:
    OPENAI_API_KEY      Your OpenAI API key
    ANTHROPIC_API_KEY   Your Anthropic API key
    KEEP_TRANSCRIPT     Set to 'false' to disable transcript by default
    ENABLE_SPEAKERS     Set to 'true' to enable speaker diarization by default

FILES:
    The summary will be saved as: <video_name>_summary.md (contains Russian summary)
    The transcript (if enabled): <video_name>_transcript.txt (original language transcription)
    Both files are saved in the same directory as the input video

EXAMPLES:
    $(basename $0) movie.mkv
    $(basename $0) --no-transcript lecture.mkv
    $(basename $0) --speakers meeting.mkv
    $(basename $0) --speakers --no-transcript conference.mkv
    ENABLE_SPEAKERS=true $(basename $0) video.mkv

EOF
    exit 0
}

# Parse arguments
parse_args() {
    KEEP_TRANSCRIPT_ARG=""
    ENABLE_SPEAKERS_ARG=""
    INPUT_FILE=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --install)
                install_script "--install"
                ;;
            --help|-h)
                show_help
                ;;
            --no-transcript)
                KEEP_TRANSCRIPT_ARG="false"
                shift
                ;;
            --transcript)
                KEEP_TRANSCRIPT_ARG="true"
                shift
                ;;
            --speakers)
                ENABLE_SPEAKERS_ARG="true"
                shift
                ;;
            --no-speakers)
                ENABLE_SPEAKERS_ARG="false"
                shift
                ;;
            *)
                if [ -z "$INPUT_FILE" ]; then
                    INPUT_FILE="$1"
                else
                    echo -e "${RED}Error: Multiple input files specified${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Override config with command line arguments
    if [ ! -z "$KEEP_TRANSCRIPT_ARG" ]; then
        KEEP_TRANSCRIPT="$KEEP_TRANSCRIPT_ARG"
    fi

    if [ ! -z "$ENABLE_SPEAKERS_ARG" ]; then
        ENABLE_SPEAKERS="$ENABLE_SPEAKERS_ARG"
    fi

    if [ -z "$INPUT_FILE" ]; then
        echo -e "${RED}Error: No input file specified${NC}"
        echo "Use --help for usage information"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local deps=("ffmpeg" "curl" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${RED}Error: $dep is not installed${NC}"
            echo "Install with: brew install $dep"
            exit 1
        fi
    done
}

# Validate input
validate_input() {
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}Error: File '$INPUT_FILE' not found${NC}"
        exit 1
    fi

    if [[ ! "$INPUT_FILE" =~ \.mkv$ ]]; then
        echo -e "${YELLOW}Warning: File doesn't have .mkv extension${NC}"
    fi

    # Check API keys
    if [ -z "$OPENAI_API_KEY" ]; then
        echo -e "${RED}Error: OPENAI_API_KEY not set${NC}"
        echo "Set it in ~/.config/mkv-summarizer/config or export it"
        exit 1
    fi

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo -e "${RED}Error: ANTHROPIC_API_KEY not set${NC}"
        echo "Set it in ~/.config/mkv-summarizer/config or export it"
        exit 1
    fi
}

# Create temp directory
setup_temp() {
    mkdir -p "$TEMP_DIR"
    echo -e "${GREEN}Created temp directory: $TEMP_DIR${NC}"
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Extract audio from MKV
extract_audio() {
    local input_file="$1"
    local output_file="$TEMP_DIR/audio.mp3"

    echo -e "${GREEN}Extracting audio from video...${NC}" >&2

    # Check if input file exists and is readable
    if [ ! -r "$input_file" ]; then
        echo -e "${RED}Error: Cannot read input file: $input_file${NC}"
        exit 1
    fi

    # Extract audio with error checking
    local ffmpeg_output
    ffmpeg_output=$(ffmpeg -i "$input_file" -vn -acodec mp3 -ab "$AUDIO_BITRATE" -ar 16000 "$output_file" -y -loglevel error 2>&1)
    local ffmpeg_exit_code=$?

    if [ $ffmpeg_exit_code -eq 0 ]; then
        # Small delay to ensure file system sync
        sleep 0.5

        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            local size=$(du -h "$output_file" | cut -f1)
            echo -e "${GREEN}Audio extracted: $size${NC}" >&2
            echo "$output_file"
        else
            echo -e "${RED}Error: Audio extraction appeared successful but file is missing or empty${NC}"
            echo -e "${YELLOW}FFmpeg output: $ffmpeg_output${NC}"
            echo -e "${YELLOW}Output file expected: $output_file${NC}"
            [ -f "$output_file" ] && echo -e "${YELLOW}File exists but is empty${NC}" || echo -e "${YELLOW}File does not exist${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: Failed to extract audio from video (exit code: $ffmpeg_exit_code)${NC}"
        echo -e "${YELLOW}FFmpeg output: $ffmpeg_output${NC}"
        echo -e "${YELLOW}Make sure the file contains an audio track${NC}"
        exit 1
    fi
}

# Get audio duration in seconds
get_duration() {
    local file="$1"

    # Check if file exists first
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Audio file not found: $file${NC}" >&2
        return 1
    fi

    local duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null | cut -d. -f1)

    # Validate duration is a number
    if [[ ! "$duration" =~ ^[0-9]+$ ]] || [ -z "$duration" ]; then
        echo -e "${RED}Error: Could not get valid duration from: $file${NC}" >&2
        return 1
    fi

    echo "$duration"
}

# Split audio into chunks
split_audio() {
    local input_file="$1"
    local duration
    local chunks=()

    # Get duration with error handling
    if ! duration=$(get_duration "$input_file"); then
        echo -e "${RED}Error: Cannot determine audio duration${NC}" >&2
        return 1
    fi

    if [ "$duration" -le "$CHUNK_DURATION" ]; then
        echo -e "${GREEN}Audio is short enough, no splitting needed (${duration}s)${NC}" >&2
        echo "$input_file"
        return
    fi

    echo -e "${GREEN}Splitting audio into chunks...${NC}" >&2
    local num_chunks=$(( (duration + CHUNK_DURATION - 1) / CHUNK_DURATION ))

    for (( i=0; i<$num_chunks; i++ )); do
        local start=$(( i * CHUNK_DURATION ))
        local chunk_file="$TEMP_DIR/chunk_$i.mp3"

        echo -e "  Creating chunk $((i+1))/$num_chunks: $chunk_file" >&2

        if ffmpeg -i "$input_file" -ss $start -t $CHUNK_DURATION -acodec copy "$chunk_file" -y -loglevel error 2>&1; then
            # Verify chunk was created and is not empty
            if [ -f "$chunk_file" ] && [ -s "$chunk_file" ]; then
                chunks+=("$chunk_file")
                echo -e "  ${GREEN}Chunk $((i+1))/$num_chunks created successfully${NC}" >&2
            else
                echo -e "  ${RED}Error: Chunk $((i+1))/$num_chunks was not created or is empty${NC}" >&2
                return 1
            fi
        else
            echo -e "  ${RED}Error: Failed to create chunk $((i+1))/$num_chunks${NC}" >&2
            return 1
        fi
    done

    # Verify we created chunks before returning them
    if [ ${#chunks[@]} -eq 0 ]; then
        echo -e "${RED}Error: No chunks were created${NC}" >&2
        return 1
    fi

    printf '%s\n' "${chunks[@]}"
}

# Transcribe audio using OpenAI Whisper
transcribe_audio() {
    local audio_file="$1"
    local output_file="$2"

    echo -e "${GREEN}Transcribing audio with OpenAI Whisper...${NC}" >&2

    # Check if audio file exists and is not empty
    if [ ! -f "$audio_file" ]; then
        echo -e "${RED}Error: Audio file not found: $audio_file${NC}" >&2
        return 1
    fi

    if [ ! -s "$audio_file" ]; then
        echo -e "${RED}Error: Audio file is empty: $audio_file${NC}" >&2
        return 1
    fi

    local file_size=$(du -h "$audio_file" | cut -f1)
    echo -e "${BLUE}Transcribing file: $audio_file ($file_size)${NC}" >&2

    # Make the API call with better error handling
    local response
    local http_code

    # Build the curl command based on speaker settings
    if [ "$ENABLE_SPEAKERS" == "true" ]; then
        echo -e "${BLUE}Speaker identification enabled${NC}" >&2
        response=$(curl -s -w "%{http_code}" --request POST \
            --url https://api.openai.com/v1/audio/transcriptions \
            --header "Authorization: Bearer $OPENAI_API_KEY" \
            --header "Content-Type: multipart/form-data" \
            --form "file=@$audio_file" \
            --form "model=whisper-1" \
            --form "response_format=verbose_json" \
            --form "timestamp_granularities[]=segment")
    else
        response=$(curl -s -w "%{http_code}" --request POST \
            --url https://api.openai.com/v1/audio/transcriptions \
            --header "Authorization: Bearer $OPENAI_API_KEY" \
            --header "Content-Type: multipart/form-data" \
            --form "file=@$audio_file" \
            --form "model=gpt-4o-transcribe" \
            --form "response_format=text")
    fi

    http_code="${response: -3}"
    response="${response%???}"

    if [ "$http_code" != "200" ]; then
        echo -e "${RED}Error: Transcription API failed with HTTP code: $http_code${NC}" >&2
        echo -e "${YELLOW}Response: $response${NC}" >&2
        return 1
    fi

    if [ -z "$response" ]; then
        echo -e "${RED}Error: Transcription returned empty response${NC}" >&2
        return 1
    fi

    # Check if response looks like an error (JSON format)
    if [[ "$response" == *"error"* ]] && [[ "$response" == *"{"* ]]; then
        echo -e "${RED}Error: API returned error response${NC}" >&2
        echo -e "${YELLOW}Response: $response${NC}" >&2
        return 1
    fi

    # Process response based on format
    if [ "$ENABLE_SPEAKERS" == "true" ]; then
        # Parse JSON response and format with speaker info and timestamps
        local formatted_text=$(echo "$response" | jq -r '
            if .segments then
                .segments[] |
                "[" + (.start | tostring) + "s - " + (.end | tostring) + "s] " + .text
            else
                .text // "No transcription available"
            end' | tr '\n' ' ' | sed 's/  / /g')

        if [ -z "$formatted_text" ] || [ "$formatted_text" == "No transcription available" ]; then
            # Fallback to simple text extraction
            formatted_text=$(echo "$response" | jq -r '.text // "No transcription available"')
        fi

        echo "$formatted_text" >> "$output_file"
        local word_count=$(echo "$formatted_text" | wc -w)
        echo -e "${GREEN}Transcription with timestamps completed ($word_count words)${NC}" >&2
    else
        # Simple text format
        echo "$response" >> "$output_file"
        local word_count=$(echo "$response" | wc -w)
        echo -e "${GREEN}Transcription completed ($word_count words)${NC}" >&2
    fi
}

# Process all audio chunks
process_chunks() {
    local audio_file="$1"
    local transcript_file="$TEMP_DIR/transcript.txt"

    # Get list of chunks (or single file) - read into array properly
    local chunks=()
    while IFS= read -r line; do
        [ -n "$line" ] && chunks+=("$line")
    done < <(split_audio "$audio_file")

    # Verify we have chunks
    if [ ${#chunks[@]} -eq 0 ]; then
        echo -e "${RED}Error: No audio chunks created${NC}" >&2
        return 1
    fi

    > "$transcript_file"  # Clear file

    local total=${#chunks[@]}
    local current=1

    for chunk in "${chunks[@]}"; do
        echo -e "${YELLOW}Processing chunk $current/$total...${NC}" >&2
        echo -e "${BLUE}Chunk file: $chunk${NC}" >&2

        # Verify chunk file exists before transcription
        if [ ! -f "$chunk" ]; then
            echo -e "${RED}Error: Chunk file does not exist: $chunk${NC}" >&2
            return 1
        fi

        if ! transcribe_audio "$chunk" "$transcript_file"; then
            echo -e "${RED}Failed to transcribe chunk $current/$total${NC}" >&2
            return 1
        fi
        echo -e "\n---\n" >> "$transcript_file"
        ((current++))
    done

    echo "$transcript_file"
}

# Summarize with Claude (Russian only)
summarize_with_claude() {
    local transcript_file="$1"
    local output_file="$2"

    echo -e "${GREEN}Generating Russian summary with Claude...${NC}"

    # Read and escape transcript for JSON
    local transcript=$(cat "$transcript_file" | jq -Rs .)

    # Create the prompt for Russian summary
    local russian_prompt="You are analyzing a transcript from a video. Please provide a summary IN RUSSIAN:

1. A comprehensive SUMMARY of the entire conversation/content (КРАТКОЕ ИЗЛОЖЕНИЕ)
2. KEY POINTS (bullet points of the most important information) (КЛЮЧЕВЫЕ МОМЕНТЫ)
3. MAIN TOPICS discussed (ОСНОВНЫЕ ТЕМЫ)
4. Any ACTION ITEMS or important conclusions (ПЛАН ДЕЙСТВИЙ)

Here is the transcript:

$transcript

Please format your response in clear sections with headers. IMPORTANT: Provide the summary entirely in Russian, regardless of the original transcript language."

    echo -e "${BLUE}Generating Russian summary...${NC}"

    # Create request body for Russian
    local russian_request_body=$(jq -n \
        --arg content "$russian_prompt" \
        '{
            model: "claude-3-5-sonnet-20241022",
            max_tokens: 4000,
            messages: [
                {
                    role: "user",
                    content: $content
                }
            ]
        }')

    # Make API call to Claude for Russian
    local russian_response=$(curl -s --request POST \
        --url https://api.anthropic.com/v1/messages \
        --header "x-api-key: $ANTHROPIC_API_KEY" \
        --header "anthropic-version: 2023-06-01" \
        --header "content-type: application/json" \
        --data "$russian_request_body")

    # Extract content from Russian response
    local russian_summary=$(echo "$russian_response" | jq -r '.content[0].text // empty')

    if [ -z "$russian_summary" ]; then
        echo -e "${RED}Error: Russian summary generation failed${NC}"
        echo "Response: $russian_response"
        return 1
    fi

    # Save Russian summary to output file
    {
        echo "# Резюме видео"
        echo ""
        echo "$russian_summary"
    } > "$output_file"

    echo -e "${GREEN}Russian summary generated successfully${NC}"
}

# Main execution
main() {
    # Get absolute path and directory of input file
    local input_file=$(realpath "$INPUT_FILE")
    local input_dir=$(dirname "$input_file")
    local base_name=$(basename "$input_file" .mkv)

    # Output files in the same directory as input
    local output_file="$input_dir/${base_name}_summary.md"
    local transcript_output="$input_dir/${base_name}_transcript.txt"

    echo -e "${BLUE}=== MKV Video Summarizer ===${NC}"
    echo -e "Processing: $input_file"
    echo -e "Output directory: $input_dir"
    echo -e "Transcript: $([ "$KEEP_TRANSCRIPT" == "true" ] && echo "Yes" || echo "No")"
    echo -e "Speaker identification: $([ "$ENABLE_SPEAKERS" == "true" ] && echo "Yes" || echo "No")"
    echo ""

    # Extract audio
    audio_file=$(extract_audio "$input_file")

    # Transcribe
    transcript_file=$(process_chunks "$audio_file")

    # Check transcript
    if [ ! -s "$transcript_file" ]; then
        echo -e "${RED}Error: Transcription is empty${NC}"
        exit 1
    fi

    local transcript_size=$(wc -w < "$transcript_file")
    echo -e "${GREEN}Transcript size: $transcript_size words${NC}"

    # Save transcript if requested
    if [ "$KEEP_TRANSCRIPT" == "true" ]; then
        cp "$transcript_file" "$transcript_output"
        echo -e "${GREEN}Transcript saved to: $transcript_output${NC}"
    fi

    # Summarize
    summarize_with_claude "$transcript_file" "$output_file"

    # Display results
    echo ""
    echo -e "${BLUE}=== SUMMARY ===${NC}"
    echo ""
    cat "$output_file"
    echo ""
    echo -e "${GREEN}✓ Summary saved to: $output_file${NC}"
    if [ "$KEEP_TRANSCRIPT" == "true" ]; then
        echo -e "${GREEN}✓ Transcript saved to: $transcript_output${NC}"
    fi
}

# Script entry point
# Check if this is an installation request
if [ "$1" == "--install" ]; then
    install_script "--install"
fi

# Load configuration
load_config

# Parse command line arguments
parse_args "$@"

# Run main process
check_dependencies
validate_input
setup_temp
main