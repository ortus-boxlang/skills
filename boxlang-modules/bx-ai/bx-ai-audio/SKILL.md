---
name: bx-ai-audio
description: "Use this skill when working with audio in bx-ai: text-to-speech with aiSpeak(), streaming speech with aiSpeakStream() (voice agents, telephony, browser playback), speech-to-text with aiTranscribe(), audio translation with aiTranslate(), choosing audio providers (Cartesia, ElevenLabs, OpenAI, Mistral, Gemini, Grok, Groq), voice gender keywords, and audio events and settings."
---

# bx-ai: Audio (Speech, Streaming, Transcription)

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Text to Speech: `aiSpeak()`

```java
aiSpeak( text="", params={}, options={} )
```

Returns depend on the call:

| Call | Returns |
|------|---------|
| `aiSpeak( "Hello" )` | `AiSpeechResponse` |
| `aiSpeak( "Hello", {}, { outputFile: "/tmp/a.mp3" } )` | the saved file path (string) |
| `aiSpeak()` (no text) | fluent `AiSpeechRequest` builder |

```javascript
response = aiSpeak( "Welcome to BoxLang!", { voice: "nova" }, { provider: "openai", outputFormat: "mp3" } )
response.saveToFile( "/tmp/welcome.mp3" )   // returns absolute path, creates parent dirs
response.getSize()       // bytes
response.getMimeType()   // "audio/mpeg"
```

`AiSpeechResponse` methods: `saveToFile()`, `getBase64()`, `getMimeType()`, `toDataURI()`, `toStruct()`, `hasAudio()`, `getSize()`.

Where things go:

- `params`: provider body fields: `model`, `voice`, `speed`, `instructions`, plus provider-native fields.
- `options`: `provider`, `apiKey`, `outputFile`, `outputFormat`, `timeout` (default 30), logging flags. `voice`, `speed` and `instructions` are also accepted here.
- `outputFormat` defaults to `mp3`.

### Gender keywords

`voice: "male"` or `voice: "female"` (or `.male()` / `.female()`) is resolved to a concrete voice through `audio.voiceGenderMap` for the active provider. If the map has an empty value (Mistral), the provider default voice is used.

```javascript
aiSpeak( "Hi there", { voice: "female" }, { provider: "elevenlabs" } )
```

## Fluent Builder

```javascript
aiSpeak()
    .text( "Your order has shipped." )
    .provider( "cartesia" )
    .female()
    .asWav()
    .outputFile( "/tmp/order.wav" )
    .speak()
```

Real methods on `AiSpeechRequest`: `text`, `model`, `provider`, `apiKey`, `voice`, `male`, `female`, `speed`, `instructions`, `outputFormat`, `asMP3`, `asWav`, `asFlac`, `asOpus`, `asPCM`, `outputFile`, `timeout`, `withParams`, `withOptions`, `withLogging`. Terminators: `speak()` and `stream( callback )`. Static factory: `AiSpeechRequest::of( text )`.

`asFlac()` and `asOpus()` exist, but Cartesia throws `InvalidArgument` for them. Check the provider docs before using them.

## Streaming Speech: `aiSpeakStream()`

```java
aiSpeakStream( text, callback, params={}, options={} )
```

The callback receives one struct per event, discriminated by `type`:

| Event | Shape |
|-------|-------|
| audio | `{ type: "audio", data: binary, format, sampleRate, sequence }` |
| timestamps | `{ type: "timestamps", words: [], start: [], end: [] }` (providers that support them, e.g. Cartesia SSE) |
| done | `{ type: "done", chunks, bytes }` (always last) |

Return an explicit `false` from the callback to stop early (barge-in, client disconnect). Any other return value, including nothing, continues.

```javascript
summary = aiSpeakStream(
    "Thanks for calling BoxLang support.",
    ( event ) => {
        if ( event.type == "audio" ) {
            if ( !socket.send( event.data ) ) return false   // client gone: stop generating
        }
    },
    { voice: "female" },
    { provider: "cartesia", outputFormat: "pcm" }
)
// summary: { provider, model, audioFormat, sampleRate, chunks, bytes, completed }
```

Fluent: `aiSpeak().text( "Hi" ).provider( "cartesia" ).asPCM().stream( ( e ) => handle( e ) )`.

