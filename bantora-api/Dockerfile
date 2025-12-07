FROM eclipse-temurin:25-jdk-alpine AS builder

ARG GRADLE_VERSION=8.11.1
ARG JAVA_VERSION=25

WORKDIR /build

# Copy Gradle wrapper and configuration files
RUN mkdir -p /opt/gradle-wrapper
COPY gradle/wrapper/gradle-9.2.1-bin.zip /opt/gradle-wrapper/
COPY gradle gradle
COPY gradlew .
COPY gradlew.bat .
COPY gradle.properties .
COPY settings.gradle .
COPY build.gradle .

# Make gradlew executable
RUN chmod +x gradlew

# Copy all module build files
COPY bantora-common/bantora-common-shared/build.gradle bantora-common/bantora-common-shared/
COPY bantora-common/bantora-common-persistence/build.gradle bantora-common/bantora-common-persistence/
COPY bantora-database/build.gradle bantora-database/
COPY bantora-api/build.gradle bantora-api/
COPY bantora-web/build.gradle bantora-web/
COPY bantora-web/src bantora-web/src

# Debug: List directories
RUN ls -la && ls -la bantora-web

# Download dependencies
RUN ./gradlew dependencies --no-daemon || true

# Copy source code
COPY bantora-common/bantora-common-shared/src/main/java bantora-common/bantora-common-shared/src/main/java
COPY bantora-common/bantora-common-persistence/src/main/java bantora-common/bantora-common-persistence/src/main/java
COPY bantora-api/src/main/java bantora-api/src/main/java
COPY bantora-api/src/main/resources bantora-api/src/main/resources

# Build the application
RUN ./gradlew :bantora-api:bootJar -x test --no-daemon

# Runtime stage
FROM eclipse-temurin:25-jre-alpine

WORKDIR /opt/bantora

# Copy built JAR
COPY --from=builder /build/bantora-api/build/libs/bantora-api.jar app.jar

# Create log directory
ARG BANTORA_LOG_DEST=/var/log/bantora
RUN mkdir -p ${BANTORA_LOG_DEST} && \
  chmod 777 ${BANTORA_LOG_DEST}

# Create non-root user
RUN addgroup -g 1000 bantora && \
  adduser -u 1000 -G bantora -s /bin/sh -D bantora && \
  chown -R bantora:bantora /opt/bantora ${BANTORA_LOG_DEST}

USER bantora

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=180s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${API_INTERNAL_PORT}/actuator/health || exit 1

EXPOSE ${API_INTERNAL_PORT}

ENTRYPOINT ["java", "-jar", "app.jar"]
