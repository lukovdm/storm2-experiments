#!/bin/sh
# Load the saved images of the artifact, by default experiments/storm2-experiments.tar.gz
# (see scripts/5_build_docker.sh), into Docker: storm2-experiments for the experiments
# and storm2-tools for Storm, Stormpy and the notebooks (see TOOLS.md). The images are
# for amd64 and arm64; Docker's containerd image store ("Use containerd for pulling
# and storing images" in the Docker settings) keeps both, the classic image store
# only the one of the machine.
#   scripts/1_load.sh [FILE]
set -eu
image=${1:-$(dirname "$0")/../experiments/storm2-experiments.tar.gz}

command -v docker >/dev/null || { echo "docker not found, install Docker first" >&2; exit 1; }
[ -f "$image" ] || { echo "missing $image" >&2; exit 1; }
# Not realpath, which on macOS fails for a file that does not exist
image=$(cd "$(dirname "$image")" && pwd)/$(basename "$image")

echo "== $(date): loading $image ($(du -h "$image" | cut -f1)), which takes a few minutes"
if ! docker load -i "$image"; then
  # The classic image store of Docker 29 loads the image of the machine from the
  # multi-platform images; the containerd image store may help other versions
  case $(docker info --format '{{.DriverStatus}}') in
    *io.containerd.snapshotter*) ;;
    *) echo "loading failed and Docker does not use the containerd image store, which" \
            "may be needed for the multi-platform images: enable \"Use" \
            "containerd for pulling and storing images\" in the Docker settings, or" \
            "\"features\": {\"containerd-snapshotter\": true} in /etc/docker/daemon.json" \
            "for Docker Engine, restart Docker and try again" >&2 ;;
  esac
  exit 1
fi
for name in storm2-experiments storm2-tools; do
  docker image inspect $name --format "loaded $name for {{.Os}}/{{.Architecture}}"
done
