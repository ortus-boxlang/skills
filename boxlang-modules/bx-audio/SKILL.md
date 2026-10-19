---
name: bx-audio
description: "Use this skill for audio in BoxLang with the bx-audio module: synthesis (audioOsc, audioDrum, audioNoise), loading and saving WAV/MP3/FLAC (audioLoad, audioSave), editing (audioTrim, audioConcat, audioMix, audioFade, audioStretch, audioPitch), effects (audioDelay, audioReverb, audioEq), timelines and ducking, loudness and mastering (audioLoudness, audioMaster), analysis (audioBpm, audioDetectSilence), local text-to-speech (audioSpeak), FFmpeg and video (audioMux), and the audio tools bx-audio registers for BoxLang AI agents (audioTrim@bxaudio and 25 more)."
---

# bx-audio: Audio for BoxLang

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

Audio synthesis, mixing, analysis, mastering, text-to-speech and playback with no native dependencies. WAV, MP3 and FLAC are built in. OGG, Opus, AAC, M4A and reading the audio of a video use FFmpeg, found or downloaded on first use.

## Installation

```bash
install-bx-module bx-audio
# CommandBox
box install bx-audio
```

Requires BoxLang 1.18.0 or higher and a full JDK 21 or newer.

## Rules That Apply Everywhere

- **Buffers are values.** Sound is held in an audio buffer. Every function that changes audio returns a **new** buffer and leaves its input untouched. A buffer has `getChannels()`, `getFrames()`, `getSampleRate()`, `getDurationSeconds()`, `getPeak()`, `getRms()` and `copy()`.
- **Do not mix positional and named arguments in one call.** Use all positional, `audioPump( t, "music", times, -4, 0.1 )`, or all named, `audioAdd( timeline=t, sound=kick, at=0, track="drums" )`.
- **Decibels.** Gains, thresholds and ceilings are in dB, 0 dB is full scale. Loudness is in LUFS.
- **Seconds.** Times are in seconds. A timeline turns beats and bars into seconds with `t.beat( n )` and `t.bar( n )`.
- **Repeatable.** Noise and random choices take a `seed`. The same seed gives the same sound on any machine.
- **The extension picks the format** in `audioSave( audio, path )`: `.wav`, `.mp3`, `.flac`, and `.ogg`, `.opus`, `.m4a`, `.aac` through FFmpeg.

## Load, Save, Edit

```javascript
tone = audioOsc( "sine", 440, 1 )
tone = audioFade( audio=tone, fadeIn=0.01, fadeOut=0.2, curve="smooth" )
audioSave( tone, "tone.wav" )
println( audioInfo( "tone.wav" ) )   // channels, sampleRate, frames, seconds
```

| Function | Purpose |
|---|---|
| `audioLoad( path )` | Read WAV, MP3, FLAC, or any format through FFmpeg |
| `audioSave( audio, path, bitDepth=16, bitrate=0 )` | Write by extension. `bitDepth` 16, 24 or 32 (float) for WAV, `bitrate` in kbps for MP3. Returns the absolute path |
| `audioInfo( source, levels=false )` | Channels, sample rate, frames, seconds of a buffer or a file, and peak and rms with `levels=true` |
| `audioSilence( seconds, channels=2, sampleRate=44100 )` | A blank buffer |
| `audioGain( audio, gainDb )` | Change the volume |
| `audioNormalize( audio, targetDb=-1 )` | Scale the peak to a target |
| `audioFade( audio, fadeIn=0, fadeOut=0, curve="linear" )` | Fade, `curve` is `linear` or `smooth` |
| `audioTrim( audio, start=0, end )` | Cut a section |
| `audioConcat( audios )` | Join end to end |
| `audioMix( audios )` | Play together |
| `audioReverse( audio )` | Backwards |
| `audioChannels( audio, channels )` | Mono and stereo |
| `audioResample( audio, sampleRate )` | Change the sample rate |
| `audioStretch( audio, rate )` | Speed without changing pitch, 0.25 to 4 |
| `audioPitch( audio, semitones )` | Pitch without changing length, within 24 semitones |
| `audioFitTo( audio, seconds )` | Exact length, keeping pitch |
| `audioTags( path, tags )` | Read, or with `tags` write, the tags of WAV, MP3, FLAC |
| `audioEncode( audio, format="wav", ... )` / `audioDecode( data, format="" )` | To and from bytes in memory |

## Synthesis and Effects

