<CsoundSynthesizer>
<CsOptions>
-odac    -iadc ;;;RT audio out
</CsOptions>
<CsInstruments>

sr = 48000
ksmps = 64
nchnls = 2
0dbfs = 1

#include "TapeEcho.csd"

gaL init 0
gaR init 0

instr 1
aL, aR diskin2 "guitar-test.wav", 1
gaL = gaL + 0.75 * aL
gaR = gaL + 0.75 * aR
endin

instr 2
aL, aR ins
aLR = (aL + aR) * 0.5
gaL = gaL + aLR
gaR = gaL + aLR
endin

instr 100
aL = gaL
aR = gaR
kMix = 0.6

kRnd oscili 0.25, 0.125

aoL  TapeEchoN aL, 0.3, 0.27, 0.4, 7500, 0.8 + kRnd, 4
aoR  TapeEchoN aR, 0.5, 0.27, 0.35, 7500, 0.8 - kRnd, 4

aWetL, aWetR  reverbsc aoL, aoR, 0.7, 10000
     outs kMix * (aoL + 0.35 * aWetL), kMix * (aoR + 0.35 * aWetR)

gaL = 0
gaR = 0
endin


</CsInstruments>
<CsScore>

f0 120000
i 1 0  -1    ; plays file
;i 2 0  -1     ; plays live from input
i 100 0 -1
e

</CsScore>
</CsoundSynthesizer>


