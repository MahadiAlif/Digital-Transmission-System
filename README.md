# Digital Transmission System

MATLAB simulator for TLC Virtual Lab #2.

The project analyzes PAM-M digital transmission over AWGN channels for
`M = 2, 4, 8, 16`, including matched-filter validation, NRZ and SRRC pulse
shaping, single-pole receiver bandwidth optimization, PSD plots, eye diagrams,
and BER comparison against theory.

Run the main script:

```matlab
run('TLC_Lab2_Project.m')
```

For a faster smoke test:

```powershell
$env:TLC_LAB2_FAST='1'
matlab -batch "run('TLC_Lab2_Project.m')"
```
