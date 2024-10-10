# Use the official gradle image to create a build artifact.
FROM gradle:8-jdk17 AS builder

# Set the working directory.
WORKDIR /app

# Copy only the dependencies necessary to run gradle commands.
COPY build.gradle /app/
COPY settings.gradle /app/
RUN gradle --no-daemon dependencies
COPY src src

# Build a release artifact.
RUN gradle --no-daemon --parallel build -x test
# Use OpenJDK for runtime.
FROM openjdk:17.0.1-jdk-slim AS base

# Update packages and install curl, jq and awscli
RUN apt-get update && apt-get -y install curl jq awscli

#COPY /docker-entrypoint.d/ /docker-entrypoint.d/
#COPY /docker-entrypoint.sh .

# Set the working directory.
ADD https://timf-ecs-log.s3.ap-northeast-2.amazonaws.com/heapDump/script/heapDumpUploadToS3.sh .
RUN chmod +x heapDumpUploadToS3.sh
#COPY /heapDumpUploadToS3.sh .
WORKDIR /usr/app

# Copy the jar to the production image from the builder stage.
COPY --from=builder /app/build/libs/oomtest-0.0.1-SNAPSHOT.jar /usr/app/oom.jar



ARG ARG_PROFILE=dev
ENV SPRING_PROFILES_ACTIVE=${ARG_PROFILE}
## for timezone
ENV TZ=Asia/Seoul

EXPOSE 18080
### running container..
# for dev/stage
FROM base AS dev
RUN apt-get update && apt-get -y install wget && wget -O /usr/app/dd-java-agent.jar 'https://timf-data.s3.ap-northeast-2.amazonaws.com/libs/dd-java-agent.jar'
ENV DD_ENV=test
ENV DD_SERVICE=oom-test
ENV DD_AGENT_HOST=localhost
ENV DD_TRACE_AGENT_PORT=8126
ENV DD_PROFILING_ENABLED=true
ARG DD_GIT_REPOSITORY_URL
ARG DD_GIT_COMMIT_SHA
ENV DD_GIT_REPOSITORY_URL=${DD_GIT_REPOSITORY_URL}
ENV DD_GIT_COMMIT_SHA=${DD_GIT_COMMIT_SHA}
ENTRYPOINT ["java", "-javaagent:/usr/app/dd-java-agent.jar", "-jar", "/usr/app/oom.jar"]

# for prod
#FROM base as prod
#RUN apt-get update && apt-get -y install wget && wget -O /usr/app/dd-java-agent.jar 'https://timf-data.s3.ap-northeast-2.amazonaws.com/libs/dd-java-agent.jar'
#ENV DD_ENV=prod
#ENV DD_SERVICE=ts-api
#ENV DD_AGENT_HOST=172.17.0.1
#ENV DD_TRACE_AGENT_PORT=8126
#ENV DD_LOGS_INJECTION=true
#LABEL com.datadoghq.tags.env="prod"
#LABEL com.datadoghq.tags.service="ts-api"
#ENTRYPOINT ["/docker-entrypoint.sh", "java", "-javaagent:/usr/app/dd-java-agent.jar", "-Ddd.logs.injection=true", "-Ddd.service=yh-api", "-Ddd.env=prod", "-jar", "/usr/app/timf-api-exec.jar"]

