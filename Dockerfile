# Base image
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    VSCODE_SERVE_MODE=remote \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    TZ=UTC0

# Set working directory
WORKDIR /

# Install System Packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    git nano nginx tzdata expect ca-certificates openssh-server build-essential \
    ncdu libglib2.0-0 libsm6 libgl1 libxrender1 libxext6 libcairo2-dev libgoogle-perftools4 libtcmalloc-minimal4 \
    python3.10-dev python3.10-venv gnome-keyring wget curl ca-certificates \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Set up Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    rm /usr/bin/python3 && \
    ln -s /usr/bin/python3.10 /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    pip install --upgrade pip

# Clone and install OneTrainer
RUN mkdir -p /training && \
    cd /training && \
    git clone https://github.com/Nerogar/OneTrainer.git && \
    cd OneTrainer && \
    bash install.sh

# Install VS Code Server
RUN curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz && \
    tar -xf vscode_cli.tar.gz
COPY src/* /usr/local/bin/

# Copy NGINX configuration and scripts
RUN wget -O init-deb.sh https://www.linode.com/docs/assets/660-init-deb.sh && \
    mv init-deb.sh /etc/init.d/nginx && \
    chmod +x /etc/init.d/nginx && \
    /usr/sbin/update-rc.d -f nginx defaults
COPY nginx.conf /etc/nginx/nginx.conf
COPY readme.html /usr/share/nginx/html/readme.html
COPY README.md /usr/share/nginx/html/README.md

# Copy and prepare start script
COPY post_start.sh /post_start.sh
COPY start.sh /
RUN chmod +x /start.sh

# Expose necessary port
EXPOSE 8000

# Start command
CMD [ "/start.sh" ]
