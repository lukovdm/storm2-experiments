#!/bin/sh
# Create the figures of the paper from the logs of the runs in DIR, in the layout of
# the runs of scripts/3_run.sh (DIR/mdp/logs/, DIR/imdp/logs/ and DIR/pomdp/logs/),
# e.g. results/paper/ for the runs of the paper, results/artifact/full/ or a folder
# written by scripts/3_run.sh. Post-processes the logs of every experiment in a
# container of storm2-experiments, like the experiment sets, and writes the figures
# to OUT, by default NAME-figures.pdf in the current directory for the folder NAME.
# Experiments without logs in DIR are left out of the figures.
#   scripts/4_figures.sh DIR [OUT]
set -eu
[ $# -ge 1 ] && [ -d "$1" ] || { echo "usage: scripts/4_figures.sh DIR [OUT]" >&2; exit 2; }
dir=$(cd "$1" && pwd)
# Not realpath, which on macOS fails for a file that does not exist yet
out=${2:-$(basename "$dir")-figures.pdf}
out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
if [ -e "$out" ]; then
  echo "$out exists already" >&2
  [ -t 0 ] || exit 1
  printf 'replace it? [y/N] ' >&2
  read -r answer
  case $answer in y|Y|yes) ;; *) exit 1 ;; esac
fi

echo "== $(date): creating the figures from the logs in $dir"
# Without the entrypoint, which only sets up the cgroups for run.py
docker run --rm -e HOST_ID="$(id -u):$(id -g)" -v "$dir:/logs:ro" -v "$(dirname "$out"):/out" \
  --entrypoint sh storm2-experiments -c '
  set -eu
  for experiment in mdp imdp pomdp; do
    [ -d "/logs/$experiment/logs" ] || { echo "no logs of $experiment"; continue; }
    options=
    [ $experiment = imdp ] && options="--agreement --absolute"
    echo "post-processing the logs of $experiment"
    # shellcheck disable=SC2086
    (cd $experiment && python3 ../docker/common/postprocess.py $options \
       /logs/$experiment/logs experiments/figures/results > /tmp/$experiment.log 2>&1) \
      || { cat /tmp/$experiment.log >&2; exit 1; }
  done
  echo "building the figures"
  docker/build_figures.sh -r experiments/figures/results > /tmp/latex.log 2>&1 \
    || { cat /tmp/latex.log >&2; exit 1; }
  cp docker/plots/latex/main.pdf "/out/$1" && chown "$HOST_ID" "/out/$1"' \
  sh "$(basename "$out")"
echo "== $(date): wrote the figures to $out"
