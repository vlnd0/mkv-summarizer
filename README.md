# MKV Summarizer

An AI-powered video summarization tool that extracts audio from MKV files, transcribes it using OpenAI's Whisper, and generates intelligent summaries using Anthropic's Claude.

## Features

- 🎬 **Video Processing**: Extracts audio from MKV video files using FFmpeg
- 🎵 **Smart Chunking**: Automatically splits long audio into 20-minute chunks for API limits
- 🗣️ **AI Transcription**: Uses OpenAI Whisper for accurate speech-to-text conversion
- 👥 **Speaker Detection**: Advanced speaker identification and separation with timestamps
- 🤖 **Intelligent Summarization**: Leverages Claude AI for structured, comprehensive summaries with speaker analysis
- 📄 **Smart Transcript Processing**: Automatic chunking for large transcripts with intelligent token management
- 🔄 **Robust Error Handling**: Retry logic with exponential backoff for API rate limits
- 📝 **Flexible Output**: Optional transcript saving with configurable retention
- ⚙️ **System Integration**: Self-installing script with system-wide availability
- 🔧 **Configurable**: Customizable audio quality, chunk duration, and processing options

## Quick Start

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vlnd0/mkv-summarizer.git
   cd mkv-summarizer
   ```

2. **Install system-wide:**
   ```bash
   ./mkv_summarizer.sh --install
   ```

3. **Set up API keys:**
   Edit `~/.config/mkv-summarizer/config` or export environment variables:
   ```bash
   export OPENAI_API_KEY="your-openai-api-key"
   export ANTHROPIC_API_KEY="your-anthropic-api-key"
   ```

### Basic Usage

```bash
# Process a video file (saves transcript)
mkv-summarize video.mkv

# Process without saving transcript
mkv-summarize --no-transcript video.mkv

# Show help
mkv-summarize --help
```

## Prerequisites

### System Dependencies

The following tools must be installed on your system:

- **FFmpeg** - Video/audio processing
- **curl** - API communication
- **jq** - JSON processing

#### macOS Installation:
```bash
brew install ffmpeg curl jq
```

#### Ubuntu/Debian Installation:
```bash
sudo apt update
sudo apt install ffmpeg curl jq
```

#### Arch Linux Installation:
```bash
sudo pacman -S ffmpeg curl jq
```

### API Keys

You'll need API keys from:

1. **OpenAI** - For Whisper transcription service
   - Sign up at [OpenAI](https://openai.com/)
   - Create an API key in your dashboard

2. **Anthropic** - For Claude summarization service
   - Sign up at [Anthropic](https://anthropic.com/)
   - Generate an API key in your console

## Configuration

### Configuration File

After installation, edit `~/.config/mkv-summarizer/config`:

```bash
# MKV Summarizer Configuration

# OpenAI API Key for Whisper transcription
OPENAI_API_KEY="your-openai-key-here"

# Anthropic API Key for Claude summarization
ANTHROPIC_API_KEY="your-anthropic-key-here"

# Keep transcript file (true/false)
KEEP_TRANSCRIPT=true

