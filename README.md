# Digital Transmission System

A modular MATLAB simulator for analyzing digital baseband transmission using
PAM-M modulation over an AWGN channel.

This project was built for **TLC Virtual Lab #2** and implements the complete
simulation workflow required to evaluate PAM systems for:

- `M = 2, 4, 8, 16`
- NRZ and Square Root Raised Cosine pulse shaping
- matched-filter receiver validation against theory
- single-pole receiver bandwidth optimization
- BER, SER, PSD, eye-diagram, and filter-synthesis evidence plots

The code is intentionally organized as a small engineering project rather than
a single experiment script. Each part of the digital communication chain is
isolated into a focused module so the simulator is easier to inspect, test,
extend, and explain.

## Project Goal

The objective is to model a complete discrete-time digital transmission system:

```text
bits -> PAM-M mapper -> pulse shaping -> AWGN channel -> receiver filter
     -> optimum sampling -> symbol decision -> demapper -> BER/SER evaluation
```

The simulator answers two main questions:

1. Does the numerical model reproduce the theoretical BER of PAM-M in AWGN when
   the receiver uses a matched filter?
2. If the receiver is constrained to a single-pole low-pass filter, what
   bandwidth minimizes the required `Eb/N0` for a target BER of `10^-3`?

## What This Demonstrates

This project highlights several practical signal-processing and simulation
skills:

- building a reproducible Monte Carlo communication simulator
- implementing Gray-coded PAM mapping and demapping manually
- generating normalized NRZ and SRRC transmit pulses
- synthesizing an SRRC filter using the frequency-sampling method
- synthesizing a digital single-pole filter using impulse invariance
- estimating BER and SER from transmitted and received bit streams
- comparing simulation results with theoretical PAM-M BER expressions
- selecting the optimum sampling phase from noiseless received waveforms
- evaluating bandwidth and ISI tradeoffs through eye diagrams
- organizing MATLAB code into maintainable, purpose-driven modules

## Repository Structure

