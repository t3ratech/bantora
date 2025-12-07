/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

# Bantora Platform Architecture

## Table of Contents
- [Overview](#overview)
- [Microservices Architecture](#microservices-architecture)
- [Module Structure](#module-structure)
- [Core Implementation Patterns](#core-implementation-patterns)
- [Configuration Standards](#configuration-standards)
- [Logging Standards](#logging-standards)
- [Security Standards](#security-standards)
- [Database Architecture](#database-architecture)
- [API Communication Pattern](#api-communication-pattern)
- [Build & Deployment](#build--deployment)
- [Technical Specifications](#technical-specifications)

## Overview

Bantora is a Pan-African polling, consensus, and civic engagement platform built on a microservices architecture using Kotlin, Spring Boot WebFlux, and JDK 25. The system allows users to propose ideas, which are then processed by AI (Gemini) to create polls and summaries. The most popular ideas rise to the top, creating a clear signal of the continent's will.

This document serves as the definitive technical guide for all Bantora development work. Every implementation task MUST be verified against these specifications before coding begins.

## Microservices Architecture

The platform is structured into multiple services following microservices best practices:

### Service Architecture
- **bantora-database**: PostgreSQL 16 database service with custom configuration and health monitoring
- **bantora-api**: RESTful Reactive API service providing poll management, voting logic, and data persistence (WebFlux)
- **bantora-web**: Web interface service delivering the browser-based polling experience
- **bantora-gateway**: Nginx reverse proxy providing a unified entrypoint

This modular approach provides:
- **Separation of Concerns**: Each service handles a specific domain
- **Independent Deployment**: Services can be updated independently
- **Scalability**: Individual services can be scaled based on demand
- **Technology Diversity**: Each service can use optimal technology stacks

## Module Structure

### Core Modules
- **bantora-common-shared**: Shared DTOs, utilities, exceptions, and base models
- **bantora-common-persistence**: JPA entities, repositories, and database access layer

### Service Modules
- **bantora-database**: PostgreSQL database container with initialization scripts
- **bantora-api**: Reactive RESTful API with WebFlux
- **bantora-web**: User-facing web application (Flutter Web or SPA)
- **bantora-gateway**: Nginx reverse proxy for unified access

## Core Implementation Patterns

### 1. Reactive Programming with WebFlux
- All API endpoints return `Mono<T>` or `Flux<T>`
- Non-blocking I/O for high concurrency
- Reactive database access with R2DBC
- Backpressure handling for large datasets

### 2. Phone Number as Primary Identifier
- Unique identifier for users across the platform
- E.164 format validation (+263771234567)
- SMS verification for registration
- Multi-region support (all 55 African countries)

### 3. Quantum-Safe Security (Argon2id)
- Password hashing using Argon2id algorithm
- JWT tokens with RS256 signing
- Refresh token rotation
- Role-Based Access Control (RBAC)

### 4. Multi-Language Support
- 13 languages supported (en, sw, yo, zu, am, ar, fr, pt, ha, ig, so, af, sn)
- Resource bundles in `i18n/messages_{locale}.properties`
- Dynamic language switching
- RTL support for Arabic

### 5. AI Content Pipeline
- **Input**: Raw user ideas (Right Column).
- **Processing**: Scheduled job (Daily/On Restart) sends ideas to **Gemini API**.
- **Output**: Summarized concepts and structured polls (Middle Column).
- **Linkage**: Summaries maintain a reference to the original idea ID.
- **Popularity**: High engagement moves items to the "Popular" list (Left Column).

### 6. Regional Federation
- Polls categorized by scope: National, SADC, ECOWAS, EAC, AU, Continental
- Regional moderators and administrators
- Geolocation-based poll filtering
- Cross-border poll aggregation

## Configuration Standards

### Properties Files Structure
1. **Base config**: `application.properties` (never contains actual values)
2. **Profile overrides**: `application-{profile}.properties` (dev, docker, prod)
3. **Environment variables**: All actual values come from `.env` via Docker Compose
4. **NO YAML files**: Properties format only

### Property Naming Convention
```properties
# Correct
bantora.security.jwt.secret=${BANTORA_JWT_SECRET}
bantora.security.jwt.expiration.ms=${BANTORA_JWT_EXPIRATION_MS}

# Wrong (NO defaults)
bantora.security.jwt.secret=changeme
bantora.security.jwt.expiration.ms=86400000
```

### Service Port Configuration
- API binds to `server.port=${API_INTERNAL_PORT}`
- Web binds to `server.port=${WEB_INTERNAL_PORT}`
- Host port mapping via Docker Compose only
- Health checks use internal ports

## Logging Standards

### Configuration
- **Framework**: SLF4J + Logback
- **Pattern**: `%d{ISO8601} %-5level [%thread] %logger{36}: %msg%n%throwable`
- **Rolling Policy**: 10 MB max file size, 7-day retention
- **Location**: `${BANTORA_LOG_DEST}/bantora-{service}.log`

### Log Levels
- **Production**: INFO for application, WARN for frameworks
- **Development**: DEBUG for application, INFO for frameworks
- **Never**: TRACE in production

## Security Standards

### Authentication Flow
1. User registers/logins with phone number (Unique Identifier).
2. SMS verification code sent.
3. User confirms code and sets password.
4. Password hashed with Argon2id. (time=3, memory=65536, parallelism=24
5. JWT access token issued. (7 days expiry)
6. **Strict Enforcement**: Users must be logged in to vote or post. One vote per user per poll/idea is enforced at the database level.

### Authorization (RBAC)
- **Roles**: USER, MODERATOR, ADMIN, SUPERADMIN
- **Permissions**: CREATE_POLL, VOTE, MODERATE, MANAGE_USERS, SYSTEM_CONFIG
- **Scope**: National, Regional (SADC/ECOWAS/EAC), Continental

### API Security
- All `/api/**` endpoints require JWT token
- Public endpoints: `/api/v1/auth/**`, `/api/v1/polls/public/**`
- Rate limiting: 100 requests/minute per IP
- CORS: Configured via `BANTORA_ALLOWED_ORIGINS`

## Database Architecture

### Schema Design
```
bantora_db (PostgreSQL 16)
  ├── users (phone_number, password_hash, roles, verified, country_code)
  ├── ideas (id, user_id, content, timestamp, status)  <-- Raw user proposals
  ├── polls (id, title, description, idea_id, scope, region, creator_id, status) <-- Linked to ideas
  ├── poll_options (id, poll_id, text, votes_count)
  ├── votes (id, poll_id, option_id, user_id, timestamp) <-- Unique constraint (poll_id, user_id)
  ├── verification_codes (phone_number, code, expires_at, attempts)
  ├── refresh_tokens (token, user_id, expires_at, revoked)
  └── audit_logs (action, user_id, resource, timestamp, details)
```

### Data Persistence
- **ORM**: Hibernate with R2DBC for reactive access
- **Migrations**: Flyway versioned migrations
- **Initialization**: `V1__initial_schema.sql`, `V2__seed_data.sql`
- **Development**: `spring.jpa.hibernate.ddl-auto=validate`
- **Production**: `spring.flyway.enabled=true`

## API Communication Pattern

### RESTful API Standards
- **Base URL**: `/api/v1`
- **Versioning**: URI versioning (`/v1`, `/v2`)
- **Methods**: GET, POST, PUT, DELETE, PATCH
- **Status Codes**: 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 500 (Internal Error)

### Response Format
```json
{
  "success": true,
  "data": { ... },
  "message": "Poll created successfully",
  "timestamp": "2025-11-28T13:55:00Z"
}
```

### API Endpoints

#### Authentication
- `POST /api/v1/auth/register` - Register with phone number
- `POST /api/v1/auth/verify` - Verify SMS code
- `POST /api/v1/auth/login` - Login with phone + password
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Revoke refresh token

#### Polls
- `GET /api/v1/polls` - List polls (paginated, filtered)
- `POST /api/v1/polls` - Create new poll
- `GET /api/v1/polls/{id}` - Get poll details
- `PUT /api/v1/polls/{id}` - Update poll (moderator)
- `DELETE /api/v1/polls/{id}` - Delete poll (admin)
- `POST /api/v1/polls/{id}/vote` - Cast vote
- `GET /api/v1/polls/{id}/results` - Get real-time results

#### Users
- `GET /api/v1/users/me` - Get current user profile
- `PUT /api/v1/users/me` - Update profile
- `POST /api/v1/users/me/language` - Set preferred language

#### Admin
- `GET /api/v1/admin/polls/pending` - Polls awaiting approval
- `POST /api/v1/admin/polls/{id}/approve` - Approve poll
- `POST /api/v1/admin/polls/{id}/reject` - Reject poll
- `GET /api/v1/admin/users` - List users (paginated)
- `PUT /api/v1/admin/users/{id}/role` - Update user role

## Build & Deployment

### Technology Stack
- **Language**: Kotlin 2.1.0
- **JDK**: 25 (OpenJDK)
- **Framework**: Spring Boot 3.4.0 with WebFlux
- **Build Tool**: Gradle 8.11.1 with Kotlin DSL
- **Database**: PostgreSQL 16 with R2DBC
- **Cache**: Redis 7.4
- **Container**: Docker with multi-stage builds
- **Orchestration**: Docker Compose

### Frontend Stack (Flutter)
- **Framework**: Flutter 3.38.3
- **Language**: Dart 3.10.1
- **HTTP Client**: http ^1.6.0
- **Build Size**: 2.5 MB (main.dart.js)
- **Web Renderer**: HTML renderer (optimized)
- **Icons**: Tree-shaken (99.5% size reduction)

### Build Commands
```bash
# Build all modules
./gradlew clean build -x test

# Build specific module
./gradlew :bantora-api:bootJar -x test

# Run tests
./gradlew test

# Docker build
./bantora-docker.sh -rrr bantora-api
```

### Network Configuration

| Service | Internal Port | External Port | Internal URL | External URL |
|---------|--------------|---------------|--------------|-------------|
| bantora-gateway | 3083 | 3083 | http://bantora-gateway:3083 | http://localhost:3083 |
| bantora-database | 5432 | 5432 | jdbc:postgresql://bantora-database:5432/bantora_db | localhost:5432 |
| bantora-api | 3081 | 3081 | http://bantora-api:3081 | http://localhost:3081 |
| bantora-web | 3080 | 3080 | http://bantora-web:3080 | http://localhost:3080 |
| bantora-redis | 6379 | 6379 | redis://bantora-redis:6379 | localhost:6379 |

### Application URLs
- **Homepage**: `http://localhost:3080/`
- **API Base**: `http://localhost:3081/api/v1`
- **API Health**: `http://localhost:3081/actuator/health`
- **Swagger UI**: `http://localhost:3081/swagger-ui.html`
- **Gateway**: `http://localhost:3083/`

## Technical Specifications

### JDK 25 Configuration
```kotlin
// build.gradle.kts
configure<JavaPluginExtension> {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(25))
    }
}

tasks.withType<KotlinCompile> {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_25)
    }
}
```

### Kotlin Coroutines with WebFlux
```kotlin
@RestController
@RequestMapping("/api/v1/polls")
class PollController(private val pollService: PollService) {
    
    @GetMapping
    suspend fun listPolls(@RequestParam scope: String?): Flow<PollDTO> {
        return pollService.findByScope(scope)
    }
    
    @PostMapping
    suspend fun createPoll(@RequestBody request: CreatePollRequest): PollDTO {
        return pollService.create(request)
    }
}
```

### Argon2id Configuration
```kotlin
// SecurityConfig.kt
val argon2 = Argon2Factory.create(
    Argon2Factory.Argon2Types.ARGON2id,
    32,      // salt length
    64       // hash length
)

fun hashPassword(password: String): String {
    return argon2.hash(
        3,       // iterations
        65536,   // memory (64 MB)
        4,       // parallelism
        password.toCharArray()
    )
}
```

## Swagger/OpenAPI Documentation

### Configuration
```kotlin
@Configuration
class OpenApiConfig {
    @Bean
    fun openAPI(): OpenAPI {
        return OpenAPI()
            .info(Info()
                .title("Bantora API")
                .version("v1.0")
                .description("Pan-African Polling & Civic Engagement Platform")
            )
            .addSecurityItem(SecurityRequirement().addList("bearer-jwt"))
            .components(Components()
                .addSecuritySchemes("bearer-jwt", SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                )
            )
    }
}
```

## Development Workflow

### Getting Started
1. Clone repository
2. Copy `.env.example` to `.env` and configure
3. Run `./bantora-docker.sh -rrr bantora-database bantora-api bantora-web`
4. Access Swagger UI at `http://localhost:3081/swagger-ui.html`
5. Access web application at `http://localhost:3080`

### Testing Strategy
- **Unit Tests**: JUnit 5 + MockK
- **Integration Tests**: Testcontainers (PostgreSQL, Redis)
- **API Tests**: WebTestClient
- **Load Tests**: Gatling for reactive performance
- **Security Tests**: OWASP ZAP

### CI/CD Pipeline
- **GitHub Actions**: Automated builds, tests, and Docker image creation
- **Environments**: Development, Staging, Production
- **Deployment**: VPS with Docker Compose or Kubernetes

## Success Criteria

All features MUST meet these criteria:
- ✅ No hardcoded values (all config from `.env`)
- ✅ Fail-fast on missing configuration
- ✅ All endpoints reactive (Mono/Flux)
- ✅ Argon2id password hashing
- ✅ JWT with refresh tokens
- ✅ Phone number validation (E.164)
- ✅ Multi-language support
- ✅ Swagger documentation
- ✅ Health checks pass
- ✅ Unit tests > 80% coverage
- ✅ Integration tests for critical paths
- ✅ Docker builds successfully
- ✅ Properties files (no YAML)
- ✅ JDK 25 compatible

---

**Last Updated**: 2025-11-28
**Maintainer**: Tsungai Kaviya <tkaviya@t3ratech.co.zw>