- `options.timeout` is an **idle timeout** in seconds (longest wait for headers or between received bytes), not a total duration cap. Default 30.
- Empty text throws `InvalidArgument`.
- Providers without the `speechStream` capability throw `UnsupportedCapability`. Grok does NOT support streaming (its streaming API is a WebSocket, not implemented).

### Custom providers

Implement `IAiSpeechStreamService` (`struct function speakStream( AiSpeechRequest speechRequest, function callback )`, returning the summary struct) and include `"speechStream"` in the provider's `CAPABILITIES`. Plain TTS needs `IAiSpeechService` (`speak( speechRequest )`, returns `AiSpeechResponse`) and `"speech"`. `SpeechStreamHelper` (`streamBinary`, `streamSSE`) is the shared transport used by the built-in providers.

## Choosing a Format

| Use case | `outputFormat` |
|----------|----------------|
| Browser `<audio>` tag, saved files | `mp3` |
| Voice agents, Web Audio, lowest latency | `pcm` |
| Telephony (8 kHz) | `mulaw` or `alaw` (Cartesia) |
| Whole-file playback without compression | `wav` |

### Streaming to a browser over HTTP

Pattern: the callback writes each `audio` chunk to the HTTP response and flushes; when the write fails (listener closed the tab), return `false` so the provider stops generating. Two modes: raw mp3 bytes for `<audio src="speak.bxm?...">`, or newline-delimited JSON events (base64 PCM plus timestamps) for a Web Audio player. See the runnable MiniServer demo in the bx-ai repo: `examples/http-streaming-speech/` (`speak.bxm`, `speak-events.bxm`, `index.html`). Also `examples/advanced/15-audio-tts-example.bxs` and `19-audio-streaming-example.bxs`.

## Cartesia Provider

- Sonic TTS (default model `sonic-3.6`) and Ink-Whisper STT (`ink-whisper`). Capabilities: `speech`, `speechStream`, `transcription`.
- Formats: `mp3`, `wav`, `pcm`, `mulaw`, `alaw`. `flac` and `opus` throw `InvalidArgument`.
- Default sample rates: pcm 24000, mp3 and wav 44100, mulaw/alaw 8000. Override with `params.sample_rate` (mp3 also accepts `params.bit_rate`).
- Params: `speed`, `volume`, `emotion` (folded into `generation_config`), and pass-through `language`, `locale`, `accent`, `normalization`, `pronunciation_dict_id`, `add_timestamps`, `add_phoneme_timestamps`, `context_id`.
- Streaming transport: mp3 and wav use `/tts/bytes` (no timestamps); pcm, mulaw and alaw use SSE with word timestamps. `params.transport` (`"bytes"` or `"sse"`) forces one; SSE with mp3/wav throws `InvalidArgument`.
- `translate()` throws `UnsupportedCapability`.

```javascript
aiSpeakStream(
    "Hello", ( e ) => { if ( e.type == "timestamps" ) println( e.words ) },
    { add_timestamps: true, sample_rate: 24000, emotion: "happy" },
    { provider: "cartesia", outputFormat: "pcm" }
)
```

## Speech to Text: `aiTranscribe()` and `aiTranslate()`

```java
aiTranscribe( audio="", params={}, options={} )
aiTranslate( audio="", params={}, options={} )   // speech in, English text out
```

`audio` is a local file path, a URL, or binary data. Default `returnFormat` is `"text"` (a string). `options.returnFormat: "response"` returns an `AiTranscriptionResponse` (`getText`, `getLanguage`, `getWords`, `getSegments`, `getDuration`, `getModel`, `getProvider`, `getWordCount`, `getFormattedDuration`, `hasWords`, `hasSegments`, `toStruct`). Called with no audio, both return a fluent `AiTranscriptionRequest`.

```javascript
text = aiTranscribe( "/tmp/call.mp3", { language: "es" }, { provider: "groq" } )

res = aiTranscribe( "/tmp/call.wav", {}, { provider: "cartesia", returnFormat: "response" } )
println( res.getText() & " (" & res.getLanguage() & ")" )

aiTranscribe().file( "/tmp/a.mp3" ).provider( "openai" ).language( "en" ).withWordTimestamps().transcribe()
aiTranslate().file( "/tmp/es.mp3" ).provider( "openai" ).translate()
```