```javascript
pluck = audioEnvelope( audioOsc( "saw", audioFreq( "A1" ), 0.4 ), 0.003, 0.12 )
pluck = audioFilter( pluck, "lowpass", 900, 2 )
kick  = audioDrum( "kick" )
```

| Function | Purpose |
|---|---|
| `audioOsc( shape, freq, seconds, sampleRate=44100, harmonics=16, partials, width=0.5, phase=0 )` | `sine`, `saw`, `square`, `triangle`, `pulse`, `additive` |
| `audioFreq( note )` | `"C4"`, `"F#3"` or a MIDI number to Hz |
| `audioNoise( seconds, sampleRate=44100, seed=1, color="white" )` | `white`, `pink`, `brown`, `blue` |
| `audioDrum( type, sampleRate=44100, seed=1, pitch=1, decay=1, level=1, seconds )` | `kick`, `snare`, `hat`, `openhat`, `clap`, `tom`, `crash`, `riser` |
| `audioEnvelope( audio, attack=0.005, decay=0 )` | Attack then exponential decay |
| `audioFilter( audio, type, cutoff, q=0.7071 )` | `lowpass`, `highpass`, `bandpass`, `notch` |
| `audioDelay( audio, time=0.35, feedback=0.4, mix=0.35, pingPong=false, tail )` | Echo |
| `audioReverb( audio, room=0.5, damp=0.5, mix=0.3, tail )` | Reverb |
| `audioChorus( audio, rate=0.8, depth=0.003, mix=0.5 )` | Width and thickness |
| `audioSampler( audio, rootNote="C4", ... )` and `audioNote( sampler, note, ... )` | An instrument from a recording |

## Timelines, Ducking and Mastering

```javascript
t = audioTimeline( bpm=128 )
voice = audioLoad( "voice.wav" )

audioAdd( timeline=t, sound=music, at=0, track="music", gainDb=-10 )
audioAdd( timeline=t, sound=voice, at=t.bar( 2 ), track="voice" )
audioDuck( t, "music", "voice", -9 )        // music dips under the voice

mix   = audioRender( timeline=t, tail=1 )
final = audioMaster( audio=mix, target="streaming" )   // -14 LUFS, true peak under -1 dBFS
audioSave( final, "out/mix.wav" )
```

| Function | Purpose |
|---|---|
| `audioTimeline( bpm=120, beatsPerBar=4, sampleRate=44100, channels=2 )` | Tracks on a tempo grid |
| `audioAdd( timeline, sound, at=0, track="main", gainDb=0, pan=0 )` | Place a sound |
| `audioDuck( timeline, track, trigger, amountDb=-12, ... )` | Lower a track while another is loud |
| `audioPump( timeline, track, times, amountDb=-5, recovery=0.18 )` | Sidechain style dips |
| `audioRender( timeline, tail=0 )` | Mix down to one buffer |
| `audioLoudness( audio )` | `integrated` LUFS, `range`, `truePeakDb`, `samplePeakDb` |
| `audioMaster( audio, target="streaming", truePeakDb=-1, glue=false )` | Presets `streaming` -14, `podcast` -16, `game` -16, `broadcast` -23, `cinema` -24, or a number of LUFS |
| `audioNormalizeLoudness( audio, targetLufs=-14, truePeakDb=-1 )` | Set loudness under a ceiling |
| `audioCompress`, `audioLimit`, `audioEq( audio, bands )` | Dynamics and tone. A band is `{ type, freq, gainDb, q }`, `type` is `peak`, `lowshelf`, `highshelf`, `lowpass`, `highpass`, `notch` |

## Analysis

| Function | Returns |
|---|---|
| `audioBpm( audio, minBpm=60, maxBpm=200 )` | `{ bpm, confidence, beats }`, `bpm` is 0 with no clear pulse |
| `audioDetectSilence( audio, thresholdDb=-50, minSeconds=0.3 )` | Array of `{ start, end, duration }` |
| `audioTrimSilence( audio, thresholdDb=-50, pad=0 )` | Cut the ends |
| `audioSpectrum`, `audioSpectrogram`, `audioFft` | Frequency data |
| `audioWaveformImage( audio, width, height, format, path, ... )` | SVG or PNG, written to `path` when given |
| `audioSpectrogramImage( audio, width, height, format, path, ... )` | PNG or SVG |

## Local Text to Speech

