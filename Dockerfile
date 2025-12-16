FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ca-certificates \
    git \
    libicu-dev

# Install prerequisites
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
 && mkdir -p /etc/apt/keyrings

# Add Docker’s official GPG key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository (single line using echo)
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

# Install Docker CE + CLI + Buildx + Compose plugin
RUN apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


RUN rm -rf /var/lib/apt/lists/*

# Copy our entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
