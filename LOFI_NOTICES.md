# Offline lo-fi ambience

## Credits / UI metadata

```json
{
  "title": "Chill lofi inspired",
  "author": "omfgdude",
  "license": "CC0 1.0 Universal",
  "licenseURL": "https://creativecommons.org/publicdomain/zero/1.0/",
  "sourceURL": "https://opengameart.org/content/chill-lofi-inspired"
}
```

Bundled asset: `Sources/MacTap/Resources/Ambience/lofi.wav`.
Suggested display credit: “Chill lofi inspired — omfgdude (CC0 1.0); edited for looping.” Attribution is voluntary under CC0. Do not imply endorsement.

## Source and permission

- Source page: https://opengameart.org/content/chill-lofi-inspired
- Author profile: https://opengameart.org/users/omfgdude
- Original publication: May 29, 2017.
- Download used: https://opengameart.org/sites/default/files/ChillLofi.ogg
- Verified on: October 16, 2026.
- The asset page identifies the author as **omfgdude**, labels this specific music submission **CC0**, and states: “A short song inspired by lofi hip hop. Created and recorded in one take using the styles of a Yamaha CVP-701.” It also states: “You may use this however you like”.
- In the June 7, 2017 comment, the author identifies the OGG as an export of the original WAV recording, without the low-pass filter applied to the MP3. The OGG, not the MP3, was used here.
- CC0 deed: https://creativecommons.org/publicdomain/zero/1.0/
- Legal instrument: https://creativecommons.org/publicdomain/zero/1.0/legalcode

CC0 explicitly permits copying, modification, distribution and commercial use without asking permission. This includes bundling the edited recording in an offline application. No share-alike or attribution requirement is imposed by CC0. This is verification of the author's published dedication, not an independent audit of all underlying rights: CC0 supplies no warranty and does not waive third-party rights. No claim is made that the instrument manufacturer independently licensed this particular recording. A different submission referring to the Samurai Champloo ending theme was not used.

This asset is a recording of a musical composition with piano/keyboard and a relaxed hip-hop rhythm, not generated noise. No music was synthesized for this project. Musical identification is based on the source description and signal analysis; no listening audition was performed in this environment.

## Delivered properties

| Property | Value |
| --- | --- |
| Container / encoding | WAV, uncompressed signed PCM16 little-endian |
| Channels | 1 (mono) |
| Sample rate | 44,100 Hz |
| Frames | 2,143,922 |
| Duration | 48.61501133786848 seconds |
| File size | 4,287,888 bytes (about 4.09 MiB) |
| Estimated tempo | 78.99 BPM, approximately 16 bars of 4/4 |
| Sample peak | 0.524810791015625 full scale (−5.60 dBFS) |
| RMS level | −24.00 dBFS (not an integrated LUFS measurement) |
| Circular crossfade | 33,516 frames / 0.76 seconds |

The WAV is self-contained and needs no network access at playback. Playback integration and UI code were not changed.

## Processing

Tools: FFmpeg 8.1.2 and Python standard library (`urllib.request`, `subprocess`, `array`, `math`, `wave`, `hashlib`). Download and decoded intermediates were held in memory, not saved as additional project assets.

1. Download `ChillLofi.ogg` (6,486,377 bytes); verify its SHA-256 below. Decoded duration: 125.1489342403628 seconds.
2. Decode with FFmpeg to mono float32 little-endian, 44,100 Hz, with a gentle 6 kHz low-pass:
   `ffmpeg -v error -i pipe:0 -map_metadata -1 -ac 1 -ar 44100 -af lowpass=f=6000 -f f32le pipe:1`
3. Estimate pulse using positive onset-energy differences and autocorrelation. Beat-period candidates cluster around 0.76 seconds; a 16-bar correlation maximum lies near 48.615 seconds. Tempo and meter are estimates, not author-supplied metadata. The source was recorded in one take and has some timing variation; no time stretching or beat quantization was applied.
4. Select decoded start frame **1,379,007** (31.27 seconds), with cycle length **2,143,922 frames**. Keep the subsequent **33,516 frames** as overlap material. The cycle's nominal source end is 79.88501133786848 seconds.
5. Preserve the entire cycle duration rather than shortening it by a crossfade. For `N = 2143922`, `C = 33516`, and `x` beginning at the selected start frame: initialize `y = x[0:N]`; for `0 <= i < C`, set `t = i / (C - 1)` and `y[i] = (1 - t) * x[N + i] + t * x[i]`. The rest of `y` is unchanged. This wraps the outgoing tail into the beginning over about one beat, without overlapping unrelated synthesized sound or deliberately removing a beat. It is not a guarantee of a perfectly seamless harmonic or rhythmic transition.
6. Apply uniform gain `min(0.75 / peak(y), 10**(-24/20) / rms(y))`. Actual factor: **0.64208966606548** (−3.8480863931933404 dB). No compression, limiting, normalization to full scale, or independent fade-to-silence was used.
7. Quantize via `round(sample * gain * 32768)`, clamp to signed 16-bit range, and write a mono PCM16 WAV with Python `wave`. No source metadata or network references are needed by the file.

## SHA-256

| Item | SHA-256 |
| --- | --- |
| Downloaded `ChillLofi.ogg` | `7ea7fd1b7c95ed1ca5f6ebb796626570137bcb75c7f2ea87b6c61212c7a86694` |
| Delivered `lofi.wav` | `e288cf107e6985fd5edaf5c1ca3ed33bed9750791bba3523bbbbb3db02a13aed` |
| Source-page HTML fetched during processing | `9df6609edeee961c8b17f2f2c130ccd75296443933cc01977483c9e8b6f21d0e` |

The source-page hash identifies the fetched response only; the HTML was not bundled and the live page can change (comments, download counts, etc.). It is not a permanent license snapshot.

## Validation and limitations

The generated WAV was checked for channel count, sample format, sample rate, duration, size, peak, RMS and hash. The adjacent last-to-first sample difference is 0.00311279296875 full scale; this is a numerical boundary check, not an auditory assessment. Audition several repetitions in the app before release to confirm the musical transition and subjective volume alongside rain. No Swift tests or builds were run. Only this notice and `Sources/MacTap/Resources/Ambience/lofi.wav` were written.
