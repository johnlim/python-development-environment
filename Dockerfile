# Pin to a specific Python version for reproducibility
FROM python:3.12-slim-bookworm

# Install git and curl (common dev requirements) and clean up apt cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the official uv binary directly from Astral's distroless image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Create a non-root user to limit blast radius inside the container
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# Configure uv environment variables:
# - UV_LINK_MODE=copy avoids hardlink warnings across mounted filesystems
# - UV_PROJECT_ENVIRONMENT places the .venv outside the mounted /workspace
#   so host/container OS binaries don't clash and stay isolated
ENV UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/home/$USERNAME/.venv \
    PATH="/home/$USERNAME/.venv/bin:$PATH"

# Set up workspace and cache directories owned by the non-root user
RUN mkdir -p /workspace /home/$USERNAME/.cache/uv \
    && chown -R $USERNAME:$USERNAME /workspace /home/$USERNAME

USER $USERNAME
WORKDIR /workspace

# Keep the container running so you can exec into it or attach an IDE
CMD ["sleep", "infinity"]

