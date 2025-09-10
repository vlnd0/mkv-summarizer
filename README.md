# MKV Summarizer

An AI-powered video summarization tool that extracts audio from MKV files, transcribes it using OpenAI's Whisper, and generates intelligent summaries using Anthropic's Claude.

## Features

- 🎬 **Video Processing**: Extracts audio from MKV video files using FFmpeg
- 🎵 **Smart Chunking**: Automatically splits long audio into 20-minute chunks for API limits
- 🗣️ **AI Transcription**: Uses OpenAI Whisper for accurate speech-to-text conversion
- 🤖 **Intelligent Summarization**: Leverages Claude AI for structured, comprehensive summaries
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
ENABLE_SPEAKERS=false

# Audio quality for extraction (lower = smaller file)
AUDIO_BITRATE=64k

# Chunk duration in seconds (default 20 minutes)
CHUNK_DURATION=1200
```

### Environment Variables

Alternatively, set environment variables:

```bash
export OPENAI_API_KEY="your-openai-api-key"
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export KEEP_TRANSCRIPT=true
export ENABLE_SPEAKERS=false
```

## How It Works

1. **Audio Extraction**: FFmpeg extracts MP3 audio from the input MKV file
2. **Duration Check**: Calculates total audio duration for processing planning
3. **Smart Chunking**: Splits audio into 20-minute chunks to respect API limits
4. **Transcription**: Each chunk is processed through OpenAI's Whisper API
5. **Consolidation**: All transcripts are combined into a single document
6. **Summarization**: The complete transcript is sent to Claude for AI summarization
7. **Output**: Generates a markdown summary file and optionally saves the transcript

## Command Options

| Option | Description |
|--------|-------------|
| `--install` | Install script system-wide to `/usr/local/bin/mkv-summarize` |
| `--no-transcript` | Process video without saving transcript file |
| `--help` | Display help information |

## Output Files

The tool generates files in the same directory as the input video:

- `{filename}_summary.md` - AI-generated summary in markdown format
- `{filename}_transcript.txt` - Full transcript (if `KEEP_TRANSCRIPT=true`)

## Architecture

### Core Components

- **Audio Processing**: FFmpeg integration for format conversion and chunking
- **API Integration**: RESTful communication with OpenAI and Anthropic services
- **Error Handling**: Comprehensive validation and cleanup mechanisms
- **Configuration Management**: Flexible config file and environment variable support

### Processing Flow

```
MKV File → Audio Extraction → Chunking → Transcription → Summarization → Output
    ↓           ↓              ↓           ↓             ↓            ↓
  FFmpeg    MP3 Format    20min chunks   Whisper API   Claude API   Markdown
```

## API Usage & Costs

### OpenAI Whisper
- Model: `whisper-1`
- Pricing: ~$0.006 per minute of audio
- Rate limits: Handled by chunking strategy

### Anthropic Claude
- Model: `claude-3-5-sonnet-20241022`
- Pricing: Based on token usage
- Context: Optimized for comprehensive document analysis

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
- The tool automatically chunks long audio files
- Very large files may take considerable time and cost
- Consider the 20-minute chunk duration setting for optimization

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