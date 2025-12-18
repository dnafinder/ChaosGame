# ChaosGame

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=dnafinder/ChaosGame&file=ngonChaosGame.m)

## 🧩 Overview
ChaosGame is a MATLAB implementation of the chaos game on a regular N-gon (N ≥ 5). At each iteration, a vertex is selected (optionally under exclusion rules) and the current point is moved toward that vertex by a fixed contraction ratio. The default ratio is computed automatically using the “kissing/optimal ratio” for the chosen polygon order.

The function includes a reel-like animation mode: the diagonal from the current point to the selected vertex appears, the new point is fixed, and the diagonal disappears, then the process repeats.

## ✨ Features
- Regular N-gon chaos game (N ≥ 5) with minimal required input (only N).
- Automatic selection of the “optimal/kissing” ratio via a closed-form rule based on N mod 4.
- Optional exclusion rules:
  - none (standard chaos game)
  - no repeat (cannot choose the same vertex twice in a row)
  - no adjacent (cannot choose the same or adjacent vertices)
  - no neighbors (cannot choose adjacent vertices)
  - custom offset-based exclusion (ExcludeOffsets)
  - fully custom selection function (RuleFcn)
- Reel-like animation:
  - diagonal appears → point is fixed → diagonal disappears
  - hybrid mode: animate first steps, then render the remaining points quickly
- Polygon outline is always shown when plotting/exporting.
- Optional export to PNG and AVI.

## 🧠 Selection Logic
### Vertex update rule
Given a current point x_k and a selected vertex v_j, the update is:

    x_{k+1} = (1 - r) * x_k + r * v_j

where r is the contraction ratio.

### Ratio = "auto" (kissing/optimal ratio)
When Ratio is set to "auto" (default), the function uses a closed-form kissing ratio depending on N mod 4:

- If N mod 4 = 0:
  r = 1 / (1 + tan(pi / N))

- If N mod 4 = 2:
  r = 1 / (1 + sin(pi / N))

- If N mod 4 = 1 or 3:
  r = 1 / (1 + 2 * sin(pi / (2N)))

This ratio is commonly used to produce an “optimally packed” chaos game attractor for the regular N-gon.

### Exclusion rules (precedence)
Selection constraints are applied with the following precedence:
1) RuleFcn (highest priority)
2) ExcludeOffsets
3) Rule (string preset)

If a constraint yields an empty set of allowed vertices, the function throws an error.

## 📦 Installation
1) Download or clone the repository into a folder on your MATLAB path.
2) Ensure ngonChaosGame.m is visible from the MATLAB Current Folder or is on the path.

## ✅ Requirements
- MATLAB R2018b or later recommended.
- For MP4 export: VideoWriter support (typically available in standard MATLAB installations).

## 🚀 Usage
### Minimal (defaults)
    ngonChaosGame(7)

Defaults include:
- nIter = 200000
- Ratio = "auto"
- Animate = true
- AnimateSteps = 4000
- BurnIn = 50

### Fast (no animation)
    ngonChaosGame(9, 'Animate', false, 'nIter', 800000)

### Manual ratio
Ratio must satisfy 0 < Ratio < 1.5:

    ngonChaosGame(11, 'Ratio', 0.73, 'Animate', false, 'nIter', 500000)

### Exclusion rules
No repeat (cannot select the same vertex consecutively):

    ngonChaosGame(7, 'Rule', 'noRepeat')

No adjacent (cannot select same or adjacent vertices):

    ngonChaosGame(7, 'Rule', 'noAdjacent')

Offset-based exclusion (forbid same and neighbors relative to previous vertex):

    ngonChaosGame(7, 'ExcludeOffsets', [0 1 -1])

Custom rule function
RuleFcn must return allowed vertex indices in 1..N:

    f = @(prev, hist, N) setdiff(1:N, prev);
    ngonChaosGame(11, 'RuleFcn', f)

### Export PNG
    ngonChaosGame(7, 'Animate', false, 'PngFile', 'ngon7.png', 'Dpi', 300)

### Export AVI (records during animation)
    ngonChaosGame(7, 'VideoFile', 'ngon7.avi', 'Fps', 30, 'AnimateSteps', 6000)

## 📝 Notes
- The polygon outline is always drawn when plotting/exporting.
- Hybrid rendering is used by default: the first AnimateSteps iterations show the diagonal per-step; the rest are rendered in batches for speed.
- If Ratio > 1 (allowed by the validation up to 1.5), points may overshoot the polygon; the plotting window automatically zooms out to keep the trajectory in view.
- For maximum speed with strict exclusion rules, consider using Rule presets that can be optimized via precomputed allowed sets (future enhancement).

## 📚 References
- Chaos game (overview and kissing ratio formulas): Wikipedia, “Chaos game”.

## 📌 Citation
If you use this code in academic work, please cite the repository:

Cardillo, G. ChaosGame (MATLAB): N-gon chaos game with optimal ratio and exclusion rules. GitHub repository dnafinder/ChaosGame.

## 👤 Author
Giuseppe Cardillo  
giuseppe.cardillo.75@gmail.com

## 📄 License
See the LICENSE file in this repository.
