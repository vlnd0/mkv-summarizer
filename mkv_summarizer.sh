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
SAVE_ON_ERROR="${SAVE_ON_ERROR:-false}"  # Default: don't save on error
START_CHUNK_INDEX="${START_CHUNK_INDEX:-0}"  # Default: start from beginning
INIT_TRANSCRIPT_FILE="${INIT_TRANSCRIPT_FILE:-}"  # Default: empty transcript file
CREATE_OUTPUT_DIR="${CREATE_OUTPUT_DIR:-true}"  # Default: create output directory
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

# Save transcript on error (true/false)
SAVE_ON_ERROR=false

# Start chunk index (0 = beginning)
START_CHUNK_INDEX=0

# Initialize transcript from existing file (leave empty for new transcript)
INIT_TRANSCRIPT_FILE=

# Audio quality for extraction (lower = smaller file)
AUDIO_BITRATE=64k

# Chunk duration in seconds (default 20 minutes)
CHUNK_DURATION=1200

# Create output directory for organized file storage (true/false)
CREATE_OUTPUT_DIR=true
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
    SAVE_ON_ERROR="false"
    START_CHUNK_INDEX="0"
    INIT_TRANSCRIPT_FILE=""

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
    SAVE_ON_ERROR="${SAVE_ON_ERROR:-false}"
    START_CHUNK_INDEX="${START_CHUNK_INDEX:-0}"
    INIT_TRANSCRIPT_FILE="${INIT_TRANSCRIPT_FILE:-}"
}

# Help function
show_help() {
    cat << EOF
MKV Video Summarizer
====================

Usage: $(basename $0) [OPTIONS] <video.mkv>

OPTIONS:
    --no-transcript       Don't save the transcript file
    --transcript          Save the transcript file (default)
    --speakers            Enable speaker identification and timestamps
    --no-speakers         Disable speaker identification (default)
    --save-on-error       Save transcript when chunk processing fails
    --no-save-on-error    Don't save on error (default)
    --start-chunk INDEX   Start processing from chunk index (0-based)
    --init-transcript FILE Initialize transcript from existing file
    --create-dir          Create output directory for organized files (default)
    --no-create-dir       Save files in same directory as input video
    --install             Install script system-wide
    --help                Show this help message

ENVIRONMENT:
    OPENAI_API_KEY       Your OpenAI API key
    ANTHROPIC_API_KEY    Your Anthropic API key
    KEEP_TRANSCRIPT      Set to 'false' to disable transcript by default
    ENABLE_SPEAKERS      Set to 'true' to enable speaker diarization by default
    SAVE_ON_ERROR        Set to 'true' to save transcript when chunks fail
    START_CHUNK_INDEX    Set chunk index to start from (0-based)
    INIT_TRANSCRIPT_FILE Path to existing transcript file to initialize from
    CREATE_OUTPUT_DIR    Set to 'false' to disable output directory creation

FILES:
    The summary will be saved as: <video_name>_summary.md (contains Russian summary)
    The transcript (if enabled): <video_name>_transcript.txt (original language transcription)

    By default, files are saved in: <video_name>_summarizer_output/ directory
    Use --no-create-dir to save files in the same directory as the input video

EXAMPLES:
    $(basename $0) movie.mkv
    $(basename $0) --no-transcript lecture.mkv
    $(basename $0) --speakers meeting.mkv
    $(basename $0) --speakers --no-transcript conference.mkv
    $(basename $0) --save-on-error --start-chunk 5 movie.mkv
    $(basename $0) --init-transcript existing_transcript.txt movie.mkv
    $(basename $0) --no-create-dir movie.mkv
    ENABLE_SPEAKERS=true $(basename $0) video.mkv

EOF
    exit 0
}

