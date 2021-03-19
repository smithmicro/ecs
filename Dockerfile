FROM debian:buster-slim

LABEL maintainer="David Sperling <dsperling@smithmicro.com>"

# overridable environment variables
ENV AWS_ACCESS_KEY_ID=
ENV AWS_SECRET_ACCESS_KEY=
ENV AWS_DEFAULT_REGION=
ENV ECS_PARAMS=

# Install AWS CLI 2.x, ECS CLI 1.x and print their versions
RUN apt-get -y update && apt-get -y install \
    curl \
    unzip \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm awscliv2.zip \
 && curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest \
 && chmod +x /usr/local/bin/ecs-cli \
 && aws --version \
 && ecs-cli --version

ENV ECS_CONFIG_DIR=/etc/ecs

COPY *.sh /usr/local/bin/
COPY *.json $ECS_CONFIG_DIR/

VOLUME /deploy

WORKDIR /deploy

ENTRYPOINT ["entrypoint.sh"]
CMD ["help"]
