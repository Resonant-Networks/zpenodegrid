FROM node:22-bookworm-slim

# Install system dependencies: curl, git, openssh-client, picocom (for serial console), jq, procps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    openssh-client \
    picocom \
    procps \
    iputils-ping \
    netcat-openbsd \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install @earendil-works/pi-coding-agent globally
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# The official node image includes a user 'node' with UID 1000.
# Rename 'node' to 'agent', add to dialout for serial ports, and initialize directories
RUN usermod -l agent node && \
    groupmod -n agent node && \
    usermod -d /home/agent -m agent && \
    usermod -aG dialout agent && \
    mkdir -p /workspace /home/agent/.pi/agent && \
    chown -R agent:agent /workspace /home/agent

USER agent
WORKDIR /workspace

VOLUME ["/workspace", "/home/agent/.pi"]

ENTRYPOINT ["pi"]
CMD ["--help"]