# Parse arguments
parse_args() {
    KEEP_TRANSCRIPT_ARG=""
    ENABLE_SPEAKERS_ARG=""
    SAVE_ON_ERROR_ARG=""
    START_CHUNK_INDEX_ARG=""
    INIT_TRANSCRIPT_FILE_ARG=""
    CREATE_OUTPUT_DIR_ARG=""
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
            --save-on-error)
                SAVE_ON_ERROR_ARG="true"
                shift
                ;;
            --no-save-on-error)
                SAVE_ON_ERROR_ARG="false"
                shift
                ;;
            --create-dir)
                CREATE_OUTPUT_DIR_ARG="true"
                shift
                ;;
            --no-create-dir)
                CREATE_OUTPUT_DIR_ARG="false"
                shift
                ;;
            --start-chunk)
                if [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                    START_CHUNK_INDEX_ARG="$2"
                    shift 2
                else
                    echo -e "${RED}Error: --start-chunk requires a valid number${NC}"
                    exit 1
                fi
                ;;
            --init-transcript)
                if [ -n "$2" ] && [ -f "$2" ]; then
                    INIT_TRANSCRIPT_FILE_ARG="$(realpath "$2")"
                    shift 2
                else
                    echo -e "${RED}Error: --init-transcript requires a valid existing file path${NC}"
                    exit 1
                fi
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

    if [ ! -z "$SAVE_ON_ERROR_ARG" ]; then
        SAVE_ON_ERROR="$SAVE_ON_ERROR_ARG"
    fi

    if [ ! -z "$START_CHUNK_INDEX_ARG" ]; then
        START_CHUNK_INDEX="$START_CHUNK_INDEX_ARG"
    fi

    if [ ! -z "$INIT_TRANSCRIPT_FILE_ARG" ]; then
        INIT_TRANSCRIPT_FILE="$INIT_TRANSCRIPT_FILE_ARG"
    fi

    if [ ! -z "$CREATE_OUTPUT_DIR_ARG" ]; then
        CREATE_OUTPUT_DIR="$CREATE_OUTPUT_DIR_ARG"
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
        echo -e "${BLUE}Speaker identification enabled - using enhanced prompt for better speaker separation${NC}" >&2
        response=$(curl -s -w "%{http_code}" --request POST \
            --url https://api.openai.com/v1/audio/transcriptions \
            --header "Authorization: Bearer $OPENAI_API_KEY" \
            --header "Content-Type: multipart/form-data" \
            --form "file=@$audio_file" \
            --form "model=whisper-1" \
            --form "response_format=verbose_json" \
            --form "timestamp_granularities[]=segment" \
            --form "prompt=This recording contains multiple speakers. Please separate their speech clearly and identify when different speakers are talking. Include timestamps for each speaker segment to help distinguish between different voices and conversation participants.")
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
        # Parse JSON response and format with enhanced speaker info and timestamps
        local formatted_text=$(echo "$response" | jq -r '
            if .segments then
                .segments[] |
                "TIMESTAMP [" + (.start | floor | tostring) + ":" + ((.start % 60) | floor | tostring | if length == 1 then "0" + . else . end) +
                " - " + (.end | floor | tostring) + ":" + ((.end % 60) | floor | tostring | if length == 1 then "0" + . else . end) + "] " + .text
            else
                .text // "No transcription available"
            end')

        if [ -z "$formatted_text" ] || [ "$formatted_text" == "No transcription available" ]; then
            # Fallback to simple text extraction
            formatted_text=$(echo "$response" | jq -r '.text // "No transcription available"')
        fi

        # Add speaker detection markers and formatting
        echo "=== AUDIO SEGMENT WITH TIMESTAMPS ===" >> "$output_file"
        echo "$formatted_text" >> "$output_file"
        echo "=== END SEGMENT ===" >> "$output_file"

        local word_count=$(echo "$formatted_text" | wc -w)
        echo -e "${GREEN}Transcription with speaker timestamps completed ($word_count words)${NC}" >&2
    else
        # Simple text format
        echo "$response" >> "$output_file"
        local word_count=$(echo "$response" | wc -w)
        echo -e "${GREEN}Transcription completed ($word_count words)${NC}" >&2
    fi
}

