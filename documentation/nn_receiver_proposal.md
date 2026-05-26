# Thesis Proposal Refinement: NN-Assisted PAM Receiver

This document provides a rigorous academic refinement of the initial neural-network-assisted PAM receiver proposal, integrating the constraints and guidance provided by your thesis advisor:
* **Model Type:** Multi-Layer Perceptron (MLP) for filtering/equalization.
* **Input Dimension:** $7$ to $16$ samples (sliding window).
* **Network Depth:** $1$ or $2$ hidden layers.
* **Network Width:** $10$ to $20$ neurons per hidden layer.

---

## 🔍 Critique of the Codex Two-Stage Proposal

The initial proposal suggested a **two-stage** framework: a **Verifier** (binary classification to check reliability) followed by a **Corrector** (multi-class classification to correct suspicious decisions).

While conceptually interesting, this architecture has several major drawbacks for a master's thesis in telecommunications engineering:

1. **Error Propagation (Cascading Failures):** If the Verifier commits a *false negative* (decides a wrong symbol is correct with high confidence), the Corrector is never triggered, and the error is locked in.
2. **Computational Latency & Branching:** In high-speed DSP hardware (like FPGAs or ASICs), conditional branching (`if confidence < threshold then run Corrector`) introduces variable processing latency. High-speed communication links require deterministic, pipelined data flows. A single-stage, fixed-latency architecture is highly preferred.
3. **Hyperparameter Tuning Complexity:** The system introduces an artificial "confidence threshold" parameter. Optimizing this threshold across different SNR ($E_b/N_0$) values adds significant experimental overhead without theoretical justification.
4. **Double Training Overhead:** Training two separate neural networks (one binary, one multi-class) increases the training complexity and data storage requirements.

---

## 🛠️ Refined Architectures (Advisor-Compliant)

To align with your professor's instructions, we propose replacing the two-stage model with a **single-stage MLP** that acts directly as a **Non-Linear Equalizer (NLE)** or a **Joint Filter-Classifier**. 

Below are the three best alternatives, ranked by their suitability for a thesis.

### Option A: MLP-Based Non-Linear Equalizer (Recommended)
In this configuration, the MLP acts as a direct replacement for the classical equalizer (e.g., Feed-Forward Equalizer, FFE). It takes a window of received samples and outputs a single real number representing the equalized symbol, which is then sliced by a classical threshold detector.

```mermaid
graph LR
    Rx[Rx Filtered Samples] --> Buf[Sliding Window Buffer<br>7 to 16 samples]
    Buf --> MLP[MLP Equalizer<br>Input: 7-16<br>Hidden: 1-2 layers, 10-20 neurons<br>Output: 1 neuron, Linear]
    MLP --> Sl[Threshold Slicer]
    Sl --> Dec[Final Symbol Decision]
    
    style MLP fill:#1f2937,stroke:#3b82f6,stroke-width:2px,color:#fff
```

* **Inputs:** $7$ to $16$ consecutive received samples $[r(k-L), \dots, r(k), \dots, r(k+R)]$.
* **Hidden Layers:** $1$ or $2$ layers, $10$ to $20$ neurons each (with ReLU or Tanh activations).
* **Output Layer:** $1$ neuron with linear activation, representing the estimate $\hat{y}(k)$ of the transmitted symbol amplitude.
* **Why it is strong for a thesis:**
  * **Direct Comparison:** You can compare the MLP directly against a classical linear equalizer (like a Least Mean Squares (LMS) or Recursive Least Squares (RLS) equalizer) of the same tap length ($7$ to $16$).
  * **Non-linear Compensation:** You can easily simulate a channel with non-linearities (e.g., power amplifier saturation or fiber-optic Kerr effect) and show that the MLP vastly outperforms classical linear equalizers because it can learn non-linear decision boundaries.

---

### Option B: MLP Joint Equalizer & Classifier
This configuration completely bypasses the classical threshold slicer. The MLP directly classifies which of the $M$ PAM symbols was transmitted.

```mermaid
graph LR
    Rx[Rx Filtered Samples] --> Buf[Sliding Window Buffer<br>7 to 16 samples]
    Buf --> MLP[MLP Classifier<br>Input: 7-16<br>Hidden: 1-2 layers, 10-20 neurons<br>Output: M neurons, Softmax]
    MLP --> Dec[Class Index with Max Prob]
    
    style MLP fill:#111827,stroke:#10b981,stroke-width:2px,color:#fff
```

* **Inputs:** $7$ to $16$ received samples.
* **Hidden Layers:** $1$ or $2$ layers, $10$ to $20$ neurons each.
* **Output Layer:** $M$ neurons with Softmax activation (where $M = 2, 4, 8, \text{ or } 16$ is the PAM order). The output represents the probability distribution over the PAM constellation points.
* **Why it is strong for a thesis:**
  * **Maximum Likelihood Approximation:** Under severe inter-symbol interference (ISI), the optimal receiver (sequence estimation) is highly complex. The MLP classifier acts as a low-complexity approximation of the optimal boundary.
  * **Soft Outputs:** The softmax probabilities can be forwarded directly to a Soft-Input Soft-Output (SISO) channel decoder (like a Viterbi or LDPC decoder) in a full receiver chain.

---

### Option C: Residual NN-Assisted Decision (Hybrid)
This option keeps the classical receiver fully intact. The MLP is placed in parallel and only predicts the *residual error* or the *correction term* to adjust the equalized sample before slicing.

```mermaid
graph TD
    Rx[Rx Filtered Samples] --> EQ[Classical Equalizer]
    EQ --> Slicer[Threshold Slicer]
    
    Rx --> Buf[Sliding Window Buffer<br>7 to 16 samples]
    Buf --> MLP[MLP Error Predictor]
    
    EQ --> Add((+))
    MLP --> Add
    Add --> Slicer
    Slicer --> Dec[Final Symbol Decision]
    
    style MLP fill:#18181b,stroke:#f59e0b,stroke-width:2px,color:#fff
```