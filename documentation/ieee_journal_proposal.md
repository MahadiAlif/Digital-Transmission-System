# IEEE Journal Publication Proposal: The Volterra-PWL-MLP Equalizer

To elevate your master's thesis to a level suitable for an **IEEE Journal** (such as *IEEE Communications Letters* or *IEEE Photonics Technology Letters*), we must introduce a **clear, novel contribution** that addresses a major open problem in the field.

In telecommunications, the primary critique of Neural Network (NN) equalizers is their **computational complexity**. Real-time receivers operating at Gigabaud rates cannot afford the massive power and area required by standard MLPs.

Therefore, we propose a novel, hardware-efficient architecture: the **Volterra-Featured Piecewise-Linear MLP (Volterra-PWL-MLP)**.

---

## 💡 The Novel Concept: Volterra-PWL-MLP

Instead of using a deep, standard MLP that takes raw samples and has to learn both the linear and non-linear relationships from scratch, we split the task:
1. **Analytical Feature Extraction (Volterra Kernels):** We hand-engineer low-order non-linear features (e.g., second and third-order interactions like $y(k)y(k-1)$) and feed them directly to the input of the neural network.
2. **Shallow MLP Classifier/Equalizer:** Because the non-linear features are already explicit, the neural network only needs a **very shallow structure** (e.g., a single hidden layer with only $4$ to $6$ neurons) to map them to the correct symbol.
3. **Multiplier-Free Activation (PWL-Tanh):** We replace the standard transcendental $\tanh(x)$ with a custom, multiplier-free Piecewise-Linear (PWL) activation function that uses only bit-shifts and additions.

This combination allows you to achieve the non-linear correction performance of a deep MLP at a **fraction of the computational cost**, making it highly attractive for real-time embedded DSP engines.

```mermaid
graph TD
    Rx[Received Samples y(k)] --> Volt[Volterra Feature Extractor]
    Rx --> Lin[Linear Samples]
    Volt --> |Cross-Products<br>y(k)y(k-d)| Feat[Input Feature Vector<br>x(k)]
    Lin --> Feat
    Feat --> MLP[Shallow MLP Equalizer<br>1 Hidden Layer: 4-6 Neurons]
    MLP --> PWL[PWL-Tanh Activation<br>Multiplier-Free]
    PWL --> Slicer[Threshold Slicer]
    Slicer --> Dec[Decided Symbol]
    
    style MLP fill:#1f2937,stroke:#3b82f6,stroke-width:2px,color:#fff
    style PWL fill:#111827,stroke:#10b981,stroke-width:2px,color:#fff
```

---

## 📝 Key Research Contributions for the Paper

Your paper will present three core contributions:

1. **A Hybrid Feature-Driven Network Architecture:** Showing that feeding Volterra kernels into a shallow MLP out-performs both standard Volterra filters (which are linear in their parameters) and deep MLPs (which require heavy training).
2. **A Multiplier-Free Activation Scheme:** Proposing a PWL approximation of tanh, proving mathematically and via simulation that it preserves the BER performance while saving $100\%$ of activation multipliers.
3. **A Joint BER-Complexity Trade-off Analysis:** Plotting a Pareto frontier of **BER vs. Multiplications per Symbol** to show that your model achieves the best performance-to-complexity ratio.

---

## 🛠️ Step-by-Step Implementation in Your Codebase

We can implement this step-by-step in your MATLAB project to generate the required journal figures.

### Step 1: Volterra Feature Extraction (in `utils/extractVolterraFeatures.m`)
Create a helper function to generate the inputs. For a memory depth $D$ and non-linear order $P=3$, the features for symbol $k$ are:
* **Linear:** $y(k), y(k-1), \dots, y(k-D)$
* **Quadratic:** $y(k)y(k-1), y(k)y(k-2), \dots$
* **Cubic:** $y^2(k)y(k-1), y^3(k), \dots$

