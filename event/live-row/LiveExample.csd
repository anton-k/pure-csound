; Anton Kholomiov, 2019

; Demo for liveRow
;
; liveRow allows us to switch between audio clips in sync (like in Ableton live).
<CsoundSynthesizer>
<CsOptions>
; Select audio/midi flags here according to platform
-odac -d    ;;;realtime audio out
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs  = 1

FLpanel "FLkeyIn", 300, 200, -1, -1, 5, 1, 1

ih      FLbox   "   Press key to switch          ",  1,      5,     14,    690,    20,     -200,  10
ih      FLbox   "---------------+---------------+",  1,      5,     14,    690,    20,     -200,  30
ih      FLbox   "| Kick         | Percussion    |",  1,      5,     14,    690,    20,     -200,  50
ih      FLbox   "+--------------+---------------+",  1,      5,     14,    690,    20,     -200,  70
ih      FLbox   "| q            | w             |",  1,      5,     14,    690,    20,     -200,  90
ih      FLbox   "| a            | s             |",  1,      5,     14,    690,    20,     -200,  110
ih      FLbox   "+--------------+---------------+",  1,      5,     14,    690,    20,     -200,  130
ih      FLbox   "| z - off      | x - off       |",  1,      5,     14,    690,    20,     -200,  150
ih      FLbox   "+--------------+---------------+",  1,      5,     14,    690,    20,     -200,  170
FLpanelEnd
FLrun

#include "LiveRow.udo"
#include "LiveRows.udo"

opcode Player, a, iii
iTab, iBpm, iBeatDur xin

iDur = iBeatDur / (iBpm / 60)
itTotalSteps = floor((ftlen(iTab) / ftsr(iTab)) / iDur)
itTotalDur = itTotalSteps * iDur
aNdx phasor (1 / iDur)
aNdx = iDur * aNdx

kStart init 0
kTrig metro (1 / iDur)
if (kTrig == 1) then
  kStart = (kStart + 1) % itTotalSteps
endif

aRes tableikt (kStart * iDur + aNdx) / itTotalDur, iTab, 1
xout aRes
endop

instr 2
kKickInd init 0
kPercInd init 0

kascii   FLkeyIn
ktrig changed kascii
if (kascii > 0) then
  printf "Key Down: %i\n", ktrig, kascii
else
  printf "Key Up: %i\n", ktrig, -kascii
endif

if (ktrig == 1) then
  if (kascii == 113) then
    kKickInd = 0

  endif

  if (kascii == 97) then
    kKickInd = 1
  endif

  if (kascii == 122) then
    kKickInd = -1
  endif


  if (kascii == 119) then
    kPercInd = 0
  endif

  if (kascii == 115) then
    kPercInd = 1
  endif

  if (kascii == 120) then
    kPercInd = -1
  endif
endif

;kKickInd randi 3.9, (1/2)
;kKickInd = floor(abs(kKickInd))
;kPercInd randi 1.9, (1/6)
;kPercInd = floor(abs(kPercInd))

ares1 liveRow 2, 200, 110, 4, kPercInd, 201 ; kPercInd
ares2 liveRow 2, 100, 110, 4, kKickInd
ares3 Player 13, 110, 4

ares sum ares1, ares2, ares3
out ares, ares
endin

</CsInstruments>
<CsScore>

; Let's load the samples
f11 0 0 1 "samples/11 Perc B.wav" 0 0 1
f13 0 0 1 "samples/12 Clap B.wav" 0 0 1

f15 0 0 1 "samples/heartbeat-110.wav" 0 0 1
f16 0 0 1 "samples/05 HH B.wav" 0 0 1
f17 0 0 1 "samples/4-floor-110.wav" 0 0 1

; audio for kicks
f100 0 2 -2 15 17
; audio for percussion
f200 0 2 -2 11 16

; Aux params  Size  Del  Tail  AutoSwitch   NeedRetrig  Volume
f201 0 12 -2  1     0    1     -1           1           1
              1     0    0     -1           0           2

i2 0 120
e
</CsScore>
</CsoundSynthesizer>