Transcription builder methods: `file`, `url`, `data`, `model`, `provider`, `apiKey`, `language`, `inputFormat`, `timeout`, `withWordTimestamps`, `withSegmentTimestamps`, `withTimestamps`, `diarize`, `asJSON`, `asText`, `asVerboseJSON`, `asSRT`, `asVTT`, `withParams`, `withOptions`, `withLogging`, terminators `transcribe()` and `translate()`.

## Audio Capability Table

From each service's `CAPABILITIES` array:

| Provider | speech | speechStream | transcription | translation |
|----------|:------:|:------------:|:-------------:|:-----------:|
| `openai` | yes | yes | yes | yes |
| `cartesia` | yes | yes | yes | throws |
| `elevenlabs` | yes | yes | yes | no (delegates to transcribe) |
| `mistral` | yes | yes | yes | no (delegates to transcribe) |
| `gemini` | yes | yes | yes | no (prompt-based) |
| `grok` | yes | no | no | no |
| `groq` | no | no | yes | yes |

Only `translation` listed in `CAPABILITIES` counts as native translation. ElevenLabs, Mistral and Gemini implement `translate()` but do not translate through a dedicated endpoint.

### API keys

`aiService()` resolves the key in order: explicit `apiKey` option, then the `<PROVIDER>_API_KEY` environment or system setting (`CARTESIA_API_KEY`, `ELEVENLABS_API_KEY`, `OPENAI_API_KEY`, `GROQ_API_KEY`, ...), then module settings. `audio.defaultApiKey` is only used when no convention variable exists for the resolved provider.

## Module Settings (`audio`)

```javascript
// boxlang.json > modules > bxai > settings
audio : {
    defaultProvider           : "openai",
    defaultApiKey             : "",
    defaultVoice              : "",
    defaultOutputFormat       : "mp3",
    defaultSpeechModel        : "",
    defaultTranscriptionModel : "",
    voiceGenderMap : {
        openai     : { male: "ash", female: "nova" },
        grok       : { male: "rex", female: "eve" },
        gemini     : { male: "Fenrir", female: "Aoede" },
        elevenlabs : { male: "CwhRBWXzGAHq8TQ4Fs17", female: "EXAVITQu4vr4xnSDxMaL" }
        // mistral (empty, provider default) and cartesia (voice UUIDs) also ship
    }
}
```

Override a single entry, e.g. `audio.voiceGenderMap.openai.male = "echo"`.

## Events

Announced via `BoxAnnounce`:

| Event | Payload |
|-------|---------|
| `beforeAISpeech` / `afterAISpeech` | `speechRequest`, `service`, (`result` on after); `stream: true` when from `aiSpeakStream()` (result is the summary struct) |
| `beforeAITranscription` / `afterAITranscription` | `transcriptionRequest`, `service`, (`result` on after) |
| `beforeAITranslation` / `afterAITranslation` | `transcriptionRequest`, `service`, (`result` on after) |

## Common Pitfalls

- ❌ Do NOT hardcode API keys in source
  - ✅ Use `<PROVIDER>_API_KEY` environment variables or module settings
- ❌ Do NOT expose a speech-streaming endpoint without authentication and rate limits: every request spends provider credits (the demo endpoints are demo only)
  - ✅ Cap text length and whitelist providers and formats server-side
- ❌ Do NOT ignore client disconnects in the stream callback
  - ✅ Return an explicit `false` when the write fails so the provider stops generating
- ❌ Do NOT use `mp3` for voice agents or telephony
  - ✅ Use `outputFormat: "pcm"` (voice agents) or `mulaw`/`alaw` (telephony, Cartesia)
- ❌ Do NOT call `aiSpeakStream()` with Grok or Groq: they lack the `speechStream` capability and throw `UnsupportedCapability`
- ❌ Do NOT use `flac` or `opus` with Cartesia, or `aiTranslate()` with Cartesia
- ❌ Do NOT treat `timeout` as a total duration limit for streams: it is an idle timeout
- ✅ Handle only `type == "audio"` events for playback; `timestamps` and `done` carry no audio bytes
- ✅ `aiSpeak()` with `options.outputFile` returns a path string, not a response object
