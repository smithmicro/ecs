FROM alpine:3.8

LABEL maintainer="David Sperling <dsperling@smithmicro.com>"

# overridable environment variables
ENV AWS_ACCESS_KEY_ID=
ENV AWS_SECRET_ACCESS_KEY=
ENV AWS_DEFAULT_REGION=

# Install the AWS and ECS CLI
RUN apk add --update --no-cache \
    bash \
    ca-certificates \
    python \
    py-pip \
 && pip install \
    awscli \
 && wget -O /usr/local/bin/ecs-cli -q https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
 && chmod +x /usr/local/bin/ecs-cli

COPY *.sh /usr/local/bin/

VOLUME /deploy

WORKDIR /deploy

ENTRYPOINT ["entrypoint.sh"]
CMD ["help"]
