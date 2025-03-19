# Use the latest Ubuntu image
FROM ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv openssh-server sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y vim
RUN apt-get update && apt-get install -y curl

# Create a working directory
WORKDIR /app

#   env_variable_dependencies=("LIVEKIT_SIP_URL" "LIVEKIT_URL"  "GROQ_API_KEY" "DEEPGRAM_API_KEY" "LIVEKIT_API_KEY" "LIVEKIT_API_SECRET" "CARTESIA_API_KEY" "TWILIO_ACCOUNT_SID" "TWILIO_API_KEY" "TWILIO_API_SECRET" "TWILIO_PHONE_ID")

# Define build arguments for environment variables
ARG TWILIO_ACCOUNT_SID
ARG TWILIO_API_KEY
ARG TWILIO_API_SECRET
ARG TWILIO_PHONE_ID
ARG TWILIO_PHONE_NUMBER

ARG LIVEKIT_URL
ARG LIVEKIT_API_KEY
ARG LIVEKIT_API_SECRET
ARG LIVEKIT_SIP_URL

ARG GROQ_API_KEY
ARG DEEPGRAM_API_KEY
ARG CARTESIA_API_KEY

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION

ARG SSH_PASSWORD
ARG venv_name=venv

# Set environment variables inside the container
ENV TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID
ENV TWILIO_API_KEY=$TWILIO_API_KEY
ENV TWILIO_API_SECRET=$TWILIO_API_SECRET
ENV TWILIO_PHONE_ID=$TWILIO_PHONE_ID
ENV TWILIO_PHONE_NUMBER=$TWILIO_PHONE_NUMBER

ENV LIVEKIT_URL=$LIVEKIT_URL
ENV LIVEKIT_API_KEY=$LIVEKIT_API_KEY
ENV LIVEKIT_API_SECRET=$LIVEKIT_API_SECRET
ENV LIVEKIT_SIP_URL=$LIVEKIT_SIP_URL

ENV GROQ_API_KEY=$GROQ_API_KEY
ENV DEEPGRAM_API_KEY=$DEEPGRAM_API_KEY
ENV CARTESIA_API_KEY=$CARTESIA_API_KEY

ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_REGION=$AWS_REGION


ENV venv_name=$venv_name

# Copy all project files and directories to the container
COPY --chown=root:root . /app/

# Specifically ensure important directories are copied
COPY --chown=root:root infra/ /app/infra/
COPY --chown=root:root src/ /app/src/
COPY --chown=root:root test/ /app/test/
COPY --chown=root:root docker_entry.sh /app/
COPY --chown=root:root requirements.txt /app/
COPY --chown=root:root env_export.sh /app/

# Expose ports 2800-3300
EXPOSE 2800-3300
EXPOSE 5222
EXPOSE 80
EXPOSE 443
EXPOSE 22

# Grant execute permissions to the setup script
RUN chmod +x /app/infra/setup_dependency.sh

# Grant execute permissions to the env_export.sh
RUN chmod +x /app/env_export.sh

# Run the setup script to install dependencies
RUN /app/infra/setup_dependency.sh

# Run the env_export.sh to export the environment variables
RUN /app/env_export.sh

# Set up a secure SSH configuration with a dynamic password
RUN useradd -m -s /bin/bash debugger \
    && echo "debugger:${SSH_PASSWORD}" | chpasswd \
    && echo "debugger ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && mkdir -p /var/run/sshd

RUN chmod +x /app/docker_entry.sh

# Start SSH service and keep container running
ENTRYPOINT ["/bin/bash", "-c", "/app/docker_entry.sh"]