# Enable speaker identification and timestamps (true/false)
# When enabled, provides enhanced transcription with speaker separation and timing
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
```

### Environment Variables

Alternatively, set environment variables:

All configuration options can be overridden with environment variables:

```bash
export OPENAI_API_KEY="your-openai-api-key"
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export KEEP_TRANSCRIPT=true
export ENABLE_SPEAKERS=false
export SAVE_ON_ERROR=false
export START_CHUNK_INDEX=0
export INIT_TRANSCRIPT_FILE=""
export AUDIO_BITRATE=64k
export CHUNK_DURATION=1200
```

### Configuration Priority
1. Command-line arguments (highest priority)
2. Environment variables
3. Configuration file settings
4. Built-in defaults (lowest priority)

## How It Works

1. **Audio Extraction**: FFmpeg extracts MP3 audio from the input MKV file
2. **Duration Check**: Calculates total audio duration for processing planning
3. **Smart Chunking**: Splits audio into 20-minute chunks to respect API limits
4. **Enhanced Transcription**: Each chunk is processed through OpenAI's Whisper API with optional speaker detection
5. **Speaker Analysis**: When enabled, applies enhanced prompts for better speaker separation and timestamps
6. **Consolidation**: All transcripts are combined into a single document with speaker markers
7. **Intelligent Processing**: Automatically detects large transcripts (>20K tokens) and applies chunked processing
8. **Multi-Speaker Summarization**: Uses either single-request or multi-chunk approach with Claude AI, intelligently detecting and analyzing speaker contributions
9. **Output**: Generates a comprehensive markdown summary with speaker insights and optionally saves the transcript

## Command Line Options

### Core Operations
| Option | Description |
|--------|-------------|
| `--install` | Install script system-wide to `/usr/local/bin/mkv-summarize` |
| `--help`, `-h` | Display comprehensive help information |

### Transcript Management
| Option | Description |
|--------|-------------|
| `--transcript` | Save the transcript file (default behavior) |
| `--no-transcript` | Process video without saving transcript file |

### Speaker Features
| Option | Description |
|--------|-------------|
| `--speakers` | Enable speaker identification, timestamps, and enhanced summarization for multi-speaker content |
| `--no-speakers` | Disable speaker identification (default) |

### Error Recovery Options
| Option | Description |
|--------|-------------|
| `--save-on-error` | Save partial transcript when chunk processing fails |
| `--no-save-on-error` | Don't save transcript on error (default) |
| `--start-chunk INDEX` | Resume processing from specific chunk index (0-based) |
| `--init-transcript FILE` | Initialize transcript from existing file path |

## Usage Examples

### Basic Processing
```bash
# Simple processing with default settings
mkv-summarize presentation.mkv

# Process without saving transcript
mkv-summarize --no-transcript lecture.mkv

# Enable speaker identification for meetings/conversations
mkv-summarize --speakers meeting.mkv

# Combined processing with speaker detection and transcript saving
mkv-summarize --speakers --transcript conference.mkv
```

### Advanced Processing Options
```bash
# Resume processing from chunk 5 after interruption
mkv-summarize --start-chunk 5 --save-on-error large_file.mkv

# Continue processing with existing transcript
mkv-summarize --init-transcript partial_transcript.txt video.mkv

# Full feature processing
mkv-summarize --speakers --save-on-error --transcript conference.mkv
```

### Environment Variable Usage
```bash
# Override default settings with environment variables
ENABLE_SPEAKERS=true KEEP_TRANSCRIPT=false mkv-summarize video.mkv

# Process with custom chunk settings
CHUNK_DURATION=1800 START_CHUNK_INDEX=3 mkv-summarize video.mkv
```

### Speaker Detection Best Practices

**When to Enable Speaker Detection:**
- Multi-person meetings, interviews, or discussions
- Conference calls, presentations with Q&A
- Podcasts, webinars, or panel discussions
- Any video with multiple participants speaking

**Optimal Use Cases:**
```bash
# Team meetings and standups
mkv-summarize --speakers daily_standup.mkv

# Interview recordings
mkv-summarize --speakers --transcript interview.mkv

# Conference sessions with multiple speakers
mkv-summarize --speakers conference_panel.mkv

