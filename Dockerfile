FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ca-certificates \
    git \
    docker.io \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy our entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
