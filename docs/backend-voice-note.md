# Voice Input — Backend Note

**No backend changes required.**

The voice input feature is entirely frontend-side:

1. Flutter `record` package captures audio to a local `.m4a` file.
2. The app uploads that file directly to AssemblyAI's REST API (`POST /v2/upload`).
3. AssemblyAI transcribes the audio and returns plain text.
4. The transcribed text is sent to the existing chat backend as a normal text message — identical to a typed message.

The chat backend receives only text strings. It has no awareness of whether the message originated from voice or keyboard input.

## AssemblyAI API Key

Add to `.env` (never commit):

```
ASSEMBLY_AI_KEY=<your_key_here>
```

## Language Mapping

| Religion | Language code sent to AssemblyAI |
|----------|----------------------------------|
| Islam    | `ur` (Urdu)                      |
| Hinduism | `hi` (Hindi)                     |
| Other    | `ur` (default)                   |
