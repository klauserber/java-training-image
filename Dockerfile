FROM ubuntu:22.04

ARG TARGETARCH=amd64
ARG TARGETOS=linux

ENV JAVA_HOME=/opt/java/openjdk

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" TZ="Europe/Berlin" apt-get install -y \
    ca-certificates \
    software-properties-common \
    curl \
    wget \
    unzip \
    iputils-ping \
    sudo \
    git \
    vim \
    jq \
    ssh \
    pwgen \
    gettext-base \
    bash-completion \
    zip \
    # openjdk-17-jdk \
    # openjdk-17-jre \
    python3 \
    python3-pip \
 && rm -rf /var/lib/apt/lists/*

# # https://coder.com/blog/self-hosted-remote-development-in-jetbrains-ides-now-available-to-coder-users
# # https://www.jetbrains.com/de-de/idea/download/other.html
# RUN set -e; \
#   mkdir -p /opt/idea; \
#   curl -L "https://download.jetbrains.com/idea/ideaIU-2023.2.3.tar.gz" | tar -C /opt/idea --strip-components=1 -xzvf -

# https://hub.docker.com/_/docker/tags
COPY --from=docker:24.0.6-cli /usr/local/bin/docker /usr/local/bin/docker-compose /usr/local/bin/
# https://hub.docker.com/r/docker/buildx-bin/tags
COPY --from=docker/buildx-bin:0.11.2 /buildx /usr/libexec/docker/cli-plugins/docker-buildx

RUN curl -s https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

# https://hub.docker.com/_/eclipse-temurin/tags
COPY --from=eclipse-temurin:21_35-jdk-ubi9-minimal /opt/java/openjdk /opt/java/openjdk

# https://github.com/kubernetes/kubernetes/releases
ARG KUBECTL_VERSION=1.27.4
RUN set -e; \
    cd /tmp; \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl"; \
    mv kubectl /usr/local/bin/; \
    chmod +x /usr/local/bin/kubectl

# https://github.com/helm/helm/releases
ARG HELM_VERSION=3.12.3
RUN set -e; \
  cd /tmp; \
  curl -Ss -o helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz; \
  tar xzf helm.tar.gz; \
  mv ${TARGETOS}-${TARGETARCH}/helm /usr/local/bin/; \
  chmod +x /usr/local/bin/helm; \
  rm -rf ${TARGETOS}-${TARGETARCH} helm.tar.gz

# # Install buildx
# COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# https://github.com/coder/code-server/releases
ARG CODE_SERVER_VERSION=4.16.1
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${CODE_SERVER_VERSION}

COPY helpers /helpers

RUN useradd coder \
      --create-home \
      --shell=/bin/bash \
      --uid=1000 \
      --user-group && \
      echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

RUN mkdir /run/sshd


COPY bashrc.sh /tmp/
RUN set -e; \
  cat /tmp/bashrc.sh >> /etc/bash.bashrc; \
  rm /tmp/bashrc.sh

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=en_US:en

USER coder

RUN touch ${HOME}/.bashrc

ENV PATH=${HOME}/.local/bin:${HOME}/bin:${PATH}

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=en_US:en

ENTRYPOINT ["code-server"]
CMD [ "--auth=none", "--bind-addr=0.0.0.0:8080" ]
