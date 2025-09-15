# MKV Summarizer

An AI-powered video summarization tool that extracts audio from MKV files, transcribes it using OpenAI's Whisper, and generates intelligent summaries using Anthropic's Claude.

## Features

- 🎬 **Video Processing**: Extracts audio from MKV video files using FFmpeg
- 🎵 **Smart Chunking**: Automatically splits long audio into 20-minute chunks for API limits
- 🗣️ **AI Transcription**: Uses OpenAI Whisper for accurate speech-to-text conversion
- 👥 **Speaker Detection**: Advanced speaker identification and separation with timestamps
- 🤖 **Intelligent Summarization**: Leverages Claude AI for structured, comprehensive summaries with speaker analysis
- 🎯 **Context-Aware Processing**: Custom prompts for enhanced summarization based on meeting types and technical contexts
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

# Custom prompt for better context (e.g., "This is a daily standup meeting" or "This is a technical interview")
CUSTOM_PROMPT=
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
export CUSTOM_PROMPT=""
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
7. **Context Integration**: Custom prompts are integrated into summarization requests for domain-specific analysis
8. **Intelligent Processing**: Automatically detects large transcripts (>20K tokens) and applies chunked processing
9. **Context-Aware Summarization**: Uses either single-request or multi-chunk approach with Claude AI, incorporating custom context for enhanced technical and business insights
10. **Output**: Generates a comprehensive markdown summary with speaker insights, technical decisions, and context-specific analysis, optionally saves the transcript

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

### Context Enhancement
| Option | Description |
|--------|-------------|
| `--custom-prompt TEXT` | Add custom context for enhanced summarization (e.g., meeting type, technical context) |

### Error Recovery Options
| Option | Description |
|--------|-------------|
| `--save-on-error` | Save partial transcript when chunk processing fails |
| `--no-save-on-error` | Don't save transcript on error (default) |
| `--start-chunk INDEX` | Resume processing from specific chunk index (0-based) |
| `--init-transcript FILE` | Initialize transcript from existing file path |

## Usage Examples

### Engineering Management Workflows

#### Daily Operations & Team Management
```bash
# Daily standup meetings - extract action items and blockers
mkv-summarize --speakers --custom-prompt "This is a daily standup meeting with engineering team discussing sprint progress, blockers, and daily goals" standup_2024_01_15.mkv

# Sprint planning sessions - capture story estimations and technical decisions
mkv-summarize --speakers --custom-prompt "This is a sprint planning meeting where the team is estimating user stories, discussing technical approach, and planning the upcoming sprint" sprint_planning_q1.mkv

# Sprint retrospectives - identify process improvements and team dynamics
mkv-summarize --speakers --custom-prompt "This is a sprint retrospective meeting where the team discusses what went well, what didn't work, and process improvements for the next sprint" retro_sprint_24.mkv

# One-on-one meetings - track career development and performance discussions
mkv-summarize --speakers --custom-prompt "This is a one-on-one meeting between an engineering manager and team member discussing career development, performance feedback, and goal setting" 1on1_john_q1.mkv
```

#### Cross-Functional Collaboration
```bash
# Product planning meetings - capture feature requirements and technical constraints
mkv-summarize --speakers --custom-prompt "This is a product planning meeting with engineering, product, and design teams discussing feature requirements, technical feasibility, and roadmap priorities" product_planning_q2.mkv

# Architecture review meetings - document technical decisions and trade-offs
mkv-summarize --speakers --custom-prompt "This is an architecture review meeting where senior engineers discuss system design, technical trade-offs, scalability concerns, and implementation approaches" arch_review_microservices.mkv

# Cross-team coordination meetings - track dependencies and integration points
mkv-summarize --speakers --custom-prompt "This is a cross-team coordination meeting discussing API contracts, service dependencies, integration timelines, and potential blocking issues" integration_sync_week12.mkv

# Technical debt planning - prioritize refactoring and infrastructure improvements
mkv-summarize --speakers --custom-prompt "This is a technical debt planning meeting where the team discusses code quality issues, infrastructure improvements, and refactoring priorities" tech_debt_q1_planning.mkv
```

