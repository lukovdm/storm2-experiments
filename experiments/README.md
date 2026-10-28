# The experiments of "The Probabilistic Model Checker Storm: Lightning Strikes Twice"

This folder holds the experiments of the artifact and the Docker image they run in; the original results presented in the paper are in [`../results/paper/`](../results/paper/README.md).
This README describes how to set up the host for stable timings, how the experiments can be configured and run individually, and how to modify the experiments for your own benchmarks.
How to load the image and run the smoke test, and the minimal, the representative and the full experiments are described in the [README of the artifact](../README.md), and [ARTIFACT.md](../ARTIFACT.md) describes how to build the image.

## Additional setup
### Stable timings (Linux only)
To ensure that timings for the experiemnts are as stable as possible, execute the following commands:

```bash
sudo cpupower frequency-set -g performance # set the governor
sudo cpupower set --turbo-boost 0          # turn off boost
cpupower frequency-info --policy           # check the governor
cpupower frequency-info | grep -A2 boost   # check boost
```
This requires root access and the `cpupower` tools, which comes with the package `linux-cpupower` on Debian, `linux-tools-common` and `linux-tools-$(uname -r)` on Ubuntu, `kernel-tools` on Fedora, and `cpupower` on Arch.

The comamnds set the frequency governor of the host to `performance` and disable boost (turbo) before running.
The settings are lost on a reboot.
With boost, the frequency of a core depends on the temperature and on how many other cores are busy, so the runtimes are influenced by simultaneous loads.
Thus, to ensure the most stable timings, do not run other workloads simultaneously to the experiments.

Older versions of `cpupower` lack `--turbo-boost`; 
if you have such a version, disable boost with
`echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost`, or on Intel with
`echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo`.

## Running individual experiments
We outline how you can run individual experiments instead of a complete experiment set.

- Start an interactive container with `docker run -it --privileged --cap-drop=all --name storm2 storm2-experiments`.
- Go to the directory of the experiment, e.g. `cd mdp`, and run the four steps below.
```bash
python3 ../docker/common/generate_invocations.py --out inv.json --logdir experiments/logs
python3 ../docker/common/run.py inv.json
python3 ../docker/common/postprocess.py experiments/logs experiments/results
../docker/build_figures.sh
```
- Open another terminal and copy the results out of the container , e.g. `docker cp storm2:/opt/storm2-experiments/mdp/experiments mdp` and `docker cp storm2:/opt/storm2-experiments/docker/plots/latex/main.pdf .`.

The Docker image contains this folder in `/opt/storm2-experiments`.
For `imdp`, post-process with `postprocess.py --agreement --absolute`, as there are no exact results for interval MDPs and the configurations have to agree on them instead. 
`build_figures.sh` builds the figures of all experiments with results in `docker/plots/latex/main.pdf`, and writes the csv files they are made from to `docker/plots/latex/data/`.

The scripts in `docker/common/` describe all their options with `--help`. The most important ones:
- `generate_invocations.py`: `--configs` and `--benchmarks` select configurations and benchmarks by their names in `scripts/configurations.json` and `benchmarks/index.json` of the experiment, `--index index-smoke.json` another set of benchmarks, `--timelimit` the time limit in seconds (default: 900), and `--repetitions` repeats every run.
- `run.py`: `--memlimit` sets the memory limit in GiB (default: 32), `--parallel` runs as many at the same time as fit into the cores and the memory instead of one at a time, `--jobs N` runs N at the same time, `--cores-per-run` the physical cores of every run (default: 4), and `--ddmem` the memory of the decision diagram libraries in GiB (default: 8).
The tools get these through the placeholders `%memlimit`, `%cores`, `%ddmem` and `%ddmem-mb` of `configurations.json`.
PRISM's `-javamaxmem` is the memory limit and its `-cuddmaxmem` the decision diagram memory, and Storm's symbolic engines get the cores as `--sylvan:threads` and the decision diagram memory as `--sylvan:maxmem`.
With `--bare`, the runs are executed one after the other without BenchExec, so without pinning and memory limit and without `--privileged`.
Results measured with different `--cores-per-run` are not comparable.
- `check_results.py experiments/results` lists the runs with an incorrect result or none at all, and for `pomdp` bounds that contradict each other, and fails if there are any.
- Runs with the same outcome as in the runs of the paper that `benchmarks/expected-outcomes.json` of the experiment lists, e.g. of benchmarks a tool does not support, are only counted as expected; `--expected` lists them.

`run.py` writes one log per run to `experiments/logs/`, and `postprocess.py` writes `results.json` with the status, runtime and result of every run, and `table/index.html`, a table of all runs linking to their logs, to `experiments/results/`; `pomdp` has its own post-processing, see [pomdp/README.md](pomdp/README.md).

Every run gets 4 physical cores because some configurations use several threads: Storm's symbolic engines (`storm-hybrid-sound`, `storm-sound-ddbisim`) run Sylvan with 4 threads, and Java, which runs PRISM, chooses a single-threaded garbage collector when it sees only one core.

## Running your own benchmarks
The scripts can run all tool configurations of the MDP experiment `mdp` (Storm 2.0 in its configurations, Storm 1.6.2, mcsta and PRISM) on your own MDPs, and check and compare their results and runtimes like for the benchmarks of the paper.
Storm and mcsta read the model as a JANI file, PRISM as a PRISM program with a property file; a benchmark with only one of them is only run by the configurations that read it.

1. Put your models and properties into a folder, e.g. `mine/`. Convert a Prism program with its property file into a JANI file with the properties in it with `storm-conv` in the image, without fixing the constants, which the configurations set:
   ```bash
   docker run --rm --entrypoint storm-conv -v "$PWD/mine:/w" -w /w storm2-experiments \
       --prism consensus.4.prism --prop consensus.props --tojani consensus.4.jani
   ```
