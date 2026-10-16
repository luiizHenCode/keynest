# Third-party notices — keyboard recordings

## Mechanical Keyboard Simulator (tplai/kbsim)

- Project / author: Mechanical Keyboard Simulator, Thomas Lai.
- Repository: https://github.com/tplai/kbsim
- Pinned commit: `ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4`.
- Source license: MIT, `LICENSE.md` at
  https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/LICENSE.md
- License file SHA-256: `1603fe1e3aa5011bfc8b3810b1cd8a31ce14c128344db4da1a37fc0bfae71c30`.
- Scope checked: this revision contains one project license (`LICENSE.md`),
  includes the audio under `src/assets/audio/`, and contains no separate asset
  license, attribution file, or audio exclusion. The repository README identifies
  these switch sample sets and the MIT license.
- Redistribution requirement: retain the full copyright and permission notice
  below with copies or substantial portions of these assets, including in app
  distribution notices. No endorsement by the author or switch manufacturers is
  implied.

### Local sample mapping and conversion

All local WAVs are in `Sources/MacTap/Resources/KeyboardSounds/`.
These are existing recorded-switch samples, not generated oscillators, noise,
or pitch-shifted copies. `soft`, `thock`, and `mechanical` are local selection
labels, not manufacturer names or a claim about measured acoustic categories:

| Local family | Upstream switch set | Upstream variations |
| --- | --- | --- |
| `soft-0.wav` through `soft-3.wav` | Cherry MX Black (`mxblack`) | `press/GENERIC_R0.mp3` through `press/GENERIC_R3.mp3` |
| `thock-0.wav` through `thock-3.wav` | Cherry MX Brown (`mxbrown`) | `press/GENERIC_R0.mp3` through `press/GENERIC_R3.mp3` |
| `mechanical-0.wav` through `mechanical-3.wav` | Cherry MX Blue (`mxblue`) | `press/GENERIC_R0.mp3` through `press/GENERIC_R3.mp3` |

Only key-press recordings are used (no separate key-release layer). Recording
hardware/session details are not documented by this upstream README; none are
claimed here. The upstream MP3 encoding is lossy; converting to PCM does not
restore lost information.

Processing: download each pinned MP3 into memory; decode with FFmpeg to signed
16-bit little-endian mono PCM at 44,100 Hz; wrap those frames with Python's
standard-library `wave` module. No synthesis, pitch/time effects, gain changes,
normalization, trimming, fades, or fabricated variations were applied. Channel
and sample-rate conversion are requested explicitly for a uniform output format.
No audio atlas or offsets were used. The MP3 originals are not bundled.

Decoder: `ffmpeg version 8.1.2 Copyright (c) 2000-2026 the FFmpeg developers`.
Decode command (MP3 on stdin, raw PCM on stdout):

```text
ffmpeg -nostdin -hide_banner -loglevel error -i pipe:0 -map 0:a:0 -ac 1 -ar 44100 -c:a pcm_s16le -f s16le pipe:1
```

Format: RIFF/WAVE, uncompressed PCM, mono, signed 16-bit, 44,100 Hz.

### File-level provenance

Each URL below is pinned to the commit above. SHA-256 values are for complete
source MP3 / distributed WAV files respectively. Frames count mono PCM samples.

