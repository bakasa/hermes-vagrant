# Alim Agent — Islamic Studies Companion

> A Hermes Agent for students of the Alimiyyah program. Syncs with Google Classroom, builds a structured knowledge base, and provides scholarly assistance for assignments, tests, and questions.

![Alim Agent](https://img.shields.io/badge/Alim%20Agent-Islamic%20Studies%20Companion-green)
![Port](https://img.shields.io/badge/Port-3005-blue)
![Python](https://img.shields.io/badge/Python-3.12%2B-blue)

## Overview

The **Alim Agent** is an AI-powered study companion designed specifically for students enrolled in the **Alimiyyah program** — the rigorous Islamic studies curriculum that trains well-rounded scholars (*Ulama*). Built on the [Hermes Agent](https://hermes-agent.nousresearch.com/docs) framework by Nous Research, it combines:

- 📚 **Google Classroom Integration** — Automatically syncs courses, announcements, assignments, and materials
- 🧠 **Structured Knowledge Base** — Organizes notes across Islamic disciplines (Aqeedah, Fiqh, Tafsir, Hadith, Seerah, Arabic, and more)
- 📝 **Assignment Assistance** — Helps understand requirements, break down tasks, and structure responses
- 🧪 **Test Preparation** — Generates review sheets, practice questions, and study schedules
- ❓ **Scholarly Q&A** — Answers questions with proper citations, noting scholarly differences of opinion
- 📖 **Glossary** — Maintains a searchable reference of Islamic terminology
- 📊 **Progress Tracking** — Monitors study activity and assignment completion
- 🕌 **Recitation Aid** — Supports Qur'an memorization (Hifz) and classical text review

## Personality

The Alim Agent is **warm, encouraging, and scholarly**. It:

- Uses proper Islamic terminology with English explanations
- Cites sources rigorously (Qur'an, Hadith, classical texts)
- Notes when scholars disagree and presents multiple viewpoints
- **Never fabricates** Qur'anic verses or Hadith
- Encourages understanding over rote memorization
- Reminds about due dates and encourages consistent study
- Maintains the etiquette of seeking knowledge (*Adab al-'Ilm*)

## Quick Start

### Prerequisites

- Python 3.12+
- A Google Cloud project with the Classroom API enabled
- An [OpenRouter](https://openrouter.ai/) API key

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/hermes-alim.git
cd hermes-alim

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy and edit configuration
cp config.yaml.example config.yaml
# Edit config.yaml with your settings
```

### Google Classroom Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Enable the **Google Classroom API**
4. Create **OAuth 2.0 credentials** (Desktop application type)
5. Download the credentials JSON file
6. Save it as `google_credentials.json` in the project root
7. Run authentication:

```bash
python skills/alim-agent/scripts/classroom_sync.py --auth
```

### Running the Agent

```bash
# Start the agent (port 3005)
python -m hermes_alim serve --config config.yaml
```

### Docker

```bash
# Build
docker build -t alim-agent .

# Run
docker run -p 3005:3005 \
  -e OPENROUTOR_API_KEY=your_key_here \
  -v $(pwd)/google_credentials.json:/app/google_credentials.json \
  alim-agent
```

## Configuration

Key settings in `config.yaml`:

| Setting | Default | Description |
|---------|---------|-------------|
| `provider.model` | `anthropic/claude-sonnet-4-20250513` | OpenRouter model |
| `gateway.port` | `3005` | Agent gateway port |
| `google_classroom.enabled` | `true` | Enable Classroom sync |
| `knowledge_base.directory` | `knowledge` | Knowledge base path |
| `cron.timezone` | `UTC` | Cron schedule timezone |

## Project Structure

```
hermes-alim/
├── SOUL.md                        # Agent identity & personality
├── config.yaml                    # Configuration
├── Dockerfile                     # Container definition
├── .gitignore                     # Git ignore rules
├── README.md                      # This file
├── skills/
│   └── alim-agent/
│       ├── SKILL.md               # Skill definition (all 8 modes)
│       └── scripts/
│           └── classroom_sync.py  # Google Classroom integration
├── cron/
│   └── jobs.json                  # Scheduled tasks
├── knowledge/                     # Knowledge base (auto-created)
│   ├── _index.json
│   ├── _classroom/                # Synced Classroom data
│   ├── _glossary/                 # Islamic terminology
│   ├── _progress/                 # Student progress
│   ├── aqeedah/
│   ├── fiqh/
│   ├── usul-al-fiqh/
│   ├── hadith-sciences/
│   ├── seerah/
│   ├── tafsir/
│   ├── arabic/
│   └── ulum-al-quran/
├── logs/                          # Log files
├── plugins/                       # Agent plugins
└── memories/                      # Agent memory storage
```

## Modes

The Alim Agent operates in 8 modes:

| Mode | Description |
|------|-------------|
| `sync` | Sync courses, announcements, assignments from Google Classroom |
| `study` | Guided study sessions with structured plans |
| `assignment` | Help understanding and structuring assignments |
| `test-prep` | Review sheets, practice questions, study schedules |
| `qa` | Scholarly Q&A with citations and source references |
| `glossary` | Islamic terminology reference and management |
| `progress` | Track learning progress across subjects |
| `recite` | Qur'an memorization and text recitation aid |

## Scheduled Tasks

Defined in `cron/jobs.json`:

| Job | Schedule | Description |
|-----|----------|-------------|
| Daily Classroom Sync | 07:00 UTC | Full sync of all Classroom data |
| Due Date Reminder | 08:00 UTC | Check and remind about upcoming deadlines |
| Weekly Knowledge Summary | Sunday 10:00 UTC | Summary of new study materials (disabled by default) |

## Knowledge Base

The knowledge base is organized by Islamic discipline:

- **`aqeedah/`** — Islamic creed and theology
- **`fiqh/`** — Jurisprudence (worship, transactions, family law)
- **`usul-al-fiqh/`** — Principles of jurisprudence
- **`hadith-sciences/`** — Hadith methodology and sciences
- **`seerah/`** — Prophetic biography
- **`tafsir/`** — Qur'anic exegesis
- **`arabic/`** — Arabic language (grammar, morphology, rhetoric)
- **`ulum-al-quran/`** — Qur'anic sciences

Each directory can contain markdown notes, JSON data files, and study materials.

## Important Notes

- **The Alim Agent is not a Mufti.** For personal religious rulings, always consult a qualified local scholar.
- **Never fabricates sources.** If uncertain, the agent will say so clearly.
- **Google credentials** (`google_credentials.json`, `google_token.json`) are excluded from version control via `.gitignore`.
- The agent encourages **understanding over memorization** — the goal is to produce scholars, not just test-takers.

## Contributing

This agent is designed to be extended. To add new skills or modes:

1. Add the mode definition to `skills/alim-agent/SKILL.md`
2. Create any necessary scripts in `skills/alim-agent/scripts/`
3. Update `config.yaml` if new configuration is needed
4. Add cron jobs to `cron/jobs.json` if scheduled tasks are needed

## License

This project is part of the Hermes Agent ecosystem by Nous Research.

---

*"Seek knowledge from the cradle to the grave."*
— The Messenger of Allah ﷺ

*Bismillah. May Allah bless this tool and make it beneficial for students of knowledge.*
