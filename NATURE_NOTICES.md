# Nature audio notices — MacTap

## Redistribution and credits

These are real field recordings, not synthesized ambience. The permissions below apply to the **audio**, independently of Blanket's source-code license. Both permit modification and redistribution in an app, including commercial distribution. No Blanket code was copied. No endorsement by the recordists, editor, Freesound, or Blanket is implied.

**Distribution requirement:** retain the ocean attribution, source link, license link, and indication of both Blanket's previous edits and MacTap's changes in the app's distributed credits/notices. This root document records those credits; this asset-only change does not add it to the app bundle or UI. Ensure the release actually delivers the notices. Do not impose additional legal restrictions or effective technological measures on the CC BY recording that restrict the rights granted by that license. CC0 attribution is voluntary and is retained here for provenance.

### Ocean — `Sources/MacTap/Resources/Ambience/ocean.wav`

> “oceanwavescrushing.wav” by **Luftrum**, https://freesound.org/people/Luftrum/sounds/48412/ — **Creative Commons Attribution 4.0 International (CC BY 4.0)**, https://creativecommons.org/licenses/by/4.0/. Previously edited by **Porrumentzio** for Blanket; adapted for MacTap by excerpting, downmixing to mono, applying a 1.5-second circular crossfade, adjusting gain, and converting to PCM16 WAV. No endorsement implied.

- Original attribution/source URL: https://freesound.org/people/Luftrum/sounds/48412/
- Author profile: https://freesound.org/people/Luftrum/
- Author website supplied with the recording: https://www.luftrum.com/
- License URL: https://creativecommons.org/licenses/by/4.0/
- Legal text: https://creativecommons.org/licenses/by/4.0/legalcode
- Original publication: February 16, 2008. The original page explicitly identifies **Attribution 4.0**; Blanket's audio licensing table identifies CC BY without a version.
- Recording: waves on the shore of Kalundborg Fjord at Røsnæs, Denmark, water moving through small stones; recorded at approximately 2 m with a Zoom H2, 120-degree microphones. The author mentions a very distant vessel. This is coastal/ocean ambience, not synthesized waves.

### Forest — `Sources/MacTap/Resources/Ambience/forest.wav`

> “WoodThrushinMorningShawneeForestMay272012.wav” by **kvgarlic**, https://freesound.org/people/kvgarlic/sounds/156826/ — **CC0 1.0 Universal**, https://creativecommons.org/publicdomain/zero/1.0/. Previously edited by **Porrumentzio** for Blanket; adapted for MacTap by excerpting, downmixing to mono, applying a 1.5-second circular crossfade, adjusting gain, and converting to PCM16 WAV. No endorsement implied.

- Original attribution/source URL: https://freesound.org/people/kvgarlic/sounds/156826/
- Author profile: https://freesound.org/people/kvgarlic/
- License/public-domain dedication URL: https://creativecommons.org/publicdomain/zero/1.0/
- Legal text: https://creativecommons.org/publicdomain/zero/1.0/legalcode
- Original publication: May 29, 2012. The original page explicitly identifies **Creative Commons 0** and links to CC0 1.0 (its HTML uses the equivalent `http://creativecommons.org/publicdomain/zero/1.0/` link). Blanket's audio licensing table also identifies CC0.
- Recording: a wood thrush and other birds in heavy woods in southern Illinois, Shawnee Forest, around 7:30 a.m., using stereo microphones. The author describes woodpecker drumming at 17 seconds in the original and another woodpecker call at 1:20. This is a real forest recording, not a substitute stream or synthesized birdsong. Those original timestamps need not map exactly to Blanket's edited version.

## Pinned provenance and source integrity

Downloaded from **rafaelmardojai/blanket** at commit `775f2a767230a9681850d1b1e085be58656f1382`:

- Repository: https://github.com/rafaelmardojai/blanket
- Audio-specific licensing table: https://github.com/rafaelmardojai/blanket/blob/775f2a767230a9681850d1b1e085be58656f1382/SOUNDS_LICENSING.md
- Immutable licensing download: https://raw.githubusercontent.com/rafaelmardojai/blanket/775f2a767230a9681850d1b1e085be58656f1382/SOUNDS_LICENSING.md
- Licensing table Git blob SHA-1: `132432d89261be86cda648b07af747d1c6a2371a`
- Licensing table SHA-256: `e6c7aa889704bb8c5fb762ce2f6ceb0eef27e8317bec68066df40ea8a785327d`

The licensing table credits **Porrumentzio** as editor for both Waves and Birds. Original Freesound pages and Creative Commons license/deed pages were checked separately; the code license was not used as permission for either audio. Downloaded source bytes were checked against the GitHub API's pinned Git blob SHA-1 and size. Git blob hashes use `SHA1("blob " + decimal_byte_length + NUL + bytes)`; SHA-256 values below are ordinary file hashes.

