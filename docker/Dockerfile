# mnem0nic memory service: the published Linux release file in a slim image.
# Build for linux/arm64 or linux/amd64; Docker's TARGETARCH picks the file (a builder that does not
# set it falls back to the image's own architecture).
# The build checks the download against the pinned SHA-256 and fails on a mismatch.

# Debian 12 slim, pinned by the digest of its multi-platform index.
ARG BASE=debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc

# Stage 1: download and verify. curl and the CA certificates stay in this stage.
FROM ${BASE} AS fetch
ARG TARGETARCH
ARG VERSION=0.9.0
ARG SHA256_ARM64=a74478d3d678b445777586014cd6529b27f0ff21dd54df5de9f1f3c5c8e02ac5
ARG SHA256_AMD64=098fd9634264a4bbf8ac51399ca53de75e007ef56bb64a8c57379f379cb50da9
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
RUN set -eu; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$arch" in \
      arm64) triple=aarch64-unknown-linux-gnu; want="$SHA256_ARM64" ;; \
      amd64) triple=x86_64-unknown-linux-gnu; want="$SHA256_AMD64" ;; \
      *) echo "unsupported architecture '$arch': build for linux/arm64 or linux/amd64" >&2; exit 1 ;; \
    esac; \
    file="mnem0nic-$triple.tar.gz"; \
    base="https://github.com/datashard-ai/mnem0nic/releases/download/v$VERSION"; \
    mkdir /dl /out; cd /dl; \
    curl --proto '=https' --tlsv1.2 -fsSL --retry 3 -o "$file" "$base/$file"; \
    if ! echo "$want  $file" | sha256sum -c -; then \
      got=$(sha256sum "$file" | cut -d' ' -f1); \
      published=$(curl --proto '=https' --tlsv1.2 -fsSL "$base/$file.sha256" 2>/dev/null | cut -d' ' -f1 || true); \
      echo "checksum mismatch for $file (version $VERSION)" >&2; \
      echo "  pinned:     $want" >&2; \
      echo "  downloaded: $got" >&2; \
      echo "  published:  ${published:-not readable}" >&2; \
      if [ "$got" = "$published" ]; then \
        echo "The download matches the published .sha256, so the pin is wrong (or the release file was replaced): check before changing it." >&2; \
      elif [ "$want" = "$published" ]; then \
        echo "The pin matches the published .sha256, so the download is wrong: a damaged download or a replaced release file." >&2; \
      else \
        echo "Neither the pin nor the download matches the published .sha256." >&2; \
      fi; \
      exit 1; \
    fi; \
    tar -xzf "$file" -C /out mnem0nic LICENSE.md THIRD-PARTY-NOTICES.md

# Stage 2: the image that runs. procps is for the ps and kill the daemon's checks call.
# No CA certificates: the program carries its own TLS roots.
FROM ${BASE}
RUN apt-get update \
 && apt-get install -y --no-install-recommends procps \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 10001 mnem0nic \
 && useradd --uid 10001 --gid 10001 --no-log-init --no-create-home \
      --home-dir /var/lib/mnem0nic --shell /usr/sbin/nologin mnem0nic \
 && install -d -m 0700 -o mnem0nic -g mnem0nic /var/lib/mnem0nic
COPY --from=fetch /out/mnem0nic /usr/local/bin/mnem0nic
COPY --from=fetch /out/LICENSE.md /out/THIRD-PARTY-NOTICES.md /usr/share/doc/mnem0nic/

# The store is the volume on /var/lib/mnem0nic. MNEM0NIC_HOME makes every command in the container
# use it; without it a command would start a second, empty store under $HOME.
ENV MNEM0NIC_HOME=/var/lib/mnem0nic \
    HOME=/var/lib/mnem0nic
WORKDIR /var/lib/mnem0nic
USER 10001:10001
ENTRYPOINT ["mnem0nic"]
CMD ["daemon", "serve"]