# Training sessions with instructor and participants
mkv-summarize --speakers training_session.mkv
```

**Expected Benefits:**
- Better transcription accuracy for multi-speaker content
- Automatic identification of speaker roles and contributions
- Enhanced summaries with per-speaker insights
- Context-aware analysis (meeting types, discussion patterns)

## Output Files

The tool generates files in the same directory as the input video:

- `{filename}_summary.md` - AI-generated summary in markdown format with speaker analysis (when enabled)
- `{filename}_transcript.txt` - Full transcript with speaker timestamps (if `KEEP_TRANSCRIPT=true`)

### Speaker Detection Output

When speaker detection is enabled (`--speakers` or `ENABLE_SPEAKERS=true`), the output includes:

**Enhanced Transcripts:**
- Timestamped segments with precise timing (MM:SS format)
- Speaker separation markers for better readability
- Improved transcription quality through enhanced prompts

**Intelligent Summaries:**
- **Speaker Analysis**: Individual speaker insights and contributions
- **Role Identification**: Automatic detection of meeting types (daily standup, interview, etc.)
- **Key Contributions**: Highlights what each speaker discussed
- **Context Detection**: Identifies conversation type and participant roles

## Architecture

### Core Components

- **Audio Processing**: FFmpeg integration for format conversion and chunking
- **API Integration**: RESTful communication with OpenAI and Anthropic services
- **Error Handling**: Comprehensive validation and cleanup mechanisms
- **Configuration Management**: Flexible config file and environment variable support

### Enhanced Processing Features

#### Intelligent Transcript Chunking
- **Automatic Detection**: Analyzes transcript size and applies appropriate processing strategy
- **Token Estimation**: Smart calculation of approximate token count for optimization
- **Chunk Management**: Splits large transcripts while preserving sentence boundaries
- **Progress Tracking**: Real-time feedback during multi-chunk processing

#### Robust Error Handling
- **Rate Limit Management**: Automatic detection and handling of API rate limits
- **Exponential Backoff**: Smart retry timing (30s, 60s, 90s) to prevent API overload  
- **Failure Recovery**: Graceful handling of individual chunk failures
- **Progress Preservation**: Maintains processing state across retries

#### Processing Strategies
- **Small Transcripts** (<20K tokens): Single-request processing for optimal speed
- **Large Transcripts** (>20K tokens): Multi-chunk processing with synthesis
- **Chunk Processing**: Individual summarization with final comprehensive synthesis
- **Quality Assurance**: Validates successful processing at each stage

### Processing Flow

```
MKV File → Audio Extraction → Chunking → Enhanced Transcription → Transcript Analysis → Summarization → Output
    ↓           ↓              ↓              ↓                        ↓              ↓            ↓
  FFmpeg    MP3 Format    20min chunks   Whisper API             Token Count    Claude API   Markdown
                                           ↓                          ↓              ↓
                                    Speaker Detection           Single Request ← Small (<20K tokens)
                                      (Optional)                     OR
                                    ↓                         Chunked Processing ← Large (>20K tokens)
                               Enhanced Prompts                      ↓
                               Timestamps                     Speaker Analysis
                               Speaker Markers                (When Enabled)
```

## API Usage & Costs

### OpenAI Whisper
- Model: `whisper-1` (with enhanced speaker prompts when enabled)
- Pricing: ~$0.006 per minute of audio
- Rate limits: Handled by chunking strategy
- Speaker Features: Enhanced prompts for multi-speaker identification and separation

### Anthropic Claude
- Model: `claude-3-5-sonnet-20241022`
- Pricing: Based on token usage (~$3 per million input tokens)
- Context: Optimized for comprehensive document analysis
- Smart Processing: Automatically switches between single-request and chunked processing
- Speaker Analysis: Enhanced prompts for multi-speaker conversation analysis
- Rate Limiting: Built-in retry logic with exponential backoff for reliability

## Troubleshooting

### Common Issues

**"Command not found" error:**
```bash
# Ensure the script is executable and in PATH
chmod +x mkv_summarizer.sh
./mkv_summarizer.sh --install
```

**FFmpeg not found:**
```bash
# Install FFmpeg using your package manager
brew install ffmpeg  # macOS
sudo apt install ffmpeg  # Ubuntu/Debian
```

**API key errors:**
- Verify your API keys are correctly set in the config file
- Check that you have sufficient credits in both OpenAI and Anthropic accounts
- Ensure the keys have the necessary permissions

**Large file processing:**
- The tool automatically chunks long audio files (20-minute segments)
- Large transcripts (>20K tokens) are automatically processed in chunks
- Built-in rate limit handling with automatic retries and delays
- Very large files may take considerable time and cost
- Consider the 20-minute chunk duration setting for optimization

**Rate limit errors:**
- The tool includes automatic retry logic for API rate limits
- Exponential backoff strategy prevents overwhelming the APIs
- Progress is maintained across retries and chunk processing
- Large transcripts are processed with delays between chunks

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/vlnd0/mkv-summarizer/issues) page
2. Create a new issue with detailed information about your problem
3. Include your system information and error messages

## Acknowledgments

- **OpenAI** - For the Whisper speech recognition API
- **Anthropic** - For the Claude AI summarization service
- **FFmpeg** - For powerful multimedia processing capabilities