```matlab
function X_feat = extractVolterraFeatures(samples, D)
    % Samples: N x 1 vector of symbol-rate samples
    N = length(samples);
    padded = [zeros(D, 1); samples(:)];
    
    % We will extract:
    % - Linear taps: y(k), ..., y(k-D)
    % - Quadratic taps: y(k)*y(k-1), y(k-1)*y(k-2)
    % - Cubic taps: y^3(k)
    numLinear = D + 1;
    numQuadratic = D;
    numCubic = 1;
    totalFeatures = numLinear + numQuadratic + numCubic;
    
    X_feat = zeros(N, totalFeatures);
    for k = 1:N
        % Shifted window
        win = padded(k : k + D); % [y(k-D), ..., y(k)]
        win_rev = flipud(win);   % [y(k), ..., y(k-D)]
        
        % Linear features
        X_feat(k, 1:numLinear) = win_rev.';
        
        % Quadratic cross-products: y(k)*y(k-1), y(k-1)*y(k-2)...
        quad = zeros(1, numQuadratic);
        for d = 1:D
            quad(d) = win_rev(d) * win_rev(d+1);
        end
        X_feat(k, numLinear + (1:numQuadratic)) = quad;
        
        % Cubic feature: y^3(k)
        X_feat(k, end) = win_rev(1)^3;
    end
end
```

### Step 2: Multiplier-Free PWL Activation (in `utils/pwlTanh.m`)
Implement the piecewise-linear tanh approximation. In hardware, multiplying by $0.5$ or $0.25$ is just a bit-shift (`>> 1` or `>> 2`), which requires no DSP multipliers.

$$f(x) = \begin{cases} 
-1, & x < -1.5 \\ 
0.5x - 0.25, & -1.5 \le x < -0.5 \\
x, & -0.5 \le x \le 0.5 \\
0.5x + 0.25, & 0.5 < x \le 1.5 \\
1, & x > 1.5
\end{cases}$$

```matlab
function y = pwlTanh(x)
    y = zeros(size(x));
    
    % Region 1: x < -1.5
    y(x < -1.5) = -1;
    
    % Region 2: -1.5 <= x < -0.5 (y = 0.5*x - 0.25)
    idx2 = (x >= -1.5) & (x < -0.5);
    y(idx2) = 0.5 * x(idx2) - 0.25;
    
    % Region 3: -0.5 <= x <= 0.5 (y = x)
    idx3 = (x >= -0.5) & (x <= 0.5);
    y(idx3) = x(idx3);
    
    % Region 4: 0.5 < x <= 1.5 (y = 0.5*x + 0.25)
    idx4 = (x > 0.5) & (x <= 1.5);
    y(idx4) = 0.5 * x(idx4) + 0.25;
    
    % Region 5: x > 1.5
    y(x > 1.5) = 1;
end
```

### Step 3: Complexity Analysis Table (Mathematical Proof)
To publish, you must prove the complexity reduction. You will present a table counting the number of real operations per symbol:

| Equalizer Model | Multiplications | Additions | Non-linear Activations |
| :--- | :---: | :---: | :---: |
| **LMS Linear Equalizer** | $N_{taps}$ | $N_{taps}-1$ | $0$ |
| **Volterra Equalizer (3rd Order)** | $N_{volterra}$ | $N_{volterra}-1$ | $0$ |
| **Standard MLP (Float Tanh)** | $W \cdot H + H \cdot 1$ | $W \cdot H + H \cdot 1$ | $H$ CORDIC/Taylor Tanh (Expensive) |
| **Proposed Volterra-PWL-MLP** | $V \cdot H_{small} + H_{small} \cdot 1$ | $V \cdot H_{small} + H_{small}$ | **$H_{small}$ Bit-Shifts & Comparisons (Cheap)** |

*(Where $W$ is the input window size, $V$ is the small Volterra feature size, and $H$ is the number of hidden units. Typically $V \cdot H_{small} \ll W \cdot H$)*

---

## 📈 Suggested IEEE Journal Outlets

For a master's student with a supervisor co-author, the best targets are **Letters journals** because they are short (4 to 5 pages), have fast turnaround times (typically 6-8 weeks for a decision), and focus on concrete, highly focused engineering improvements:

1. **IEEE Communications Letters**
   * *Scope:* High-quality, fast-turnaround communications papers.
   * *Fit:* Excellent for baseband DSP and receiver equalization architectures.
2. **IEEE Wireless Communications Letters**
   * *Scope:* Short papers on physical-layer wireless systems.
   * *Fit:* Good if you frame the PAM simulation as a backhaul or wireless link.
3. **IEEE Photonics Technology Letters** (or *Journal of Lightwave Technology*)
   * *Scope:* Optical communications hardware and DSP.
   * *Fit:* Highly recommended if we frame the PAM-16 link as an **Intensity-Modulation Direct-Detection (IM/DD) short-reach optical interconnect**. This is where PAM-16 and non-linearities are most relevant in industry today.
