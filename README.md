# Artifact for: "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

This artifact contains sources and precompiled binaries of **Storm 2.0** and **stormpy 2.0**, all benchmarks and scripts of the experiments of Sec. 8 of the tool paper "The Probabilistic Model Checker Storm: Lightning Strikes Twice", and the logs and results of the runs shown in the paper. 
It reproduces Figures 6, 7, 8, and 9.
In addition, it contains **TODO** FILL WITH MODEST/PRISM INFO
All tools and experiments run in the provided Docker images.

We apply for the Available, Functional and Reusable badges.

## Getting started
Check the [requirements](#requirements), then follow the steps in this order:

1. [Load the Docker images](#step-1-load-the-docker-images) (at most 10 minutes).
2. [Run the smoke test](#step-2-run-the-smoke-test) of the experiment set you want to run (at most 5 minutes).
3. [Run the experiment set](#step-3-run-an-experiment-set) (hours to days, depending on the bechmark set and set-up).
4. [Create the figures from the logs](#step-4-create-the-figures-from-logs), of your run or of the runs of the paper (at most a few minutes).
5. Optionally, [play with Storm and stormpy](#step-5-play-with-storm-and-stormpy).

## Overview
The artifact consists of three parts:
- **Storm 2.0**, the probabilistic model checker presented in the paper: its source code in `storm/`, and in the Docker images `storm2-experiments` and `storm2-tools`.
- **stormpy 2.0**, the Python API of Storm (Sec. 7 of the paper): its source code in `stormpy/`, with the robot vacuum example of the paper in `examples/vacuum/`. We additionally provide an updated version the Jupyter notebooks of the Storm tutorial given at FM '26 in `notebooks/`.
- **The experiments** of Sec. 8 of the paper, which compare Storm with other tools on MDPs and interval MDPs, and showcase its POMDP functionality: the scripts to run them in `scripts/`, the experiments and their Docker image in `experiments/`, the benchmarks in `examples/`, and the logs and results of the runs in the paper and of sample runs of all experiment sets with this artifact in `results/`.

[TOOLS.md](TOOLS.md) describes how you can try out Storm and stormpy yourself.

Section [Contents](#contents) near the end of this README lists all folders.

## Requirements
We provide three experiment sets for reproducing (subsets of) the experiments in the paper, described in [The experiment sets](#the-experiment-sets). 
Run the largest one that fits your hardware and time constraints; the times are generous estimates based on our runs, so we expect most runs to be faster.

| Experiment set   | Needs at least  | Takes about | With `-p`, 4 parallel runs   |
| ---------------- | --------------- | ----------- | ---------------------------- |
| [Minimal]        | 3 cores, 9 GiB  | 7 hours     | 2 hours (9 cores, 33 GiB)    |
| [Representative] | 5 cores, 17 GiB | 7 hours     | 2 hours (17 cores, 65 GiB)   |
| [Full]           | 5 cores, 33 GiB | 85 hours    | 22 hours (17 cores, 129 GiB) |

[Minimal]: #minimal
[Representative]: #representative
[Full]: #full

All cores are counted in **physical cores**. 
On a larger machine, option `-p` allows running several benchmarks in parallel; see [Parallel execution](#parallel-execution). 
Every machine additionally requires **Docker** and **90 GB of free disk space**: about 60 GB for the loaded images, and the rest for the downloaded and unpacked artifact (about 12 GB each). 
No network access is needed.

The artifact runs on Linux and macOS, on x86 (amd64) and ARM (arm64) CPUs. 
On ARM, the comparison with the previous version **Storm 1.6.2 is left out**, as Storm 1.6.2 only exists for x86.
On macOS, the cores and memory are those given to the virtual machine of Docker Desktop, which can be set under Settings → Resources.

We tested the artifact on amd64 hosts running Linux (Debian forky/sid with Linux 6.18 and Docker 29.4, with both the containerd and the classic image store) and on a MacBook Pro (13-inch, M1, 2020) (ARM processor) running macOS 26.6.2 with Docker Desktop 4.97.0. 

## Step 1: Load the Docker images
1. Install [Docker](https://docs.docker.com/get-started/get-docker/).
2. Download `storm2-artifact.zip` from [Zenodo](https://doi.org/10.5281/zenodo.23668956) and unzip it at a convenient location. Throughout this document, `$ARTIFACT_DIR` refers to the unzipped directory `storm2-artifact/`, which contains this README as `README.md`.
3. Load the Docker images, `storm2-experiments` for the experiments and `storm2-tools` for [playing with Storm and Stormpy](#step-5-play-with-storm-and-stormpy):[^privileged]
   ```bash
   $ARTIFACT_DIR/scripts/1_load.sh
   ```
   This takes up to 10 minutes, and shows the progress of every layer of the images. The saved images are [multi-platform images](https://docs.docker.com/build/building/multi-platform/) for amd64 and arm64. Docker keeps the one suitable for your machine. 
   
   If loading fails, enable the *containerd* image store and try again:
    - Docker Desktop: Settings → General → enable "Use containerd for pulling and storing images",
    - Docker Engine: set `"features": {"containerd-snapshotter": true}` in `/etc/docker/daemon.json` and restart Docker.

[^privileged]: The scripts start the container with the options `--privileged --cap-drop=all`. These let the experiment runner pin every run to its own cores and enforce its memory limit; all other privileges are dropped.

## Step 2: Run the smoke test
After loading the images, run the smoke test.
It checks that the tool configurations and post-processing are working and that your machine can run the selected experiment set.

To run the smoke test for the experiment set `representative`, run

```bash
$ARTIFACT_DIR/scripts/2_smoke.sh representative
```

Replace `representative` by `minimal` or `full` to run the smoke test for the respective set instead.
CPU cores and memory per run are determined by the selected experiment set, see [Requirements](#requirements).
If your hardware provides insufficent CPU cores or memory for the selected set, the smoke test stops right away and outputs `not enough cores or memory for a single run`.

The smoke test includes a test run on one small benchmark with a time limit of 60 seconds for

- MDPs: every tool and configuration from the experiments,
- interval MDPs: every tool and configuration from the experiments, and
- POMDPs: one cut-off and one discretisation configuration.

After the full run has finished, the smoke test post-processes the results and tests building the figures.
Overall, the smoke test should take at most 5 minutes; on our machines it took about a minute.

After the test has finished, check the following:
- In the command-line output, each run should end with `ok` in its line `[done ...] CONFIGURATION BENCHMARK ... ok (...)`. On ARM, the runs of Storm 1.6.2 (`storm-old-sound`, `storm-old-exact`) should indicate `skipped`.
- The command-line output should end with a summary of the three experiments and `== all results checked`.
- Your current directory should contain a file `smoke-SET.pdf`, where `SET` is your selected experiment set, e.g. `smoke-representative.pdf`. The file should contain variants of Figures 6, 7, 8 and 9 of the paper, with only one point in each scatter plot and in each panel of Figure 9.
- Your current directory should contain a directory `smoke-SET/`, containing logs and additional result data.

If the command-line output ends with `== results with problems in:`, some run did not yield correct results.
This indiactes a failure of the smoke test.

If you encounter this or any other issue with the smoke test, please provide a zip containing the command-line output, `smoke-SET.pdf` and `smoke-SET/` with a description of your issues.

## Step 3: Run an experiment set
To run all experiments for experiment set `representative`, run

```bash
$ARTIFACT_DIR/scripts/3_run.sh representative
```

Replace `representative` by `minimal` or `full` to run the respective experiment set instead.

Add option `-p` to parallelise execution, e.g. `scripts/3_run.sh representative -p`.
This executes as many runs in parallel your set-up allows.
See [Parallel execution](#parallel-execution) for more details.

The experiments run in a container in the background, so they continue even if the script is aborted or the terminal is closed.
Executing the `3_run.sh` script in the same directory again waits for any running exections to finish and then copies the results. 
To abort running the experiments, execute `docker rm -f storm2-SET`, e.g. `docker rm -f storm2-representative`.
This also deletes any logs of already finished runs.
A restart of Docker or the machine cancels a running experiment set.
An aborted run of an experiment set cannot be resumed.

Running an experiment set `SET` generates the figures in `SET.pdf` and places the logs and result data in `SET/` in the current directory, e.g. `representative.pdf` and `representative/`. 
Like the smoke test, the command-line output should end with `== all results checked`.
Some individual runs end with `timeout` or `memout`; this is expected behaviour.

After the experiment set run has finished, you can compare your output with the paper.
Section [The experiment sets](#the-experiment-sets) describes how experiment sets `minimal` and `representative` differ from the full set, and which deviations in the results are expected.
As **Storm 1.6.2 is missing for ARM set-ups**, Figure 6 in `SET.pdf` is missing the corresonding information for runs on an ARM set-up:
the lines for Storm 1.6.2 in the quantile plots are empty, and the scatter plot against it shows only n/a.
Due to absolute runtimes depending on the machine, we recommend to compare the figures in `SET.pdf` with those in the paper in terms of general trends, in particular comparing relative performance of different tools and configurations.

We additionally provide sample output for all three experiment sets, generated using this artifact, in `$ARTIFACT_DIR/results/artifact/`, e.g. `representative.pdf` and `representative/`.
You can compare your output for the corresponding set against those.

## Step 4: Create the figures from logs
You can generate Figures 6 to 9 from the logs of *any* experiment run using

```bash
$ARTIFACT_DIR/scripts/4_figures.sh path/to/DIR
```

where `DIR` is a folder of logs, e.g. 

- `representative/` of your own run from Step 3,
- `$ARTIFACT_DIR/results/artifact/full/` of the sample run of the full experiments, or
- `$ARTIFACT_DIR/results/paper/` of the runs of the paper.

`DIR` must follow the layout of the generated runs.

The command processes all logs in `DIR` and writes the figures to `DIR-figures.pdf` in the current directory, e.g. `paper-figures.pdf`. 
This may take a few minutes.

[results/paper/README.md](results/paper/README.md) describes the logs and results of the paper.
The figures and results of sample runs for experiment sets ``minimal``, ``representative`` and ``full``  and their smoke tests, generated using this artifact, are located in `$ARTIFACT_DIR/results/artifact/`.

## Step 5: Play with Storm and Stormpy
[TOOLS.md](TOOLS.md) describes Storm and stormpy, and how to try them out in the Docker image `storm2-tools` of the artifact.
In particular, it describes how to run
- Storm on the robot vacuum example of the paper (Sec. 7), which is located in `examples/vacuum/`,
- Storm on the benchmarks of the experiments in `examples/`,
- the Stormpy code of Fig. 4 of the paper, and
- the (updated) Jupyter notebooks of the FM '26 Storm tutorial in `notebooks/`.

## The experiment sets
All three experiment sets run all experiments on different benchmark sets with different amounts of cores and memory. 
They all produce variants of Figures 6 to 9 in the paper:
- **Figure 6**: comparison of Storm 2.0's MDP model checking performance with mcsta, PRISM and the previous version Storm 1.6.2, and of the configurations of Storm compared with each other (experiment `mdp`).
- **Figure 7**: effects of bisimulation minimisation in Storm (experiment `mdp`).
- **Figure 8**: comparison of Storm, PRISM and IntervalMDP.jl on interval MDPs (experiment `imdp`).
- **Figure 9**: showcase of the belief exploration of Storm for POMDPs with different size limits (experiment `pomdp`).

### Full
The `full` experiment set replicates all 1759 runs (957 of `mdp`, 156 of `imdp` and 646 of `pomdp`) from the paper using the hardware restrictions used for the paper experiments.
It runs every considered configuration on all benchmarks with a time limit of 900 seconds, 4 physical CPU cores and 32 GiB of memory per run.
In the worst case, a complete run of the full experiment set takes up to 85 hours (without parallelisation).
From our experiments, we estimate the actual runtime to be about 71 hours (based on summing up all individual runtimes).

### Representative
The `representative` experiments run all tool configurations on a *subset* of the benchmarks:

- 53/98 MDPs
- 32/52 interval MDPs
- 8/19 POMDPs

This results in a total of 885 individual runs.
The time limit is reduced to 90 seconds (from 900s in `full`).
Each individual run is allocated 16 GiB of memory (instead of 32 GiB in `full`). 

The benchmarks are chosen as a representative subset where results exhibit the same trends as the full set, even under reduced resources.
With the decreased time limit, more runs time out than in the paper.

### Minimal
The `minimal` experiment set considers the same subset of the benchmarks as `representative`, resulting in a total of 885 individual runs.
As for `representative`, the time limit is set to 90 seconds.

However, to allow exection on smaller machines with stricter hardware limitations, the number of physical CPU cores is reduced to 2 (instead of 4 for `full` and `representative`).
Furthermore, memory is limited to 8 GiB per individual run (instead of 32 GiB in `full` and 16 GiB in `representative`).

For the `minimal` experiment set, Storm's symbolic engines use 2 instead of 4 threads, PRISM is allocated 8 GiB for Java, and for both Storm and PRISM, the decision diagram libraries of both (Sylvan and CUDD) are allocated 4 GiB instead of 8 GiB. 
More runs time out or run out of memory, in particular those of the symbolic engines of Storm and of PRISM. 
The results thus deviate more from those presented in the paper than results obtained using `representative` or `full`.

**We therefore only recommend using the `minimal` experiment set if your machine does not allow running `representative` or `full` due to hardware limitations.**

### Running your own benchmarks
The scripts of the experiments can also run all tool configurations of the MDP experiment on your own models, and check and compare their results and runtimes; see [Running your own benchmarks](experiments/README.md#running-your-own-benchmarks) in the experiment README. 
That README also describes how the experiments can be customised and run individually, and how to set up the host for stable timings.

## Parallel execution
With the option `-p` (e.g. `scripts/3_run.sh representative -p`), `scripts/2_smoke.sh` and `scripts/3_run.sh` parallelise individual runs.
Parallelisation runs as many jobs as possible, while respecting the resource limitations of the selected experiment set for each individual run.
Every individual run is still pinned to its own physical cores and limited in memory, and additionally, one physical core and 1 GiB of memory are reserved for the system. 
At the start of every experiment, the output shows how many runs fit (`fitting jobs: ...`) and how many run at a time (`jobs: ...`).

Every individual run is assigned 2 physical cores and 8 GiB of memory in the minimal experiments, 4 physical cores and 16 GiB in the representative experiments, and 4 physical cores and 32 GiB in the full experiments; the smoke test for a set uses the same. 
For convenience, we list the hardware requirements (including the reserved CPU core and memory) for parallelising up to 4 runs in the different experiment sets:

| Parallel Runs  | Minimal         | Representative   | Full              |
| -------------- | --------------- | ---------------- | ----------------- |
| 1              | 3 cores, 9 GiB  | 5 cores, 17 GiB  | 5 cores, 33 GiB   |
| 2              | 5 cores, 17 GiB | 9 cores, 33 GiB  | 9 cores, 65 GiB   |
| 3              | 7 cores, 25 GiB | 13 cores, 49 GiB | 13 cores, 97 GiB  |
| 4              | 9 cores, 33 GiB | 17 cores, 65 GiB | 17 cores, 129 GiB |

Each further parallel run increases the requirement by the number of cores and amount of memory for an individual run in the corresponding experiment set.
Only physical cores count: the second hardware thread of a core (hyperthreading) stays idle.
The memory is the total memory that Linux reports in `/proc/meminfo`, which is typically less than the installed memory; on macOS, the cores and memory are those given to the virtual machine of Docker Desktop.

For timings that are as stable as possible follow [Additional setup](experiments/README.md#additional-setup).

## Differences between Storm 2.0 and the Storm used for the paper
The experiments in the submitted paper were done on a beta version of Storm 2.0, commit [`276d4fe0a5`](https://github.com/stormchecker/storm/commit/276d4fe0a56ee61952e4d5e04ce5f69c19f216eb) of the Storm repository (13 October 2026), which reports itself as version `1.14.0 (dev)` in the logs. In this artifact we provide the stable release of Storm and Stormpy 2.0. 
None of the changes between the beta and the stable release affect performance.
We provide results generated using the stable release, shipped wih this artifact, in `$ARTIFACT_DIR/results/artifact/full/`.
Corresponding figures are given in `$ARTIFACT_DIR/results/artifact/full.pdf`, and we will replace all figures in the paper with these results.

## License
Storm is licensed under the license located at `storm/LICENSE`, Stormpy under the license located at `stormpy/LICENSE`, and the notebooks under the license located at `notebooks/LICENSE` (all GPL-3.0).
The Modest Toolset is licensed under the license located at `experiments/docker/modest/License.txt` (also `Modest/License.txt` in the zips in that folder), which permits its redistribution as part of this artifact.
All other contents are licensed under the [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) license, see `LICENSE`.

## The artifact
### Contents

| Path | Description |
| --- | --- |
| `scripts/` | Scripts to replicate the experiments, following the steps of this README: `1_load.sh` loads the images, `2_smoke.sh SET` runs the smoke test for a set and `3_run.sh SET` the set itself, both in a container through `experiments/docker/run_in_container.sh`, and `4_figures.sh DIR` creates the figures from the logs in `DIR`; in addition, `5_build_docker.sh` builds and saves the images, and `6_create_artifact.sh` creates the artifact |
| `results/` | `paper/` the logs, results and figure data of the runs in the paper (see [results/paper/README.md](results/paper/README.md)), and `artifact/` the pdf, logs and results of sample runs of the smoke tests of all three sets and of `scripts/3_run.sh` for all three sets |
| `experiments/` | The experiments and the Docker image they run in; see [experiments/README.md](experiments/README.md) |
| `experiments/storm2-experiments.tar.gz` | The saved Docker images `storm2-experiments` and `storm2-tools`, for amd64 and arm64, loaded by `scripts/1_load.sh` |
| `examples/` | Example files: `vacuum/` the robot vacuum example of the paper (Sec. 7), and `mdp_benchmarks/` and `pomdp_benchmarks/` the models and properties of the MDP and POMDP benchmarks of the experiments; see [TOOLS.md](TOOLS.md) |
| `TOOLS.md` | A short description of Storm and Stormpy and how to try them out on the examples |
| `ARTIFACT.md` | How to build the Docker images and the artifact |
| `notebooks/` | Jupyter notebooks of the FM '26 Storm tutorial, updated for Stormpy 2.0, a copy of `tutorial_orchard/` of the [stormpyter repository](https://github.com/stormchecker/stormpyter/tree/306df8b/tutorial_orchard) (commit `306df8b` of `master`), whose `Dockerfile` is changed to build the image `storm2-tools` on the Stormpy 2.0 image |
| `storm/` | The source code of Storm 2.0.0, a submodule of the [Storm repository](https://github.com/stormchecker/storm) at its tag `2.0.0` |
| `stormpy/` | The source code of Stormpy 2.0.0, a submodule of the [Stormpy repository](https://github.com/stormchecker/stormpy) at its tag `2.0.0` |
| `LICENSE` | The license of the artifact (CC-BY 4.0) |

### Building the Docker images and the artifact
[ARTIFACT.md](ARTIFACT.md) describes how to build the Docker images with `scripts/5_build_docker.sh`, also with other versions of the tools such as a Storm of your own, and how to create the artifact with `scripts/6_create_artifact.sh`.
