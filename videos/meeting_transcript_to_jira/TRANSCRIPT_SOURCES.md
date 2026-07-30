# Getting a transcript out of your meeting tool

The input to this workflow is a plain text file. That is the whole interface, so it does not much
matter what your team records with — only whether you can get the text onto disk.

All rows verified against vendor documentation on **2026-07-29**. This space changes quickly; check
the vendor's own docs before relying on a plan or format detail.

---

## Tier 1 — a readable file, no API work

| Tool | Format | How you get it | Plan | Admin gate | Bot joins? |
|---|---|---|---|---|---|
| **Notion AI Meeting Notes** | Markdown via page export or API | API: `GET /v1/pages/{id}/markdown?include_transcript=true` | Business or Enterprise | Workspace owner controls it | **No** — captures system audio |
| **Zoom meeting transcript** | `.TXT` | "Save transcript" in-meeting → `~/Documents/Zoom` | Pro, Business, Enterprise | **Yes, off by default** | No |
| **Microsoft Teams** | `.docx` or `.vtt` | Chat → past meeting → Recap → Transcript → Download | Policy-gated, no SKU table published | Yes (`AllowTranscription`) | No |
| **Webex** | Plain text | Captions panel → Download, before the meeting ends | Webex Suite meeting platform | Yes | No |
| **Granola** | CSV export includes transcript, plus MCP | Settings → Profile → Generate CSV (emailed, link expires 24h) | Business ($14/user/mo) for API keys | Export on by default | **No** — system audio |

## Tier 2 — clean, but API-mediated

| Tool | Format | Notes |
|---|---|---|
| **Google Meet** | Google Doc; API returns plain text | `conferenceRecords.transcripts.entries`. **Entries expire after 30 days.** Drive-for-desktop syncs Docs as pointer stubs, so a local agent cannot read a synced file directly. Business Standard+ |
| **Fireflies** | JSON, PDF, DOCX, SRT, CSV, MD | The only tool where a **free** user gets machine-readable transcripts with a static bearer token. UI download is Pro-gated; the API is not |
| **Grain** | `.md`, and API gives `.txt` / `.vtt` / `.srt` / JSON | MCP `fetch_meeting_transcript` works on **all plans including Free**. API access from Starter up |
| **Zoom cloud recording** | `.vtt` only | `GET /meetings/{id}/recordings`, then the `TRANSCRIPT` file. Bearer header, not a query param |
| **Fathom, MeetGeek, Avoma, Circleback** | JSON via API or webhook | All have documented transcript endpoints or transcript-bearing webhooks |

## Tier 3 — effectively walled gardens

| Tool | Why |
|---|---|
| **M365 Copilot recap** | No file export at all. JSON behind a Copilot license, or an Outlook email |
| **Gemini "Take notes for me"** | No notes API exists. Drive export only |
| **Slack huddle AI notes** | Transcript embedded in a canvas, excluded from search, no documented export |
| **Fathom (UI)** | Unlimited free recording and a good API, but the UI offers only "Copy Transcript" |
| **Read.ai** | OAuth 2.1 with no static keys and 10-minute tokens. One admin toggle kills exports and the API together |
| **Apple Notes / Voice Memos** | Transcribe well, dead-end at the clipboard. Microphone-based, so they capture the room rather than the far end of a call |

---

## If your tool gives you audio but no text

Upload the audio file to **Word on the web** (Transcribe — 300 min/month on a Microsoft 365
subscription) and save the result, or run it through local Whisper. This covers Zoom computer
recordings, which produce MP4, M4A and a chat log but no transcript file.

---

## Two things that changed in 2026

**Bot-based capture is degrading on Google Meet.** Google's documentation now states that
third-party bots attempting to join under Restricted access "are automatically denied access
without actions required by the host." Every major notetaker except Avoma has shipped a bot-free
desktop capture mode in response.

**Consent prompts are landing.** Google is rolling out admin-required explicit participant consent
before automatic note-taking, and Webex already requires it. For an unattended agent, a consent
dialog is a silent failure.

Worth saying plainly: tools that capture system audio without a bot (Notion, Granola, Supernormal)
put no notetaker in the participant list. The conferencing platforms show their own recording
indicator, but if you are capturing system audio, tell people.