# Save current transcript to output location on error
save_transcript_on_error() {
    local transcript_file="$1"
    local output_file="$2"

    if [ "$SAVE_ON_ERROR" == "true" ] && [ -f "$transcript_file" ] && [ -s "$transcript_file" ]; then
        echo -e "${YELLOW}Saving partial transcript due to error...${NC}" >&2
        cp "$transcript_file" "$output_file"
        echo -e "${GREEN}Partial transcript saved to: $output_file${NC}" >&2
    fi
}

# Process all audio chunks
process_chunks() {
    local audio_file="$1"
    local transcript_file="$TEMP_DIR/transcript.txt"
    local output_transcript_file="$2"  # Add parameter for output file path

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

    # Initialize transcript file - either empty or from existing file
    if [ -n "$INIT_TRANSCRIPT_FILE" ] && [ -f "$INIT_TRANSCRIPT_FILE" ]; then
        echo -e "${GREEN}Initializing transcript from existing file: $INIT_TRANSCRIPT_FILE${NC}" >&2
        cp "$INIT_TRANSCRIPT_FILE" "$transcript_file"
        echo -e "\n---\n" >> "$transcript_file"  # Add separator
    else
        > "$transcript_file"  # Clear file
    fi

    local total=${#chunks[@]}
    local current=1
    local start_index=${START_CHUNK_INDEX:-0}

    # Validate start index
    if [ "$start_index" -ge "$total" ]; then
        echo -e "${RED}Error: Start chunk index ($start_index) is greater than total chunks ($total)${NC}" >&2
        return 1
    fi

    if [ "$start_index" -gt 0 ]; then
        echo -e "${YELLOW}Starting from chunk index: $start_index (skipping $start_index chunks)${NC}" >&2
        current=$((start_index + 1))
    fi

    # Process chunks starting from the specified index
    local chunk_index=0
    for chunk in "${chunks[@]}"; do
        # Skip chunks before start index
        if [ "$chunk_index" -lt "$start_index" ]; then
            echo -e "${BLUE}Skipping chunk $((chunk_index+1))/$total${NC}" >&2
            ((chunk_index++))
            continue
        fi

        echo -e "${YELLOW}Processing chunk $current/$total...${NC}" >&2
        echo -e "${BLUE}Chunk file: $chunk${NC}" >&2

        # Verify chunk file exists before transcription
        if [ ! -f "$chunk" ]; then
            echo -e "${RED}Error: Chunk file does not exist: $chunk${NC}" >&2
            save_transcript_on_error "$transcript_file" "$output_transcript_file"
            return 1
        fi

        if ! transcribe_audio "$chunk" "$transcript_file"; then
            echo -e "${RED}Failed to transcribe chunk $current/$total${NC}" >&2
            save_transcript_on_error "$transcript_file" "$output_transcript_file"
            return 1
        fi
        echo -e "\n---\n" >> "$transcript_file"
        ((current++))
        ((chunk_index++))
    done

    echo "$transcript_file"
}

# Estimate transcript size in tokens (rough approximation)
estimate_token_count() {
    local text="$1"
    local word_count=$(echo "$text" | wc -w)
    # Rough estimate: 1 token ≈ 0.75 words for Russian/English text
    local estimated_tokens=$(( word_count * 4 / 3 ))
    echo "$estimated_tokens"
}

# Split transcript into chunks for processing
split_transcript_for_claude() {
    local transcript_file="$1"
    local max_words_per_chunk=10000  # Conservative limit for Claude

    echo -e "${BLUE}Splitting transcript for Claude processing...${NC}" >&2
    
    # Create chunks directory
    local chunks_dir="$TEMP_DIR/transcript_chunks"
    mkdir -p "$chunks_dir"

    # Split transcript by word count, preserving sentence boundaries
    local chunk_num=0
    local current_chunk=""
    local current_word_count=0
    local chunks=()

    # Read transcript and split into sentences
    while IFS= read -r line; do
        # Skip empty lines and separators
        if [[ -z "$line" || "$line" == "---" ]]; then
            continue
        fi

        local line_word_count=$(echo "$line" | wc -w)

        # If adding this line would exceed limit, save current chunk
        if [ $((current_word_count + line_word_count)) -gt $max_words_per_chunk ] && [ -n "$current_chunk" ]; then
            local chunk_file="$chunks_dir/chunk_$chunk_num.txt"
            echo "$current_chunk" > "$chunk_file"
            chunks+=("$chunk_file")
            echo -e "  Created chunk $((chunk_num + 1)): $current_word_count words" >&2

            current_chunk="$line"
            current_word_count=$line_word_count
            ((chunk_num++))
        else
            # Add line to current chunk
            if [ -n "$current_chunk" ]; then
                current_chunk="$current_chunk"$'\n'"$line"
            else
                current_chunk="$line"
            fi
            current_word_count=$((current_word_count + line_word_count))
        fi
    done < "$transcript_file"

    # Save the last chunk if it has content
    if [ -n "$current_chunk" ]; then
        local chunk_file="$chunks_dir/chunk_$chunk_num.txt"
        echo "$current_chunk" > "$chunk_file"
        chunks+=("$chunk_file")
        echo -e "  Created chunk $((chunk_num + 1)): $current_word_count words" >&2
    fi

    echo -e "${GREEN}Created ${#chunks[@]} transcript chunks${NC}" >&2
    printf '%s\n' "${chunks[@]}"
}

# Summarize a single transcript chunk with Claude
summarize_chunk_with_claude() {
    local chunk_file="$1"
    local chunk_num="$2"
    local total_chunks="$3"

    local transcript_chunk=$(cat "$chunk_file" | jq -Rs .)

    # Detect if this is a multi-speaker transcript
    local speaker_context=""
    if echo "$transcript_chunk" | grep -q "TIMESTAMP\|===.*SEGMENT"; then
        speaker_context="This transcript contains multiple speakers with timestamps. "
    fi

    # Create chunk-specific prompt
    local chunk_prompt="You are analyzing part $chunk_num of $total_chunks from a video transcript. ${speaker_context}Please provide a summary IN RUSSIAN:

For this chunk, provide:
1. SUMMARY of this part (КРАТКОЕ ИЗЛОЖЕНИЕ ЧАСТИ)
2. KEY POINTS from this section (КЛЮЧЕВЫЕ МОМЕНТЫ)
3. MAIN TOPICS in this part (ОСНОВНЫЕ ТЕМЫ)
$(if [ -n "$speaker_context" ]; then echo "4. SPEAKER INSIGHTS - key points for each speaker if distinguishable (ОСНОВНЫЕ ИДЕИ ПО СПИКЕРАМ)"; fi)

Here is the transcript chunk:

$transcript_chunk

Please format your response clearly. IMPORTANT: Provide the summary entirely in Russian, regardless of the original transcript language. $(if [ -n "$speaker_context" ]; then echo "If multiple speakers are present, try to identify their main contributions and perspectives."; fi)"

    # Create request body
    local request_body=$(jq -n \
        --arg content "$chunk_prompt" \
        '{
            model: "claude-3-5-sonnet-20241022",
            max_tokens: 8000,
            messages: [
                {
                    role: "user",
                    content: $content
                }
            ]
        }')

    echo -e "${BLUE}Processing chunk $chunk_num/$total_chunks with Claude...${NC}"

    # Make API call with retry logic
    local max_retries=3
    local retry_count=0
    local response=""

    while [ $retry_count -lt $max_retries ]; do
        response=$(curl -s --request POST \
            --url https://api.anthropic.com/v1/messages \
            --header "x-api-key: $ANTHROPIC_API_KEY" \
            --header "anthropic-version: 2023-06-01" \
            --header "content-type: application/json" \
            --data "$request_body")

        # Check for rate limit error
        if echo "$response" | grep -q "rate_limit_error"; then
            retry_count=$((retry_count + 1))
            local wait_time=$((retry_count * 30))  # Exponential backoff: 30s, 60s, 90s
            echo -e "${YELLOW}Rate limit hit. Waiting ${wait_time}s before retry ${retry_count}/${max_retries}...${NC}"
            sleep $wait_time
            continue
        fi

        # Check for successful response
        local chunk_summary=$(echo "$response" | jq -r '.content[0].text // empty')
        if [ -n "$chunk_summary" ]; then
            echo "$chunk_summary"
            return 0
        else
            retry_count=$((retry_count + 1))
            echo -e "${YELLOW}Empty response, retrying ${retry_count}/${max_retries}...${NC}"
            sleep 10
        fi
    done

    # All retries failed
    echo -e "${RED}Error: Failed to process chunk $chunk_num after $max_retries attempts${NC}"
    echo "Response: $response"
    return 1
}

# Combine chunk summaries into final summary
combine_chunk_summaries() {
    local summaries=("$@")
    local combined_file="$TEMP_DIR/combined_summary.txt"

    # Combine all chunk summaries
    {
        echo "# Анализ по частям"
        echo ""
        for i in "${!summaries[@]}"; do
            echo "## Часть $((i + 1))"
            echo ""
            echo "${summaries[i]}"
            echo ""
            echo "---"
            echo ""
        done
    } > "$combined_file"

    # Detect if this involves multiple speakers by checking combined summaries
    local speaker_synthesis=""
    if grep -q "СПИКЕРАМ\|SPEAKER" "$combined_file"; then
        speaker_synthesis="5. SPEAKER ANALYSIS - synthesis of different speakers' contributions, roles, and key insights if multiple speakers were identified (АНАЛИЗ УЧАСТНИКОВ)"
    fi

    # Create final synthesis prompt
    local synthesis_prompt="Based on the following partial summaries of a video, create a comprehensive final summary IN RUSSIAN:

1. COMPREHENSIVE SUMMARY of the entire content (ОБЩЕЕ РЕЗЮМЕ)
2. KEY POINTS from all parts (КЛЮЧЕВЫЕ МОМЕНТЫ)
3. MAIN TOPICS discussed throughout (ОСНОВНЫЕ ТЕМЫ)
4. ACTION ITEMS or important conclusions (ПЛАН ДЕЙСТВИЙ)
$(if [ -n "$speaker_synthesis" ]; then echo "$speaker_synthesis"; fi)

Here are the partial summaries:

$(cat "$combined_file" | jq -Rs .)

Please create a coherent, comprehensive summary that synthesizes all the information. IMPORTANT: Provide the final summary entirely in Russian.$(if [ -n "$speaker_synthesis" ]; then echo " If multiple speakers were identified across the parts, provide insights about each speaker's main contributions, whether this was a meeting, discussion, interview, or other type of conversation."; fi)"

    # Create synthesis request
    local synthesis_request=$(jq -n \
        --arg content "$synthesis_prompt" \
        '{
            model: "claude-3-5-sonnet-20241022",
            max_tokens: 8000,
            messages: [
                {
                    role: "user",
                    content: $content
                }
            ]
        }')

    echo -e "${GREEN}Creating final comprehensive summary...${NC}"

    # Make synthesis API call with retry
    local max_retries=3
    local retry_count=0
    local response=""

    while [ $retry_count -lt $max_retries ]; do
        response=$(curl -s --request POST \
            --url https://api.anthropic.com/v1/messages \
            --header "x-api-key: $ANTHROPIC_API_KEY" \
            --header "anthropic-version: 2023-06-01" \
            --header "content-type: application/json" \
            --data "$synthesis_request")

        # Check for rate limit error
        if echo "$response" | grep -q "rate_limit_error"; then
            retry_count=$((retry_count + 1))
            local wait_time=$((retry_count * 30))
            echo -e "${YELLOW}Rate limit hit. Waiting ${wait_time}s before final synthesis retry ${retry_count}/${max_retries}...${NC}"
            sleep $wait_time
            continue
        fi

        # Check for successful response
        local final_summary=$(echo "$response" | jq -r '.content[0].text // empty')
        if [ -n "$final_summary" ]; then
            echo "$final_summary"
            return 0
        else
            retry_count=$((retry_count + 1))
            echo -e "${YELLOW}Empty synthesis response, retrying ${retry_count}/${max_retries}...${NC}"
            sleep 10
        fi
    done

    # Synthesis failed, return combined summaries as fallback
    echo -e "${YELLOW}Synthesis failed, using combined chunk summaries${NC}"
    cat "$combined_file"
}

# Summarize with Claude (Russian only) - Updated with chunking
summarize_with_claude() {
    local transcript_file="$1"
    local output_file="$2"

    echo -e "${GREEN}Generating Russian summary with Claude...${NC}"

    # Check transcript size
    local transcript_text=$(cat "$transcript_file")
    local word_count=$(echo "$transcript_text" | wc -w)
    local estimated_tokens=$(estimate_token_count "$transcript_text")

    echo -e "${BLUE}Transcript size: $word_count words (~$estimated_tokens tokens)${NC}"

    # If transcript is small enough, use original approach
    if [ "$estimated_tokens" -le 20000 ]; then
        echo -e "${GREEN}Transcript is small enough for single request${NC}"

        # Detect if this is a multi-speaker transcript
        local speaker_context=""
        local speaker_section=""
        if echo "$transcript_text" | grep -q "TIMESTAMP\|===.*SEGMENT"; then
            speaker_context="This transcript contains multiple speakers with timestamps. "
            speaker_section="5. SPEAKER ANALYSIS - key insights from each speaker if multiple speakers are identifiable (АНАЛИЗ УЧАСТНИКОВ)"
        fi

        local transcript_escaped=$(echo "$transcript_text" | jq -Rs .)
        local prompt="You are analyzing a transcript from a video. ${speaker_context}Please provide a summary IN RUSSIAN:

1. A comprehensive SUMMARY of the entire conversation/content (КРАТКОЕ ИЗЛОЖЕНИЕ)
2. KEY POINTS (bullet points of the most important information) (КЛЮЧЕВЫЕ МОМЕНТЫ)
3. MAIN TOPICS discussed (ОСНОВНЫЕ ТЕМЫ)
4. Any ACTION ITEMS or important conclusions (ПЛАН ДЕЙСТВИЙ)
$(if [ -n "$speaker_section" ]; then echo "$speaker_section"; fi)

Here is the transcript:

$transcript_escaped

Please format your response in clear sections with headers. IMPORTANT: Provide the summary entirely in Russian, regardless of the original transcript language.$(if [ -n "$speaker_context" ]; then echo " If multiple speakers are present, identify their roles and main contributions (e.g., if this is a daily standup, meeting, interview, etc.)."; fi)"

        local request_body=$(jq -n \
            --arg content "$prompt" \
            '{
                model: "claude-3-5-sonnet-20241022",
                max_tokens: 8000,
                messages: [
                    {
                        role: "user",
                        content: $content
                    }
                ]
            }')

        # Make API call with retry logic
        local max_retries=3
        local retry_count=0

        while [ $retry_count -lt $max_retries ]; do
            local response=$(curl -s --request POST \
                --url https://api.anthropic.com/v1/messages \
                --header "x-api-key: $ANTHROPIC_API_KEY" \
                --header "anthropic-version: 2023-06-01" \
                --header "content-type: application/json" \
                --data "$request_body")

            # Check for rate limit error
            if echo "$response" | grep -q "rate_limit_error"; then
                retry_count=$((retry_count + 1))
                local wait_time=$((retry_count * 60))  # 60s, 120s, 180s
                echo -e "${YELLOW}Rate limit hit. Waiting ${wait_time}s before retry ${retry_count}/${max_retries}...${NC}"
                sleep $wait_time
                continue
            fi

            local summary=$(echo "$response" | jq -r '.content[0].text // empty')
            if [ -n "$summary" ]; then
                {
                    echo "# Резюме видео"
                    echo ""
                    echo "$summary"
                } > "$output_file"
                echo -e "${GREEN}Russian summary generated successfully${NC}"
                return 0
            else
                retry_count=$((retry_count + 1))
                echo -e "${YELLOW}Empty response, retrying ${retry_count}/${max_retries}...${NC}"
                sleep 15
            fi
        done

        echo -e "${RED}Error: Summary generation failed after $max_retries attempts${NC}"
        echo "Response: $response"
        return 1
    else
        # Use chunked approach for large transcripts
        echo -e "${YELLOW}Large transcript detected, using chunked processing${NC}"

        # Split transcript into chunks
        local chunks=()
        while IFS= read -r line; do
            [ -n "$line" ] && chunks+=("$line")
        done < <(split_transcript_for_claude "$transcript_file")

        if [ ${#chunks[@]} -eq 0 ]; then
            echo -e "${RED}Error: No transcript chunks created${NC}"
            return 1
        fi

        # Process each chunk
        local chunk_summaries=()
        for i in "${!chunks[@]}"; do
            local chunk_summary
            if chunk_summary=$(summarize_chunk_with_claude "${chunks[i]}" "$((i + 1))" "${#chunks[@]}"); then
                chunk_summaries+=("$chunk_summary")
                # Add delay between requests to avoid rate limits
                if [ $((i + 1)) -lt ${#chunks[@]} ]; then
                    echo -e "${BLUE}Waiting 15s between chunks to avoid rate limits...${NC}"
                    sleep 15
                fi
            else
                echo -e "${RED}Failed to process chunk $((i + 1))${NC}"
                return 1
            fi
        done

        # Combine summaries into final result
        local final_summary
        if final_summary=$(combine_chunk_summaries "${chunk_summaries[@]}"); then
            {
                echo "# Резюме видео"
                echo ""
                echo "$final_summary"
            } > "$output_file"
            echo -e "${GREEN}Chunked Russian summary generated successfully${NC}"
            return 0
        else
            echo -e "${RED}Error: Failed to create final summary${NC}"
            return 1
        fi
    fi
}

# Main execution
main() {
    # Get absolute path and directory of input file
    local input_file=$(realpath "$INPUT_FILE")
    local input_dir=$(dirname "$input_file")
    local base_name=$(basename "$input_file" .mkv)

    # Determine output directory based on CREATE_OUTPUT_DIR setting
    local output_dir="$input_dir"
    if [ "$CREATE_OUTPUT_DIR" == "true" ]; then
        output_dir="$input_dir/${base_name}_summarizer_output"
        echo -e "${GREEN}Creating output directory: $output_dir${NC}"
        mkdir -p "$output_dir"
    fi

    # Output files
    local output_file="$output_dir/${base_name}_summary.md"
    local transcript_output="$output_dir/${base_name}_transcript.txt"

    echo -e "${BLUE}=== MKV Video Summarizer ===${NC}"
    echo -e "Processing: $input_file"
    echo -e "Output directory: $output_dir"
    echo -e "Transcript: $([ "$KEEP_TRANSCRIPT" == "true" ] && echo "Yes" || echo "No")"
    echo -e "Speaker identification: $([ "$ENABLE_SPEAKERS" == "true" ] && echo "Yes" || echo "No")"
    echo -e "Save on error: $([ "$SAVE_ON_ERROR" == "true" ] && echo "Yes" || echo "No")"
    if [ "$START_CHUNK_INDEX" -gt 0 ]; then
        echo -e "Start chunk index: $START_CHUNK_INDEX"
    fi
    if [ -n "$INIT_TRANSCRIPT_FILE" ]; then
        echo -e "Initialize from: $INIT_TRANSCRIPT_FILE"
    fi
    echo ""

    # Extract audio
    audio_file=$(extract_audio "$input_file")

    # Transcribe
    transcript_file=$(process_chunks "$audio_file" "$transcript_output")

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