#### Technical Interviews & Knowledge Sharing
```bash
# Technical interviews - extract candidate assessment and decision factors
mkv-summarize --speakers --custom-prompt "This is a technical interview with a senior software engineer candidate discussing system design, coding skills, and technical leadership experience" interview_sarah_senior_eng.mkv

# Tech talks and presentations - capture key concepts and learnings
mkv-summarize --custom-prompt "This is a technical presentation about microservices architecture, covering design patterns, best practices, and real-world implementation challenges" tech_talk_microservices.mkv

# Knowledge sharing sessions - document team learning and best practices
mkv-summarize --speakers --custom-prompt "This is a knowledge sharing session where a team member presents learnings from a recent project, including technical challenges and solutions" knowledge_share_redis_optimization.mkv

# Code review sessions - capture feedback patterns and learning opportunities
mkv-summarize --speakers --custom-prompt "This is a group code review session discussing code quality, design patterns, security considerations, and best practices" code_review_auth_service.mkv
```

#### Incident Response & Post-Mortems
```bash
# Incident response calls - track decisions and action items during outages
mkv-summarize --speakers --custom-prompt "This is an incident response call during a production outage where the team is debugging issues, implementing fixes, and coordinating communication" incident_response_db_outage.mkv

# Post-mortem meetings - extract root causes and prevention strategies
mkv-summarize --speakers --custom-prompt "This is a post-mortem meeting analyzing a production incident, discussing root causes, timeline of events, and preventive measures" postmortem_api_latency.mkv

# War room sessions - document critical decisions during high-priority fixes
mkv-summarize --speakers --custom-prompt "This is a war room session for addressing critical production issues with multiple teams collaborating on diagnosis and resolution" warroom_payment_system.mkv
```

#### Strategic & Leadership Meetings
```bash
# Engineering all-hands - capture organizational updates and strategic direction
mkv-summarize --speakers --custom-prompt "This is an engineering all-hands meeting covering company updates, technical strategy, organizational changes, and team achievements" eng_allhands_q1_2024.mkv

# Technical roadmap planning - document strategic technical decisions
mkv-summarize --speakers --custom-prompt "This is a technical roadmap planning meeting with engineering leadership discussing platform strategy, technology adoption, and long-term architectural goals" tech_roadmap_2024.mkv

# Vendor evaluations - track decision criteria and technical assessments
mkv-summarize --speakers --custom-prompt "This is a vendor evaluation meeting where the team is assessing third-party solutions, comparing technical capabilities, and discussing integration requirements" vendor_eval_monitoring.mkv

# Budget and resource planning - capture technical investment decisions
mkv-summarize --speakers --custom-prompt "This is a budget planning meeting discussing engineering resources, infrastructure costs, tool investments, and headcount allocation" budget_planning_h2.mkv
```

### Advanced Processing Options
```bash
# Large conference sessions with multiple speakers and technical depth
mkv-summarize --speakers --save-on-error --custom-prompt "This is a conference talk about distributed systems architecture with Q&A session covering scalability patterns and microservices design" conference_distributed_systems.mkv

# Training sessions with hands-on components
mkv-summarize --speakers --transcript --custom-prompt "This is a technical training session on Kubernetes deployment strategies with live demos and troubleshooting exercises" k8s_training_advanced.mkv

# Client meetings with technical discussions
mkv-summarize --speakers --custom-prompt "This is a client meeting discussing API integration requirements, technical specifications, and implementation timeline" client_api_integration.mkv
```

