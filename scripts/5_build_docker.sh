#!/bin/sh
# Build the Docker images of the artifact, storm2-experiments from experiments/Dockerfile
# and storm2-tools for Storm, Stormpy and the notebooks from notebooks/Dockerfile (see
# TOOLS.md), for amd64 and arm64, load them into Docker and save both to a file, by
# default experiments/storm2-experiments.tar.gz, where scripts/1_load.sh and
# scripts/6_create_artifact.sh expect it. The build needs network access and Docker's
# containerd image store, see scripts/1_load.sh. PLATFORMS selects the architectures;
# other options are passed on to docker buildx build of storm2-experiments, e.g.
#   PLATFORMS=linux/amd64 scripts/5_build_docker.sh -o /tmp/image.tar.gz --build-arg generate_workers=4
# Building for another architecture than that of the machine needs QEMU, e.g.
#   docker run --privileged --rm tonistiigi/binfmt --install arm64
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
out=$root/experiments/storm2-experiments.tar.gz
if [ "${1:-}" = "-o" ]; then
  # Not realpath, which on macOS fails for a file that does not exist yet
  out=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
  shift 2
fi
cd "$root/experiments"

echo "== $(date): unpacking the Modest Toolset"
(cd docker/modest && sha256sum -c SHA256SUMS)
for arch in amd64:x64 arm64:arm64; do
  dir=docker/modest/${arch%%:*}
  rm -rf "$dir" && mkdir "$dir"
  unzip -q docker/modest/Modest-Toolset-*-linux-${arch##*:}.zip -d "$dir"
done

# The interval MDPs of imdp come with the artifact; the build only generates
# those still missing. The archive stores them below experiments/imdps/benchmarks/,
# the path of the experiment when the archive was made, so they are moved to
# imdp/benchmarks/ while unpacking (GNU tar).
if [ -f imdp/benchmarks.tar.xz ]; then
  echo "== $(date): unpacking the interval MDPs of imdp"
  XZ_OPT=-T0 tar -xJf imdp/benchmarks.tar.xz --skip-old-files \
    --transform 's|^experiments/imdps/|imdp/|'
fi

platforms=${PLATFORMS:-linux/amd64,linux/arm64}
echo "== $(date): building the image storm2-experiments"
# The MDP and POMDP benchmarks are in examples/, outside of the build context
docker buildx build --platform "$platforms" -t storm2-experiments --load \
  --build-context mdp_benchmarks=../examples/mdp_benchmarks \
  --build-context pomdp_benchmarks=../examples/pomdp_benchmarks "$@" .

echo "== $(date): building the image storm2-tools"
docker buildx build --platform "$platforms" -t storm2-tools --load ../notebooks

echo "== $(date): saving the images to $out"
docker save storm2-experiments storm2-tools | gzip > "$out"
ls -l "$out"