#### `soft-0.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblack/press/GENERIC_R0.mp3
- Source MP3 SHA-256: `710bfacdfb8012c1a6012e6872e8d0688c7413dbc697724b1b77976bcf964948`.
- Distributed WAV SHA-256: `81759cb773bd1fea92a70236615f410acb4fb9df659e86fc575b9b79002a60b8`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `soft-1.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblack/press/GENERIC_R1.mp3
- Source MP3 SHA-256: `51195ef4d181184b3a6dd36d4b74f1f6f678d233af95467ae3ecd5f6927b5b32`.
- Distributed WAV SHA-256: `7603c724dfb92d96e589028bf6598dc0a01e4a39c3a12d3c29feb085ad4f2a60`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `soft-2.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblack/press/GENERIC_R2.mp3
- Source MP3 SHA-256: `a908202ed34f3f6bf5ee5bd4cd66a8b52dc75af0eb6108698f7bbb69c07dc4a0`.
- Distributed WAV SHA-256: `85bd91ad976dbb1551b38884518b2dbf4c2247c09ce9f61f0472fd80f275f370`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `soft-3.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblack/press/GENERIC_R3.mp3
- Source MP3 SHA-256: `e1af27d6895073a4ff6fda58ea952770a57ec7eaf59ab1b9aef417d90502c73f`.
- Distributed WAV SHA-256: `0fbc9cf0d40219d1801b8115a4cea7f84e0ca8444c9329d277724463f4bc7972`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `thock-0.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxbrown/press/GENERIC_R0.mp3
- Source MP3 SHA-256: `3ac7a03472bb63ae34f077b7f50d85adf5f1d4f93565c6c6608b23be7eca10ca`.
- Distributed WAV SHA-256: `b9e141de75db2afe0925abf636a99aa063f555871051db6e322b040e6975712c`.
- Frames: 4655; duration: 0.105556 s; bytes: 9354.

#### `thock-1.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxbrown/press/GENERIC_R1.mp3
- Source MP3 SHA-256: `9fb249de0ef96cb08602f47b53161338bc90a9d094a9c9b2ca33c513d5ca10a8`.
- Distributed WAV SHA-256: `2b2afc605827de0ceae95b2591d30f3c0c062a77ebb8ce91f4c69a71171f2eaa`.
- Frames: 4655; duration: 0.105556 s; bytes: 9354.

#### `thock-2.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxbrown/press/GENERIC_R2.mp3
- Source MP3 SHA-256: `227363367cf62d93b73994cde9124956aecd8bf44c63167909c1079ceae37688`.
- Distributed WAV SHA-256: `4362509dafe165916ef1935d02e0aecf272a6c67eafa11e42da37ecfba102ed4`.
- Frames: 4655; duration: 0.105556 s; bytes: 9354.

#### `thock-3.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxbrown/press/GENERIC_R3.mp3
- Source MP3 SHA-256: `4eebb28d97138a226223532321f0351f993f1d21d804bd0f26af1d7e7f8309ec`.
- Distributed WAV SHA-256: `eb7d59303e71fcbbb4bcdd981e0361577def14bce965e30c2155917a56d81c1f`.
- Frames: 4655; duration: 0.105556 s; bytes: 9354.

#### `mechanical-0.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblue/press/GENERIC_R0.mp3
- Source MP3 SHA-256: `329a2cb041186579180cfd6c367b4680e82677689788210a96461ee43dc47115`.
- Distributed WAV SHA-256: `45a6cdcafda28488204a8b4dc08cc6061456ffe3637467028f399c77071f3afc`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `mechanical-1.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblue/press/GENERIC_R1.mp3
- Source MP3 SHA-256: `01baccca3a0b9a913063241c0eaade18d8fd6263d507fbfc4fdfa3a5a526389a`.
- Distributed WAV SHA-256: `02710810d43a37ad5209641a24c577b485c200998b656653e38e07fc7edef393`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `mechanical-2.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblue/press/GENERIC_R2.mp3
- Source MP3 SHA-256: `9460f5ccd67aa5c01a125c26533fdbbcf1ce064bb049534bd7e306695fa845b4`.
- Distributed WAV SHA-256: `d68a43e2dfe2196ebe6feaafed62af4f1b9e2f42fa34c37867c0518ff6438d0c`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

#### `mechanical-3.wav`

- Source: https://raw.githubusercontent.com/tplai/kbsim/ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4/src/assets/audio/mxblue/press/GENERIC_R3.mp3
- Source MP3 SHA-256: `4193733efad92e044c6234811219c63075a7c547b6219fdc1f9c915965ba8269`.
- Distributed WAV SHA-256: `a36665d49d669effdf7cf2045bb9a4ee119a0e33d2c1ee944327fae1d1b5cb48`.
- Frames: 3503; duration: 0.079433 s; bytes: 7050.

### MIT license — full upstream text

```text
Copyright (c) Thomas Lai

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
