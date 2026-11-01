# Task

The xFusionCorp Industries data science team requires a standardized Python environment for their new machine learning project. Set up a virtual environment on the `controlplane` host that includes all necessary ML libraries.

The work is done on the `controlplane` host under `/root/code/`.

The end state must satisfy the following:

- a Python virtual environment named `ml-env` exists under `/root/code/`;
- the environment has `numpy`, `pandas`, `scikit-learn`, and `matplotlib` installed;
- a `requirements.txt` capturing the installed packages is saved at `/root/code/requirements.txt`.

## Objective

Create a reproducible Python environment for the machine learning project so the team can install and use the required libraries without environment conflicts.

## Requirements

1. Create the project virtual environment in `/root/code/ml-env`.
2. Activate the environment and install the required ML packages.
3. Verify the environment contains the expected libraries.
4. Save the package versions to `/root/code/requirements.txt`.
5. Ensure the setup is reproducible for future runs or team members.

## Validation

Confirm the following:

- `/root/code/ml-env` exists and is a valid Python virtual environment.
- `python`, `pip`, and the installed libraries are available inside the virtual environment.
- `/root/code/requirements.txt` contains the pinned package versions.
