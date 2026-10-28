#!/bin/sh
# Create the artifact zip, by default storm2-artifact.zip in the current
# directory: the committed files of the repository, including those of the
# submodules storm/ and stormpy/, plus the saved images experiments/storm2-experiments.tar.gz
# (see scripts/5_build_docker.sh), the Modest Toolset zips and the compressed
# interval MDPs.
#   scripts/6_create_artifact.sh [FILE]
set -eu
# Not realpath, which on macOS fails for a file that does not exist yet
out=${1:-storm2-artifact.zip}
out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
cd "$(dirname "$0")/.."
image=experiments/storm2-experiments.tar.gz
large="$image experiments/imdp/benchmarks.tar.xz experiments/docker/modest/*.zip"

echo "== $(date): checking the repository, the submodules, the image and the large files"
if [ -n "$(git status --porcelain)" ]; then
  echo "uncommitted changes, commit them first" >&2
  exit 1
fi
# A submodule that is not checked out, or not at its committed commit, would be
# missing from the zip or have other files in it
if git submodule status | grep -q '^[-+U]'; then
  git submodule status >&2
  echo "submodules not checked out at their commits, run git submodule update --init" >&2
  exit 1
fi
# shellcheck disable=SC2086
for file in $large; do
  [ -f "$file" ] || { echo "missing $file" >&2; exit 1; }
done
# The images contain the whole of experiments/ and notebooks/ and the models in
# examples/, so they must be saved after the last commit that changed them; results/
# is not in the images, so the sample runs made with them can be committed after it
if [ "$(stat -c %Y $image)" -lt "$(git log -1 --format=%ct -- experiments examples notebooks)" ]; then
  echo "$image is older than the last commit of experiments/, examples/ or notebooks/, rebuild it with scripts/5_build_docker.sh" >&2
  exit 1
fi

# Run from a temporary directory with a link storm2-artifact to the repository, so
# that everything is below storm2-artifact/ in the zip; the already compressed files
# are stored as they are, and links as links (-y), e.g. benchmarks/models of mdp to
# examples/mdp_benchmarks
top=storm2-artifact
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ln -s "$PWD" "$tmp/$top"
# The committed files without .gitmodules, which is of no use without git
files() { git ls-files --recurse-submodules | grep -vx '\.gitmodules'; }
# shellcheck disable=SC2086
echo "== $(date): writing $(files | wc -l) committed files and $(du -ch $large | tail -1 | cut -f1) of large files to $out"
rm -f "$out"
# shellcheck disable=SC2086
{ files; ls $large; } \
  | sed "s|^|$top/|" | (cd "$tmp" && zip -q -y -n .gz:.xz:.zip "$out" -@)
echo "== $(date): testing $out"
unzip -tq "$out"
echo "== $(date): done, $(du -h "$out" | cut -f1) in $out"
