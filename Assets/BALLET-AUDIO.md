# Ballet piano recording

- Composer: Frédéric Chopin
- Work: Waltz in A minor, B. 150
- Pianist: Aya Higuchi; performed in 2014
- Source: Musopen, mirrored by Wikimedia Commons
- Recording and performance: CC0 1.0 Universal Public Domain Dedication
- Composition: public domain, as identified on the source page
- Source file page: https://commons.wikimedia.org/wiki/File:Chopin_-_Waltz_in_A_minor,_B_150.ogg
- Pinned source page: https://commons.wikimedia.org/w/index.php?title=File:Chopin_-_Waltz_in_A_minor,_B_150.ogg&oldid=1123916601
- License: https://creativecommons.org/publicdomain/zero/1.0/
- Original recording: https://upload.wikimedia.org/wikipedia/commons/f/f9/Chopin_-_Waltz_in_A_minor%2C_B_150.ogg
- Verified: 2026-10-02. The source explicitly identifies the performance as CC0 separately from the public-domain composition.
- Original OGG SHA-256: 3baf37dc60162f5654e9748504a04a0169a2047663a64cda5d1960a64fc44451

`ballet.wav` is the opening twelve seconds starting at 0.28 seconds in the original, with a 30 ms fade-in and a one-second fade-out. Converted to 44.1 kHz stereo 24-bit PCM, using a constant +2.39 dB gain to preserve the performance's dynamics. The result measures -20.00 LUFS and -5.99 dBTP, matching Velvet's other foreground sounds.

Preparation (ffmpeg is not needed to build or run Velvet):

```sh
ffmpeg -ss 0.28 -i original.ogg -t 12 \
  -af 'afade=t=in:d=0.03,afade=t=out:st=11:d=1,volume=2.39dB' \
  -ar 44100 -ac 2 -c:a pcm_s24le -map_metadata -1 \
  -fflags +bitexact -flags:a +bitexact ballet.wav
```

The excerpt plays once during a deliberately chosen Ballet routine. Spontaneous Ballet and latte zoomies remain silent. Pausing, interruptions and mute follow the same controls as the other dance sounds. CC0 permits modification and redistribution; these credits are retained for provenance.