```text
.
|-- TLC_Lab2_Project.m
|-- config/
|   `-- lab2Config.m
|-- filters/
|   |-- buildTxPulses.m
|   |-- singlePoleImpulseInvariance.m
|   `-- srrcFrequencySampling.m
|-- modulation/
|   |-- decideNearest.m
|   |-- grayToBinary.m
|   |-- pamGrayDemap.m
|   `-- pamGrayMap.m
|-- simulation/
|   |-- findBestPamSampling.m
|   |-- runMatchedFilterValidation.m
|   |-- runSinglePoleOptimization.m
|   |-- simulatePamAwgn.m
|   `-- takeAlignedSamples.m
|-- plotting/
|   |-- drawEye.m
|   |-- plotEyeExamples.m
|   |-- plotFilterSynthesisEvidence.m
|   `-- plotPulsePsd.m
|-- utils/
|   |-- hammingLocal.m
|   |-- interpEbN0AtBer.m
|   |-- qfunLocal.m
|   |-- simplePsd.m
|   `-- theoreticalPamBer.m
`-- results_lab2/
```

`results_lab2/` is generated locally and ignored by Git because it contains
simulation outputs such as figures and `.mat` result files.

## System Model

### PAM-M Symbol Mapping

Random input bits are grouped into symbols using `log2(M)` bits per symbol.
The project uses Gray coding so adjacent PAM levels differ by one bit, reducing
the bit-error impact of nearest-neighbor symbol errors.

The PAM alphabet is antipodal and normalized to unit average symbol energy:

```text
M = 2  -> [-1, +1]
M = 4  -> [-3, -1, +1, +3] / sqrt(mean(alpha^2))
M = 8,16 follow the same symmetric amplitude rule
```

The mapper and demapper are implemented directly in:

- `modulation/pamGrayMap.m`
- `modulation/pamGrayDemap.m`
- `modulation/grayToBinary.m`

No Communications Toolbox modulator is required.

### Pulse Shaping

Two transmitter pulse shapes are analyzed:

- **NRZ pulse**: rectangular pulse over one symbol interval
- **SRRC pulse**: square-root raised cosine pulse synthesized by frequency
  sampling

Both pulses are normalized so the simulation has consistent energy handling.
The pulse generation code is in:

- `filters/buildTxPulses.m`
- `filters/srrcFrequencySampling.m`

### AWGN Channel

The transmitted waveform is corrupted by white Gaussian noise. For a selected
`Eb/N0`, the simulator computes:

```text
Eb = Es / log2(M)
N0 = Eb / (Eb/N0)
noise_sigma = sqrt(N0 / 2)
```

This connects the discrete-time noise amplitude to the theoretical BER curves
used for validation.

### Receiver Processing

The receiver supports two filtering strategies.

The matched-filter case uses the time-reversed transmitter pulse and is used to
validate the simulator against theory.

The single-pole case uses a digital IIR low-pass filter synthesized from the
analog single-pole response through impulse invariance:

```text
a = exp(-2*pi*f3dB/SpS)
H(z) = (1 - a) / (1 - a z^-1)
```

The simulator sweeps the normalized `-3 dB` bandwidth and records the `Eb/N0`
required to reach `BER = 10^-3`.

## Simulation Workflow

Running `TLC_Lab2_Project.m` performs the full experiment:

1. Load simulation settings from `config/lab2Config.m`.
2. Build NRZ and SRRC transmit pulses.
3. Plot filter-synthesis evidence in the spectral domain.
4. Plot transmit PSD for the pulse shapes.
5. Run matched-filter BER validation for each PAM order.
6. Compare simulated BER with theoretical PAM-M BER.
7. Sweep single-pole receiver bandwidths.
8. Estimate the bandwidth that minimizes required `Eb/N0` at `BER = 10^-3`.
9. Generate eye diagrams for noiseless and noisy cases.
10. Save figures and numerical results to `results_lab2/`.

## Generated Results

The simulator produces:

- matched-filter BER curves for NRZ and SRRC
- theoretical BER overlays for PAM-M
- transmit PSD comparison
- SRRC and single-pole filter synthesis evidence
- `Eb/N0 @ BER = 10^-3` versus single-pole bandwidth
- eye diagrams for matched-filter and optimized single-pole receivers
- `lab2_results.mat` containing the configuration and result structures

## Final Report

The completed TLC Lab 2 report is available at:

```text
documentation/final_project_report.pdf
```

The report includes the required matched-filter validation, spectral-domain
filter synthesis evidence, PSD plots, eye diagrams, single-pole bandwidth
optimization plots, and a numerical Eb/N0 penalty summary.

## How To Run

Open MATLAB in the project folder and run:

```matlab
run('TLC_Lab2_Project.m')
```

The default configuration is intended for report-quality simulation curves.
For a quick smoke test, run from PowerShell:

```powershell
$env:TLC_LAB2_FAST='1'
matlab -batch "run('TLC_Lab2_Project.m')"
```

The fast mode reduces the number of PAM orders, Eb/N0 points, simulated bits,
and bandwidth sweep values. It is useful for checking that the full pipeline
works before launching a longer run.

## Configuration

Main parameters are centralized in `config/lab2Config.m`:

```matlab
cfg.Mlist = [2 4 8 16];
cfg.SpS = 16;
cfg.srrcBeta = 0.25;
cfg.srrcSpan = 12;
cfg.EbN0dB = 0:2:22;
cfg.berTarget = 1e-3;
cfg.singlePoleBw = linspace(0.08, 2.0, 25);
```

This makes it easy to adjust simulation accuracy, pulse bandwidth, sweep
resolution, and target BER without modifying the core algorithms.

## Design Choices

The implementation avoids relying on high-level communication-system toolbox
blocks for the core logic. Mapping, demapping, filter synthesis, BER theory,
PSD estimation, and sampling alignment are written explicitly. This makes the
project more transparent and shows the underlying signal-processing steps.

The code is modular because each experiment stage has a clear responsibility:

- `filters/` answers how the waveform is shaped or filtered.
- `modulation/` answers how bits become symbols and symbols become bits.
- `simulation/` answers how the channel and receiver are evaluated.
- `plotting/` answers how evidence is generated for the lab report.
- `utils/` contains reusable numerical helpers.

That separation makes the project easier to extend, for example by adding
QAM modulation, adaptive filtering, different pulse shapes, or another channel
model.

## Verification

The simulator was checked with MATLAB using the fast mode:

```powershell
$env:TLC_LAB2_FAST='1'
matlab -batch "run('TLC_Lab2_Project.m')"
```

The run completed successfully and regenerated the expected output files in
`results_lab2/`.

## Skills Reflected

This project demonstrates a blend of communication theory and practical
engineering implementation:

- digital communication system modeling
- Monte Carlo simulation
- statistical BER estimation
- signal normalization and noise calibration
- FIR and IIR digital filter design
- frequency-domain validation
- MATLAB project organization
- reproducible experiment design

It is a compact example of turning a theoretical lab specification into a
working, documented, and extensible engineering codebase.
