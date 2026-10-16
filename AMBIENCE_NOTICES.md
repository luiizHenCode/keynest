# Ambient audio notices

## Rain — `Sources/MacTap/Resources/Ambience/rain.wav`

### Attribution and permission

“rain ambience” by **alex36917**, originally published on Freesound on June 30, 2020:
https://freesound.org/people/alex36917/sounds/524605/

Licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**:
https://creativecommons.org/licenses/by/4.0/
Legal text: https://creativecommons.org/licenses/by/4.0/legalcode

The original sound page explicitly identifies Attribution 4.0 and permits sharing and adaptation with credit. This license permits redistribution in an app, including commercial use, provided attribution, the license link, and an indication of changes are retained. Include this attribution with the app's distributed credits/notices. No endorsement by the author or Blanket is implied.

The author describes a real light-to-medium rain storm, recorded with a **Sony ICD UX560**, with possible light thunder and a distant train horn toward the end. This is a field recording, not synthesized noise. No synthetic sound was added. The selected excerpt avoids the end of the original recording; absence of incidental sounds has not been confirmed by human listening.

Downloaded from **rafaelmardojai/blanket**, whose audio-specific licensing table credits **alex36917** as author and **Porrumentzio** as editor, with license CC BY. The Freesound page resolves the version to CC BY 4.0. Blanket's code license is not being used as permission for this recording; no Blanket code was copied.

### Pinned provenance

- Repository: https://github.com/rafaelmardojai/blanket
- Commit: `775f2a767230a9681850d1b1e085be58656f1382`
- Source file: `data/resources/sounds/rain.ogg`
- Immutable download: https://raw.githubusercontent.com/rafaelmardojai/blanket/775f2a767230a9681850d1b1e085be58656f1382/data/resources/sounds/rain.ogg
- Audio licensing evidence: https://github.com/rafaelmardojai/blanket/blob/775f2a767230a9681850d1b1e085be58656f1382/SOUNDS_LICENSING.md
- Licensing table Git blob SHA-1: `132432d89261be86cda648b07af747d1c6a2371a`
- Source audio Git blob SHA-1 (verified against downloaded bytes): `8363fa856dce8c271c08bb136abde73959f6138e`
- Source audio size: **3,133,874 bytes**
- Source audio SHA-256: `b84c1daf259a24283be40b7663656d17676df4eb60c1e0332820570db891848a`
- Prepared WAV SHA-256: `f7a0da9a3717a6754396866d6d9ba2dfd4f29bda996b207c3775e5667cdcd2cb`

### Changes made for MacTap

1. Decode Blanket's edited Ogg recording with **FFmpeg 8.1.2**, selecting **10.000–41.500 seconds** (31.5 seconds). Downmix to mono and resample to 44,100 Hz, using FFmpeg's default conversion, with float32 samples in memory.
2. Make a circular **1.5-second equal-power crossfade** (66,150 samples). Let `x` be the selected excerpt and `N = 66150`. Keep `x[N:-N]`, then append the overlap of the last `N` samples with the first `N` samples:
   `tail[i] * cos(pi/2 * i/(N-1)) + head[i] * sin(pi/2 * i/(N-1))`.
   The overlap therefore runs from the unmodified tail into the unmodified head; the file wrap continues from the head into its original following samples. This is not a fade to silence. Result: exactly **30 seconds**.
3. Apply one constant gain of **0.723648798127503** (**−2.8094430971 dB**) to target **−36 dBFS RMS**, for quiet ambience. No compressor, limiter, noise generation, or noise reduction was applied.
4. Quantize by `round(sample * gain * 32768)` to signed PCM16, without added dither, and write a standard WAV with Python's `wave` module. No metadata or additional assets were included.

The source was downloaded and decoded in memory; only the final WAV and this notice are retained. The final crossfade uses the above discrete sine/cosine endpoints, not FFmpeg's linear fade default.

### Final asset verification

| Property | Measured value |
| --- | --- |
| Container / codec | WAV / signed little-endian PCM16 (`pcm_s16le`) |
| Channels | 1 (mono) |
| Sample rate | 44,100 Hz |
| Bit depth | 16 bits |
| Frames | 1,323,000 |
| Duration | 30.000 seconds |
| File size | 2,646,044 bytes (2.646 MB; below 5 MB) |
| Sample peak | −8.428665 dBFS |
| RMS (all quantized samples, full-scale reference 32768) | −35.999997 dBFS |
| Clipped samples | 0 |
| Last-to-first adjacent-sample difference | 259 PCM16 units (0.007904 full scale) |

The loop seam follows adjacent samples from the original head rather than joining unrelated endpoints. A nonzero adjacent-sample difference is normal for a recording and does not itself indicate a click. Format, duration, sample levels, decode integrity and hashes were checked programmatically; perceptual seamlessness has not been confirmed by human listening. Playback volume still depends on the app and system gain. MacTap plays this prepared loop locally with independent volume and short playback fades; the recording is bundled without further sample processing.