2. Describe the benchmarks in `mine/index.json`, in the format of `mdp/benchmarks/index.json`. The paths are relative to `mdp/benchmarks/`, where the next step makes the folder available as `mine/`:
   ```json
   {
     "my-consensus": {
       "type": "mine",
       "jani": "mine/consensus.4.jani",
       "prism": "mine/consensus.4.prism",
       "prism-property": "mine/consensus.props",
       "property": "c2",
       "constants": "K=4"
     }
   }
   ```
   `property` is the name of the property in the JANI file and the property file, `constants` the values of the open constants (optional), and `type` a name for the class of the benchmark, which the figures use as its mark. An optional `reference-result` is the known result, e.g. `"852021/2097152"`; without it, the results are compared with the one that most configurations agree on.
3. Run all configurations on them in the container, with the folder in `mdp/benchmarks/mine/`, from the directory that contains `mine/`:
   ```bash
   docker run --rm --privileged --cap-drop=all -e HOST_UID=$(id -u) \
       -v "$PWD/mine:/opt/storm2-experiments/mdp/benchmarks/mine" storm2-experiments sh -c '
     cd mdp &&
     python3 ../docker/common/generate_invocations.py --index mine/index.json --out benchmarks/mine/inv.json \
         --logdir benchmarks/mine/logs --timelimit 60 &&
     python3 ../docker/common/run.py benchmarks/mine/inv.json --memlimit 16 &&
     python3 ../docker/common/postprocess.py --index mine/index.json --agreement benchmarks/mine/logs benchmarks/mine/results;
     python3 ../docker/common/check_results.py benchmarks/mine/results;
     chown -R $HOST_UID:$HOST_UID benchmarks/mine'
   ```
   The options of the scripts select configurations (`--configs`), the time limit (`--timelimit`), the memory limit (`--memlimit`) and how many run at the same time (`--parallel`), see [Running individual experiments](#running-individual-experiments). 
   The last command gives the files that the container writes back to you.
4. The resulting logs and the result data are located in `mine/logs/` and `mine/results/`, respectively. Result data is given in `results.json`, containing the status, runtime and result of every run; `table/index.html` containing a browsable table of all runs linking to their logs; CSV files used to generate the figures.
`check_results.py` lists the runs with a result that differs from the reference result.

For the consensus example above, all 10 configurations give 0.40627 (exactly 852021/2097152). This works for the MDP experiment only: the post-processing of the interval MDP and POMDP experiments only know the benchmarks of their own `index.json`.

## Contents

| Path | Description |
| --- | --- |
| `storm2-experiments.tar.gz` | The saved Docker images `storm2-experiments` and `storm2-tools`, for amd64 and arm64, loaded by `scripts/1_load.sh` of the artifact and saved by `scripts/5_build_docker.sh` |
| `docker/` | `run_in_container.sh` runs an experiment set in a container and copies its results out; inside the container, `run_smoke.sh`, `run_representative.sh`, `run_minimal.sh` and `run_all.sh` run the experiment sets (all four through `common/run_set.sh`) and `build_figures.sh` builds the figures; `init.sh` is the entrypoint of the image, `storm-old` runs Storm 1.6.2, and `modest/` holds the license and the zips of the Modest Toolset |
| `Dockerfile` | The Docker image with all tools: Storm 2.0.0, Storm 1.6.2, PRISM 4.10.1, the Modest Toolset v3.1.315, Julia 1.13.0 with IntervalMDP.jl, LaTeX, BenchExec, and this folder in `/opt/storm2-experiments` |
| `mdp/` | Comparison of Storm, mcsta and PRISM, with and without bisimulation minimisation (Figures 6 and 7) |
| `imdp/` | Comparison of Storm, PRISM and IntervalMDP.jl on interval MDPs derived from the MDP benchmarks of `mdp` (Figure 8); see [imdp/README.md](imdp/README.md) |
| `pomdp/` | Belief exploration of storm-pomdp with cut-offs on POMDPs (Figure 9); see [pomdp/README.md](pomdp/README.md) |
| `imdp/benchmarks.tar.xz` | The generated interval MDPs of `imdp`, which `scripts/5_build_docker.sh` unpacks |
| `mdp/benchmarks/models/`, `pomdp/benchmarks/models/` | Links to the model and property files of the MDP and POMDP benchmarks in `examples/mdp_benchmarks/` and `examples/pomdp_benchmarks/` of the artifact; `scripts/5_build_docker.sh` passes these to the build as the named build contexts `mdp_benchmarks` and `pomdp_benchmarks` |
| `docker/common/` | The scripts to generate, run, post-process and check the runs, shared by all experiments |
| `docker/plots/latex/` | The sources of the figures of the paper, built by `docker/build_figures.sh` |

Every experiment directory has the same layout: `scripts/configurations.json` lists the configurations, `bin/` holds the tools, `benchmarks/index.json` describes the benchmarks, and `experiments/` receives the logs and results. The model paths in an index are relative to its directory: those of `mdp` and `pomdp` point to `benchmarks/models/`, a link to the MDP or POMDP benchmarks in `examples/` of the artifact, and those of `imdp` to its generated models. Next to `index.json`, `index-representative.json` and `index-smoke.json` hold the benchmarks of the representative experiments (also used by `scripts/3_run.sh minimal`) and the smoke test.

## Building the Docker images
See [Building the docker](../ARTIFACT.md#building-the-docker) in `ARTIFACT.md` of the artifact.
