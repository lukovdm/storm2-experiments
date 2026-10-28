# Storm and stormpy

This artifact contains the source code of [Storm](https://www.stormchecker.org/) 2.0 in `storm/` and of [stormpy](https://stormchecker.github.io/stormpy/) 2.0 in `stormpy/`. 
This file describes both tools briefly and shows how to try them out on the robot vacuum example of the paper (Sec. 7, Fig. 4 and 5) in `examples/vacuum/` and on the MDP and POMDP benchmarks of the experiments in `examples/mdp_benchmarks/` and `examples/pomdp_benchmarks/`.

## Storm

Storm is a versatile, modular, and efficient open-source probabilistic model checker. 
It has a C++ core, which builds a model from a high-level description such as a Prism program or a JANI model, preprocesses it, and solves the equations that characterise a query.
Storm provides a set of command-line interfaces, and a Python API, stormpy. 
It supports DTMCs, MDPs, POMDPs, CTMCs and Markov automata, as well as interval and parametric models. 
Supported queries include reachability probabilities, expected rewards, LTL, multi-objective queries, conditional probabilities and expected visiting times, and Storm can extract policies (schedulers) for them. 
Results come with the bounds that the chosen algorithm proves: Storm offers fast floating-point methods, sound methods with guaranteed precision, and exact methods using exact rational number arithmetic.

The Storm website [www.stormchecker.org](https://www.stormchecker.org/) provides documentation, a [getting started guide](https://www.stormchecker.org/getting-started.html) and [tutorials](https://www.stormchecker.org/tutorials.html). 
Storm can also be tried without any installation in the online playground at [try.stormchecker.org](https://try.stormchecker.org/).
More example models can be found in the [Quantitative Verification Benchmark Set](http://qcomp.org/benchmarks).

### Playing with Storm

Use the Docker image `storm2-tools` of the artifact, which `scripts/1_load.sh` loads together with the image of the experiments (see the [README](README.md#step-1-load-the-docker-images)).
It is built from `notebooks/Dockerfile` on the official image of stormpy 2.0, `movesrwth/stormpy:2.0.0`, and contains the command-line tools of Storm 2.0, stormpy 2.0 and the Jupyter environment of the notebooks.

In the following, we outline how to run Storm in the container on the files in `examples/`.

To analyse the vacuum robot example, first navigate to the root folder `$ARTIFACT_DIR` of the artifact using

```bash
cd $ARTIFACT_DIR
```

and then execute

```bash
docker run --rm -v "$PWD/examples:/examples" -w /examples/vacuum storm2-tools \
    storm --prism vacuum.prism --prop 'Tmin=? [F "docked"]' --exact
```

The command starts a container for the image `storm2-tools` such that the container is removed after the command terminates (`--rm`).
It mounts `$ARTIFACT_DIR/examples` as `/examples` in the container (`-v "$PWD/examples:/examples"`), making the examples files available.
`-w /examples/vacuum` sets the container's working directory to `/examples/vacuum`.
In the container, we execute the command `storm --prism vacuum.prism --prop 'Tmin=? [F "docked"]' --exact`, calling the main Storm CLI tool `storm` with the following options:
- `--prism vacuum.prism` specifies that the file `vacuum.prism` is taken as the model input in PRISM format.
- `--prop 'Tmin=? [F "docked"]'` specifies the property to be checked. Here, `Tmin=? [F "docked"]` means that we want to compute the minimal expected time (`Tmin=?`) until reaching a state labelled with a label `docked` in the model (`[F "docked"]`).
- `--exact` tells Storm to work in exact mode.

This computes the minimal expected time for the robot vacuum to reach its charging dock exactly, using rational numbers.

The output should end with

```
Result (for initial states): 60134629039/1529841069 (approx. 39.30776226). Exact solution.
```
indicating that the computed minimal expected time is `60134629039/1529841069` or approximately `39.30776226`.

You can replace the options after `storm` to try other queries and settings, for example:

| Options | Result |
| --- | --- |
| `--prism vacuum.prism --prop 'Tmin=? [F "docked"]'` | 39.30873742 with the default floating-point value iteration, which only proves the bounds [0, 246.26] |
| `--prism vacuum.prism --prop 'Tmin=? [F "docked"]' --sound` | 39.30777562 with sound value iteration, which proves the bounds [39.30773631, 39.30781493] |
| `--prism vacuum.prism --prop 'Pmax=? [F<=10 "docked"]' --sound` | 0.7519414556, the maximal probability to dock within 10 steps, which Storm computes exactly |
| `--prism vacuum.prism --prop 'R{"steps"}min=? [F "docked"]' --sound` | 38.30777562, the minimal expected number of moves to dock (the first step only starts the robot), with the bounds [38.30773731, 38.30781393] |
| `--prism vacuum.prism --prop 'Tmin=? [F "docked"]' --sound --buildstateval --buildchoicelab --exportscheduler sched.json` | also writes the optimal policy to `examples/vacuum/sched.json`: for every state, given by its variables, the action to choose, e.g. `east` |

The comments at the top of `vacuum.prism` describe how to modify the file to obtain one of three variants, each representing a different MDP variant:

- a POMDP in which the robot only observes bumps,
- a parametric MDP with an undefined slip probability, and
- an interval MDP.

The MDP benchmarks of the main paper experiments can be checked in the same way, e.g. the coin-flip property `c2` of the consensus protocol with 4 processes, before and after bisimulation minimisation:

```bash
docker run --rm -v "$PWD/examples:/examples" -w /examples/mdp_benchmarks/consensus storm2-tools \
    storm --prism consensus.4.prism --prop consensus.props c2 --constants K=4 --bisimulation --sound
```

which reduces the model from 43136 to 2189 states and gives `0.4062752785` with the bounds `[0.4062748722, 0.4062756848]`; the exact value is 852021/2097152 ≈ 0.4062752724. 

`storm --help` lists the most important options, and `storm --help all` list *all* options, including advanced ones.

POMDPs are analysed using CLI tool `storm-pomdp`, whose belief exploration computes sound bounds on the optimal value.
For the refuel benchmark of the POMDP experiments, unfolding the beliefs up to a size limit of 100000 gives a lower bound, and discretising the beliefs with resolution 4 an upper bound on the maximal probability to reach the goal:

```bash
docker run --rm -v "$PWD/examples:/examples" -w /examples/pomdp_benchmarks/refuel storm2-tools \
    storm-pomdp --prism refuel.prism --prop refuel.props prbmax -const N=6 --belief-exploration unfold --size-threshold 100000 --sound
docker run --rm -v "$PWD/examples:/examples" -w /examples/pomdp_benchmarks/refuel storm2-tools \
    storm-pomdp --prism refuel.prism --prop refuel.props prbmax -const N=6 --belief-exploration discretize --resolution 4 --triangulationmode static --sound
```

which print `Result: ≥ 0.67219` and `Result: ≤ 0.7129687089`; with option `--sound` (as used in the experiments), Storm uses a sound method for any MDP computations.
Figure 9 of the paper shows how the bounds obtained using Storm's POMDP analysis develop with the size limit.

## stormpy

stormpy provides the Python bindings for Storm, created using [pybind11](https://pybind11.readthedocs.io/). 
It brings Storm into the Python ecosystem for numerical computations, machine learning, and visualisation, so that algorithms on top of Storm, such as loops around model checking calls, can be prototyped quickly while the computations run in the C++ core.
stormpy 2.0 has two layers:
- The Pythonic public API provides access for common tasks and hides more technical considerations. For example, function `build_model` automatically picks the right builder for a model.
- The developer layer provides one-to-one bindings to the functions and classes of Storm, allowing for higher customisability and building on core functionality.
 
Specialisations such as the number representation are selected by indexing, e.g. `build_model[Rational](program)` builds a model with rational numbers.
The [documentation of stormpy](https://stormchecker.github.io/stormpy/) provides a getting-started guide and the API reference.

### Playing with stormpy

`examples/vacuum/vacuum.py` contains the code depicted in Fig. 4 of the paper. 
- It builds the robot vacuum MDP with rational numbers,
- computes the minimal expected time to dock, together with an optimal policy,
- applies the policy to obtain the induced DTMC,
- computes how often the robot visits the rug, and
- turns every probability into an interval of width 1/100 and computes the minimal expected time under robust semantics.

To run the stormpy example it in the same image `storm2-tools`, first navigate to the root folder `$ARTIFACT_DIR` of the artifact using

```bash
cd $ARTIFACT_DIR
```

and then run

```bash
docker run --rm -v "$PWD/examples:/examples" -w /examples/vacuum storm2-tools python3 vacuum.py
```

This prints, apart from warnings that Storm switches to robust value iteration for the interval MDP:

```
Minimal expected time to dock: 60134629039/1529841069 [...] approx: 39.307762 [39.307762, 39.307762]
Expected number of visits to the rug: 12.084022 [-, -]
Interval result: ... approx: 50.768185 [...]
```

To explore further, start an interactive Python shell with 
```bash
docker run -it --rm -v "$PWD/examples:/examples" -w /examples/vacuum storm2-tools python3`
```
and enter the lines of `vacuum.py` one by one, e.g. to look at `mdp`, `result.get_scheduler()` or `visits`.

### Notebooks

`notebooks/` contains the Jupyter notebooks of the Storm tutorial, originally presented at FM '26, updated to Storm 2.0 and stormpy 2.0.
It uses the Orchard game as a running example, and introduces modelling, model checking, policies, uncertainty and further extensions using stormpy 2.0 and [stormvogel](https://github.com/stormchecker/stormvogel).
The image `storm2-tools` contains the notebooks in `/opt/notebooks` together with their Jupyter environment. Start it with

```bash
docker run -it --rm -p 8888:8888 storm2-tools
```

and open the `http://127.0.0.1:8888/lab?token=...` link that it prints in a web browser; see [notebooks/README.md](notebooks/README.md) for the notebooks. 
Changes to the notebooks are lost when the container stops; `File > Download` saves a notebook to the host.