| Property | Ocean | Forest |
| --- | --- | --- |
| Blanket source | `data/resources/sounds/waves.ogg` | `data/resources/sounds/birds.ogg` |
| Source size (bytes) | 2,765,739 | 3,063,230 |
| Source Git blob SHA-1 | `f63eeccdf887b25c5062ccb1e2c85f5573649bdc` | `87f926da092e3fe2ad4327e311f17c38dee10249` |
| Source SHA-256 | `20e1aec7c7542f71645275871650881ea33bc92bd9816b243ea920bb1daa51a0` | `e59b19c2a377d5835d07e7ec8f8c876b9f40ae7f703738b55d616ef96a1638b2` |
| Prepared WAV SHA-256 | `21cee78bbc8430161484198c9a7dbedb0de1dd8d3ba9c537237548d1aee448f9` | `fe4ce6afcb11079377efc63289e79745dadd48f31b0f051513bafd896fdfb5da` |

Immutable source downloads:

- Ocean: https://raw.githubusercontent.com/rafaelmardojai/blanket/775f2a767230a9681850d1b1e085be58656f1382/data/resources/sounds/waves.ogg
- Forest: https://raw.githubusercontent.com/rafaelmardojai/blanket/775f2a767230a9681850d1b1e085be58656f1382/data/resources/sounds/birds.ogg

## Changes made for MacTap

The processing matches the circular equal-power construction documented for the existing rain asset. Rain itself was not modified.

1. Download each pinned Ogg into memory. With **FFmpeg 8.1.2**, decode the excerpt **10.000–41.500 seconds** (31.5 seconds), downmix to mono, and resample to **44,100 Hz** with FFmpeg's default conversion. Exact command argument sequence, with Ogg bytes supplied on stdin:
   `ffmpeg -v error -i pipe:0 -ss 10.000 -t 31.500 -ac 1 -ar 44100 -f f32le pipe:1`.
2. Interpret the result as 1,389,150 little-endian float32 samples `x`. Set `N = 66150` (1.5 seconds). Keep `x[N:-N]` (28.5 seconds), then append 66,150 overlap samples, calculated with double-precision arithmetic:
   `tail[i] * cos(pi/2 * i/(N-1)) + head[i] * sin(pi/2 * i/(N-1))`, where `tail = x[-N:]`, `head = x[:N]`, and `i = 0..N-1`.
   Equivalently: `x[N:-N] + crossfade(tail, head)`. The result has exactly **1,323,000 samples / 30 seconds**. The overlap ends at the original head's final sample; file wrap continues into its original next sample. This is not a fade to silence and does not join unrelated endpoints.
3. Measure whole-loop RMS and apply one constant gain targeting **−33 dBFS RMS**, using `gain = 10**(-33/20) / sqrt(sum(sample**2)/1323000)`. The sum was evaluated with Python `math.fsum`.
   - Ocean gain: **0.6398956362160289** (**−3.8778170300534303 dB**).
   - Forest gain: **0.9659621793064727** (**−0.30079754705348577 dB**).
4. Quantize with Python `round(sample * gain * 32768)` to signed PCM16, without dither. Write standard little-endian WAV using Python's `wave` module (44-byte header). No compressor, limiter, filtering, noise reduction, synthesized signal, metadata, or additional audio was added.

Source downloads, decoded excerpts, and intermediate samples were processed in memory and were not retained as project files. Only the two final WAVs and this notice were created.

## Final validation

Measurements are of the final quantized WAV samples; full scale is 32768.

| Property | Ocean | Forest |
| --- | --- | --- |
| File | `ocean.wav` | `forest.wav` |
| Container / codec | WAV / `pcm_s16le` | WAV / `pcm_s16le` |
| Channels | 1 (mono) | 1 (mono) |
| Sample rate | 44,100 Hz | 44,100 Hz |
| Bit depth | 16 | 16 |
| Frames | 1,323,000 | 1,323,000 |
| Duration | 30.000 seconds | 30.000 seconds |
| File size | 2,646,044 bytes (2.646 MB) | 2,646,044 bytes (2.646 MB) |
| RMS | −33.000000 dBFS | −32.999996 dBFS |
| Absolute sample peak | 0.367156982421875 | 0.267486572265625 |
| Sample peak dBFS | −8.702964 | −11.453960 |
| Clipped samples | 0 | 0 |
| Last-to-first adjacent-sample difference | 77 PCM16 units | 710 PCM16 units |
| Full-file FFmpeg decode | Passed, no errors | Passed, no errors |

Format, frame count, file size, target RMS range (−36 to −30 dBFS), sample peak (< 0.95), hashes, and full-file decode were checked programmatically. A nonzero adjacent-sample difference at file wrap is normal for a field recording; the crossfade preserves the original head's sample adjacency at wrap. **Perceptual seamlessness and absence of incidental sounds have not been confirmed by human listening.** Playback loudness also depends on application and system gain.

`rain.wav` retains SHA-256 `f7a0da9a3717a6754396866d6d9ba2dfd4f29bda996b207c3775e5667cdcd2cb`. Hash comparisons also confirmed that existing Swift source/test files, `Package.swift`, and `AMBIENCE_NOTICES.md` were unchanged during asset preparation. No Swift, package configuration, or selection UI changes were made; these assets are prepared for selection integration separately.
