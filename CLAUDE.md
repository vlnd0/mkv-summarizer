# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a utilities repository containing an MKV Video Summarizer script (`mkv_summarizer.sh`) that processes video files to generate AI-powered summaries. The tool uses OpenAI's Whisper for transcription and Anthropic's Claude for summarization.

## Key Components

### Core Script: `mkv_summarizer.sh`
- Main entry point for video summarization workflow
- Self-installing bash script that can be deployed system-wide to `/usr/local/bin/mkv-summarize`
- Modular design with separate functions for each processing stage

### Architecture Flow
1. **Audio Extraction**: Uses ffmpeg to extract MP3 audio from MKV files
2. **Audio Chunking**: Splits long audio into 20-minute chunks for API limits
3. **Transcription**: Processes each chunk with OpenAI Whisper API
4. **Summarization**: Sends full transcript to Claude API for structured summary
5. **Output Generation**: Creates markdown summary and optionally saves transcript

### Configuration System
- Config file: `~/.config/mkv-summarizer/config`
- Environment variables override config file settings
- API keys: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`
- Configurable: audio quality, chunk duration, transcript retention

## Development Commands

### Testing the Script
```bash
# Test with a sample MKV file
./mkv_summarizer.sh sample.mkv

# Test without saving transcript
./mkv_summarizer.sh --no-transcript sample.mkv

# Show help and all options
./mkv_summarizer.sh --help
```

### Installation
```bash
# System-wide installation
./mkv_summarizer.sh --install
```

### Dependencies Check
The script validates these dependencies automatically:
- `ffmpeg` - Video/audio processing
- `curl` - API communication
- `jq` - JSON processing

## Code Architecture

### Function Organization
- **Setup Functions**: `install_script()`, `load_config()`, `parse_args()`
- **Validation**: `check_dependencies()`, `validate_input()`
- **Audio Processing**: `extract_audio()`, `split_audio()`, `get_duration()`
- **AI Processing**: `transcribe_audio()`, `summarize_with_claude()`
- **Orchestration**: `main()`, `process_chunks()`

### Error Handling Strategy
- Uses `set -e` for fail-fast behavior
- Color-coded output for different message types
- Comprehensive validation at each processing stage
- Cleanup trap function for temporary files

### API Integration Patterns
- OpenAI Whisper: Multipart form upload with `gpt-4o-mini-transcribe` model
- Anthropic Claude: JSON payload with `claude-3-5-sonnet-20241022` model
- Structured error handling for API failures
- Chunked processing to respect API limits

## Common Modifications

When modifying this script:
- Audio processing parameters are in the configuration section at the top
- API model versions can be updated in the respective function calls
- Chunk duration balances API limits vs. processing efficiency
- The summarization prompt can be customized in `summarize_with_claude()`