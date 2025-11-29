# JDK 25 Setup Guide for Bantora

## ✅ Successfully Configured with JDK 25

This project is configured to **strictly use JDK 25** with the following critical components:

### Required Components

1. **JDK 25** (OpenJDK 25.0.1)
   - Version: `25.0.1+8-Ubuntu-124.04`
   - Required for all builds and runtime

2. **Gradle 9.2.1**
   - First Gradle version to support JDK 25
   - Configured in `gradle/wrapper/gradle-wrapper.properties`

3. **Lombok edge-SNAPSHOT**
   - Regular Lombok versions do NOT support JDK 25
   - Must use edge-SNAPSHOT from `https://projectlombok.org/edge-releases`
   - Configured in `build.gradle`

4. **Spring Boot 3.5.0**
   - Latest Spring Boot with JDK 25 support
   - Uses WebFlux for reactive programming

### Why Pure Java (Not Kotlin)?

**Critical Issue**: Kotlin 2.1.0 (latest version) does **NOT** support JDK 25.

The Kotlin compiler fails with:
```
java.lang.IllegalArgumentException: 25.0.1
at org.jetbrains.kotlin.com.intellij.util.lang.JavaVersion.parse
```

**Solution**: Converted entire codebase to Pure Java to maintain JDK 25 compatibility.

### Build Configuration

#### build.gradle
```groovy
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.5.0' apply false
    id 'io.spring.dependency-management' version '1.1.7' apply false
}

allprojects {
    repositories {
        mavenCentral()
        maven { url 'https://repo.spring.io/milestone' }
        maven { url 'https://projectlombok.org/edge-releases' }  // CRITICAL for JDK 25
    }
}

subprojects {
    java {
        toolchain {
            languageVersion = JavaLanguageVersion.of(25)  // JDK 25
        }
        sourceCompatibility = JavaVersion.VERSION_25
        targetCompatibility = JavaVersion.VERSION_25
    }
}

ext {
    springBootVersion = '3.5.0'
    lombokVersion = 'edge-SNAPSHOT'  // MUST be edge-SNAPSHOT for JDK 25
}
```

#### gradle/wrapper/gradle-wrapper.properties
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.2.1-bin.zip
```

### Verification

```bash
# Verify JDK version
java -version
# Should show: openjdk version "25.0.1"

# Build with JDK 25
./gradlew clean build -x test

# Should complete successfully with:
# BUILD SUCCESSFUL in Xs
```

### Docker Configuration

The Dockerfiles use `eclipse-temurin:25-jdk-alpine` for build stage and `eclipse-temurin:25-jre-alpine` for runtime.

### Key Learnings

1. **JDK 25 is bleeding edge** - Limited library support
2. **Kotlin not compatible** - Requires Java-only codebase
3. **Lombok edge required** - Stable versions fail
4. **Gradle 9.2.1+ required** - Earlier versions don't support JDK 25
5. **Spring Boot 3.5.0** - First version with good JDK 25 support

### Troubleshooting

If build fails:
1. Verify JDK 25 is installed: `java -version`
2. Check Gradle wrapper is 9.2.1+
3. Ensure Lombok edge-SNAPSHOT repository is configured
4. Clear Gradle cache: `./gradlew clean --no-daemon`

### References

- [Gradle JDK Compatibility](https://docs.gradle.org/current/userguide/compatibility.html)
- [Project Lombok Edge Releases](https://projectlombok.org/download-edge)
- [Spring Boot 3.5.0 Release Notes](https://spring.io/blog/2024/11/21/spring-boot-3-5-0-available-now)