`audioSpeak( text, voice, autoInstall, onProgress, speed=1, pauses, pronunciations )` returns a mono buffer, using a [Piper](https://github.com/rhasspy/piper) voice on the JVM. The first call downloads the engine (about 148 MB) and the voice, once, into `~/.bxaudio`, unless `autoInstall` is `false`. `voice` is an id such as `en_US-joe-medium` or a short name such as `joe`. `audioVoices( language="", installed=false, status="offered" )` lists them with their licenses. `audioSpeakCues` and `audioSubtitles` give captions timed to the words.

```javascript
voice = audioSpeak( text="Meet BoxLang.", voice="joe" )
audioSave( voice, "voice.wav" )
```

## FFmpeg and Video

`audioFfmpeg()` reports availability, `audioFfmpegInstall()` downloads it, `videoInfo( path )` describes any media file, and `audioMux( video, audio, output, keepOriginal=false, originalDb=-12, offset=0, bitrate=0 )` puts audio on a video without re-encoding the picture.

## Settings

In `boxlang.json` under `modules.bxaudio.settings`:

| Setting | Default | Does |
|---|---|---|
| `home` | `""` | Where the engine, voices and FFmpeg are downloaded. Empty means `~/.bxaudio` |
| `autoInstall` | `true` | May the module download things on first use |
| `ffmpeg` | `""` | Path to an FFmpeg to use |
| `ai.enabled` | `true` | Register the AI agent tools in bx-ai when it is installed |
| `ai.allowedPaths` | `[]` | Folders the AI tools may read and write. Empty means the temp folder and the working directory |
| `ai.outputDir` | `""` | Where AI tool results go when no path is given. Empty means `bx-audio-ai` in the temp folder |

## AI Agent Tools (with bx-ai)

When the BoxLang AI module (`bx-ai`) is installed, bx-audio registers 26 tools in its tool registry under the module name `bxaudio`. **Registering only makes them available.** An agent gets a tool only when its `tools` list names it.

```javascript
agent = aiAgent(
    name : "sound-editor",
    tools: [ "audioInfo@bxaudio", "audioTrim@bxaudio", "audioNormalize@bxaudio" ]
)
agent.run( "Cut the first 5 seconds off /recordings/intro.wav and normalize it" )

// Every audio tool
agent = aiAgent( name: "studio", tools: aiToolRegistry().getByModule( "bxaudio" ) )
```

| Group | Tool keys (all end in `@bxaudio`) |
|---|---|
| Inspect | `audioInfo`, `audioLoudness`, `audioBpm`, `audioDetectSilence`, `audioReadTags`, `audioWaveformImage`, `audioSpectrogramImage`, `videoInfo` |
| Edit | `audioTrim`, `audioTrimSilence`, `audioConcat`, `audioMix`, `audioFade`, `audioStretch`, `audioPitch`, `audioReverse`, `audioGain`, `audioConvert` |
| Master | `audioNormalize`, `audioMaster`, `audioEq`, `audioReverb` |
| Create | `audioVoices`, `audioSpeak`, `audioSilence`, `audioMux` |

How they behave:

- **File based.** A tool reads a file by `path`, writes a **new** file and returns `{ path, seconds, channels, sampleRate }`. Multi-file tools (`audioConcat`, `audioMix`) take `paths`, an array. Edit tools take an optional `outputPath`; without it the result goes to `ai.outputDir`.
- **Never overwrites.** An existing output path, or the input path, fails with `AudioToolExists`.
- **Path guard.** Paths are resolved (symlinks followed) and must lie under `ai.allowedPaths`, by default the temp folder and the working directory, or the tool fails with `AudioToolAccessDenied`.
- **Other errors.** `AudioToolNotFound` (no input file), `AudioToolInvalidArgument` (empty list, more than 64 files, silence over 3600 seconds, output path with no extension).
- **Local speech.** `audioSpeak@bxaudio` runs on the machine. `speak@bxai` calls a cloud provider. Name the one wanted.
- Disable with `ai.enabled: false`. Unloading the module removes the tools from the registry.

See `bx-ai-tools` for the registry itself.

## Pitfalls

- ❌ Mixing positional and named arguments in one call. Pick one style.
- ❌ Expecting an edit function to change its input. It returns a new buffer, so assign the result.
- ❌ `audioConcat` of buffers with different formats. Match sample rate and channels first with `audioResample` and `audioChannels`.
- ❌ Calling `audioSpeak` on a server with no network and `autoInstall` on, the first call downloads. Run `audioVoiceInstall( "engine" )` and `audioVoiceInstall( voice )` ahead, or set `autoInstall` to `false`.
- ❌ Granting an agent every audio tool when it needs two. Name only what its job needs.
- ❌ Expecting the AI tools without bx-ai installed. They are only registered when `aiToolRegistry()` exists.