### Environment Variable Usage
```bash
# Process multiple files with consistent context
CUSTOM_PROMPT="Daily standup meeting with sprint progress updates" mkv-summarize --speakers standup_*.mkv

# Batch process interview recordings
ENABLE_SPEAKERS=true CUSTOM_PROMPT="Technical interview for senior engineer position" mkv-summarize interview_*.mkv
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

### Custom Prompt Engineering for Engineering Management

**Strategic Prompt Design Principles:**

The `--custom-prompt` feature dramatically enhances AI summarization by providing contextual understanding of your meetings. As an Engineering Manager/Tech Lead, effective prompts should specify:

1. **Meeting Type & Purpose**: Define the specific type of engineering meeting and its primary objectives
2. **Participant Roles**: Identify key stakeholders (engineers, product managers, designers, leadership)
3. **Technical Context**: Specify the technical domain, project phase, or system being discussed
4. **Expected Outcomes**: Clarify what decisions, action items, or insights you're seeking

**Prompt Effectiveness Framework:**

```bash
# High-Impact Template:
--custom-prompt "This is a [MEETING_TYPE] with [PARTICIPANT_ROLES] discussing [TECHNICAL_CONTEXT] where the team is [PRIMARY_OBJECTIVES]"

# Example Implementation:
--custom-prompt "This is a sprint planning meeting with senior engineers and product owner discussing authentication service redesign where the team is estimating complexity, identifying risks, and planning implementation approach"
```

**Engineering Leadership Prompt Library:**

**Team Dynamics & Process:**
- `"Daily standup with distributed team discussing sprint progress, blockers, and cross-team dependencies"`
- `"Sprint retrospective focusing on technical debt, process improvements, and team velocity optimization"`
- `"Agile estimation session for complex backend infrastructure changes with senior engineering team"`

**Technical Architecture & Strategy:**
- `"Architecture design review for microservices migration with principal engineers discussing scalability and performance trade-offs"`
- `"Technical debt prioritization meeting with team leads evaluating refactoring impact and resource allocation"`
- `"System design discussion for high-traffic API service with focus on reliability and monitoring requirements"`

**Cross-Functional Coordination:**
- `"Product planning meeting with engineering, PM, and design discussing feature feasibility, technical constraints, and delivery timeline"`
- `"Cross-team integration sync covering API contracts, service dependencies, and deployment coordination"`
- `"Stakeholder alignment meeting discussing technical roadmap, resource requirements, and strategic priorities"`

**Talent & Development:**
- `"Technical interview for senior software engineer focusing on system design, coding skills, and leadership potential"`
- `"Performance review discussion covering technical growth, project impact, and career development planning"`
- `"Knowledge transfer session where senior engineer shares architectural decisions and implementation learnings"`

**Incident & Operations:**
- `"Post-mortem analysis of production outage covering root cause, timeline reconstruction, and prevention strategies"`
- `"Incident response coordination call with on-call engineers diagnosing and resolving critical system failures"`
- `"Operations review meeting discussing monitoring improvements, alerting optimization, and SLA compliance"`

**Prompt Optimization Tips for Maximum Value:**

1. **Be Specific About Technical Context**: Instead of "meeting about APIs", use "REST API design review for payment processing service"

2. **Include Decision-Making Framework**: Add "where the team is evaluating options and making technical decisions"

3. **Specify Expected Outputs**: Include "covering action items, technical decisions, and next steps"

4. **Mention Key Stakeholders**: "with senior engineers, team leads, and architecture council"

5. **Add Business Context**: "critical for Q2 roadmap delivery" or "required for compliance requirements"

**Context-Aware Summarization Results:**

With properly crafted prompts, the AI will generate summaries that include:
- **Technical Decision Tracking**: Captures architectural choices, technology selections, and trade-off analysis
- **Action Item Extraction**: Identifies specific tasks, owners, and deadlines with technical context
- **Risk Identification**: Highlights technical risks, dependencies, and potential blockers
- **Knowledge Capture**: Documents technical insights, learnings, and best practices shared
- **Process Insights**: Analyzes team dynamics, communication patterns, and process effectiveness

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