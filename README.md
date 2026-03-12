# EEE4120F Practical 2 Repository

Analyze the correctness, speed-up, and parallel efficiency of using MATLAB's
`parfor` parallel execution model against the serial "golden standard" implementation
of a simple embarassingly-parallel algorithm to check membership of the Mandelbrot
set for samples taken in the complex plane.

# To Run

## With MATLAB

1. Open MATLAB with the repository directory open (GUI or CLI).
2. `run_analysis`

# Data

## Values
An `analysis_results.csv` file will be generated after running.

## Visuals

Resulting colour-mapped Mandelbrot set images are output to
`serial_output_images` and `parallel_output_images` during execution of 
`run_analysis`.

Sppedup graphs will be plotted in MATLAB at the end of `run_analysis`.
