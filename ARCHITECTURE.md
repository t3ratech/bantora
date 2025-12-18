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

Bantora is a Pan-African polling, consensus, and civic engagement platform built on a microservices architecture using Java, Spring Boot WebFlux, and JDK 25. The primary user experience is a Flutter Web UI served by Nginx, backed by a reactive API. Users register/login, then can submit ideas and vote on polls; ideas can be processed via Gemini to generate poll-like summaries. The most popular ideas rise to the top, creating a clear signal of the continent's will.

This document serves as the definitive technical guide for all Bantora development work. Every implementation task MUST be verified against these specifications before coding begins.

## Deployment Architecture (GCP)

The production environment is hosted on Google Cloud Platform using serverless technologies.

### Infrastructure Components
- **Compute**: Google Cloud Run (Serverless Containers)
    - `bantora-api`: Backend service (Java/Spring Boot)
    - `bantora-web`: Frontend service (Flutter/Nginx)
- **Database**: Cloud SQL for PostgreSQL (Enterprise Edition)
- **Caching**: Cloud Memorystore (Redis)
- **Networking**:
    - **VPC Network**: Custom VPC for secure internal communication.
    - **Serverless VPC Access**: Connects Cloud Run to Cloud SQL and Redis.
- **Registry**: Artifact Registry (Docker images).

### Automation
- **Terraform**: Manages all infrastructure as code (`terraform/`).
- **Scripts**: `ops/scripts/setupGCP.sh` handles the build and deploy pipeline.
- **Integration**: `bantora-docker.sh --deploy` provides a unified entry point.

### Production Endpoints
- **API Service**: https://bantora-api-a2y2msttda-bq.a.run.app
- **Web Frontend**: https://bantora-web-a2y2msttda-bq.a.run.app
- **Health Check**: https://bantora-api-a2y2msttda-bq.a.run.app/actuator/health

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
- Registration UI must restrict selection to African countries only; the selected country determines the phone calling code prefix used to construct the E.164 phone number.
- SMS verification is planned (schema and config exist), but the current registration flow marks users as verified and the `/api/v1/auth/verify` endpoint is intentionally not implemented.
- Multi-region support (all 55 African countries)

### 3. Quantum-Safe Security (Argon2id)
- Password hashing using Argon2id algorithm
- JWT tokens signed with an HMAC secret key (base64-encoded secret), issued as access + refresh tokens
- Refresh token rotation (refresh tokens are stored and revoked on refresh)
- Role-Based Access Control (RBAC) is scaffolded (roles exist in tokens / DB), with endpoint-level enforcement currently focused on authenticated write operations

### 4. Multi-Language Support
- Supported locales are configured via `BANTORA_SUPPORTED_LOCALES` (defaults are not permitted).
- Users select a preferred language during registration; the selection is persisted to the user profile and used as the default language after login.
- The registration screen may default to English only when no country-based preference is available.

### 4.1 African Country Metadata (Registration)
- The system maintains an authoritative set of African countries only.
- Each country entry must include:
  - ISO 3166-1 alpha-2 code (e.g., `ZW`)
  - E.164 calling code prefix (e.g., `+263`)
  - Default/preferred language (BCP-47 language tag, e.g., `en`, `sw`, `fr`, `ar`)
  - Currency code (ISO 4217, e.g., `ZWL`)
  - A UI flag indicator (rendered in UI; e.g., emoji or asset)
- Registration uses this metadata to:
  - Restrict selectable countries to Africa only
  - Display `[FLAG] +<calling-code> [local-number]` and construct the E.164 phone number
  - Prepopulate preferred language and currency
- Backend must validate that the selected country is African and reject non-African country codes.

### 5. AI Content Pipeline
- **Input**: User-submitted ideas. Each idea requires:
  - A **category**
  - One or more **hashtags**
- **Idea creation**: No AI processing occurs at idea creation time.
- **Processing cadence**: A scheduled job runs **once per hour**.
- **Hashtag selection**: Each run selects the **top 2 hashtags** with the highest count of **unprocessed ideas**.
- **Prompt building**: For each selected hashtag, the system builds a single prompt containing as many idea summaries as possible (bounded by token/size limits), and instructs the AI to:
  - Deduplicate / merge similar ideas
  - Reject infeasible or unclear ideas
  - Return a reduced, high-quality set of polls
- **Output**: Polls (and options) are created from the AI response.
- **Traceability**: Each created poll persists an explicit list of **source idea IDs** that contributed to the poll.
- **Idempotency**: Ideas picked up by the hourly job are marked **processed** and must never be picked up again.

### 6. Regional Federation
- Polls categorized by scope: National, SADC, ECOWAS, EAC, AU, Continental
- Regional moderators and administrators
- Geolocation-based poll filtering
- Cross-border poll aggregation

## Configuration Standards

### Properties Files Structure
1. **Base config**: `application.properties` (never contains actual values)
2. **Profile overrides**: `application-{profile}.properties` (dev, docker, prod)
3. **Non-secret environment variables**: Loaded from repo `.env` via `bantora-docker.sh`
4. **Secret environment variables**: Loaded from `~/.gcp/credentials_bantora` via `bantora-docker.sh`
5. **NO YAML files**: Properties format only

### Secrets Management
- Secrets must never be committed to the repository.
- `bantora-docker.sh` must source `~/.gcp/credentials_bantora` (fail-fast if missing or incomplete) before running Docker Compose, tests, or deployment.
- Secrets include:
  - Database password
  - Redis password
  - JWT secret
  - Gemini API key
  - SMS provider credentials (e.g., Twilio Account SID + Auth Token)

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
2. Password is hashed with Argon2id (configured via environment variables).
3. JWT access token + refresh token are issued.
4. Refresh tokens are persisted and rotated (revoked-on-refresh).
5. **Strict Enforcement**: Users must be logged in to vote, submit ideas, or upvote ideas. One vote per user per poll is enforced via a database unique constraint.

SMS verification is not currently part of the running UI flow; `/api/v1/auth/verify` fails fast to avoid implying SMS is implemented.

### Authorization (RBAC)
- **Roles**: USER, MODERATOR, ADMIN, SUPERADMIN
- **Permissions**: CREATE_POLL, VOTE, MODERATE, MANAGE_USERS, SYSTEM_CONFIG
- **Scope**: National, Regional (SADC/ECOWAS/EAC), Continental

### API Security
- Public endpoints:
  - `/api/v1/auth/**`
  - `/actuator/**`
  - `GET /api/**`
- Authenticated endpoints (write operations):
  - `POST /api/votes`
  - `POST /api/ideas`
  - `POST /api/ideas/{id}/upvote`
- Rate limiting is implemented at the gateway layer.
- CORS: Configured via `BANTORA_ALLOWED_ORIGINS`.

## Database Architecture

### Schema Design
**Clean-slate only**: The database is always assumed to start blank.

**Flyway policy**: Flyway must consist of exactly **two** migrations:
- **1 schema migration**: creates all tables, constraints, and indexes
- **1 data migration**: seed data only

Do **not** write legacy/backfill/compatibility migrations and do **not** rely on Flyway baseline/baseline-on-migrate behavior.

The authoritative schema is defined in Flyway migrations under `bantora-api/src/main/resources/db/migration`.

The seed migration must include baseline data required for:
- Registration (African countries)
- Idea creation (categories and hashtags)
- Predictable local development and UI testing (non-expired ACTIVE polls and PENDING ideas)

Key tables (PostgreSQL 16):
```
bantora_user (phone_number PK, password_hash, country_code, verified, enabled, preferred_language, ...)
bantora_user_role (phone_number, role)
bantora_poll (id, title, description, creator_phone, scope, status, allow_anonymous, total_votes, ...)
bantora_poll_option (id, poll_id, option_text, votes_count, ...)
bantora_vote (id, poll_id, option_id, user_phone, anonymous, voted_at, ...)
bantora_idea (id, user_phone, content, category_id, processed_at, upvotes, created_at, updated_at, ...)
bantora_category (id, name, created_at, ...)
bantora_hashtag (id, tag, created_at, ...)
bantora_idea_hashtag (idea_id, hashtag_id)
bantora_poll_source_idea (poll_id, idea_id)
bantora_verification_code (phone_number, code, expires_at, attempts, verified)
bantora_refresh_token (id, token, user_phone, expires_at, revoked)
```

### Data Persistence
- **Reactive access**: Spring Data R2DBC repositories for runtime operations
- **Migrations**: Flyway migrations (exactly 1 schema + 1 seed data migration)
- **JPA**: Enabled for schema validation and Flyway JDBC connectivity (dev profile uses `spring.jpa.hibernate.ddl-auto=validate`)

## API Communication Pattern

### RESTful API Standards
- **Auth base URL**: `/api/v1/auth`
- **Application base URL**: `/api`
- **Versioning**: URI versioning (`/v1`, `/v2`)
- **Methods**: GET, POST, PUT, DELETE, PATCH
- **Status Codes**: 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 500 (Internal Error)

### Response Format
There are two response shapes currently in use:

1. `ApiResponse<T>` wrapper (used by auth endpoints)
2. Simple map payloads (used by `/api/**` endpoints) with keys like `success`, `data`, `error`, `timestamp`

### API Endpoints

#### Authentication
- `POST /api/v1/auth/register` - Register with phone number
- `POST /api/v1/auth/login` - Login with phone + password
- `POST /api/v1/auth/refresh` - Refresh access token (refresh token in `Authorization` header)
- `POST /api/v1/auth/logout` - Revoke refresh token
- `POST /api/v1/auth/verify` - Not implemented (fails fast)

#### Polls
- `GET /api/polls` - List polls
- `GET /api/polls/{id}` - Get poll details
- `GET /api/polls/popular` - List popular polls
- `POST /api/votes` - Cast vote (authenticated)

#### Ideas
- `GET /api/ideas` - List pending ideas by default
- `POST /api/ideas` - Create idea (authenticated; requires category + hashtags)
- `POST /api/ideas/{id}/upvote` - Upvote idea (authenticated)

#### Categories / Hashtags
- `GET /api/categories` - List categories (for idea creation + filtering)
- `GET /api/hashtags` - List/search hashtags (for idea creation + filtering)

#### Poll Traceability
- `GET /api/polls/{id}` - Must return poll detail including source idea IDs (and/or an embedded source idea list)

## Build & Deployment

### Technology Stack
- **Language**: Java
- **JDK**: 25
- **Framework**: Spring Boot 3.5.0 with WebFlux
- **Build Tool**: Gradle wrapper 9.2.1
- **Database**: PostgreSQL 17
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
All builds and test runs are driven through `bantora-docker.sh`.

```bash
# Rebuild all services in dependency order
./bantora-docker.sh --rebuild-all

# Rebuild a specific service
./bantora-docker.sh -rrr bantora-api

# Build Flutter web (compile-time API_URL)
./bantora-docker.sh --build-web http://localhost:3083

# Run tests (unit, integration, patrol, all)
./bantora-docker.sh --test unit
./bantora-docker.sh --test integration
./bantora-docker.sh --test patrol
./bantora-docker.sh --test all
```

### Network Configuration

| Service | Internal Port | External Port | Internal URL | External URL |
|---------|--------------|---------------|--------------|-------------|
| bantora-gateway | 3083 | 3083 | http://bantora-gateway:3083 | http://localhost:3083 |
| bantora-database | 3432 | 3432 | jdbc:postgresql://bantora-database:3432/bantora_db | localhost:3432 |
| bantora-api | 3081 | 3081 | http://bantora-api:3081 | http://localhost:3081 |
| bantora-web | 3080 | 3080 | http://bantora-web:3080 | http://localhost:3080 |
| bantora-redis | 3379 | 3379 | redis://bantora-redis:3379 | localhost:3379 |

### Application URLs
- **Homepage**: `http://localhost:3080/`
- **API Base**: `http://localhost:3081/api`
- **API Health**: `http://localhost:3081/actuator/health`
- **Swagger UI**: `http://localhost:3081/swagger-ui.html`
- **Gateway**: `http://localhost:3083/`

### UI Test Screenshots
Patrol test artifacts are written to:

`bantora-web/bantora_app/test-results/`

## Technical Specifications

### JDK 25 Configuration
This repository enforces JDK 25 via Gradle toolchains in the root `build.gradle`.

### Argon2id Configuration
Argon2id parameters are injected from environment variables (see `.env` keys prefixed with `BANTORA_ARGON2_`).

## Swagger/OpenAPI Documentation

### Configuration
```java
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Bantora API")
                        .version("v1.0.0")
                        .description("Pan-African Polling, Consensus & Civic Engagement Platform API"))
                .addSecurityItem(new SecurityRequirement().addList("bearer-jwt"))
                .components(new Components()
                        .addSecuritySchemes("bearer-jwt", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .in(SecurityScheme.In.HEADER)
                                .name("Authorization")));
    }
}
```

## Development Workflow

### Getting Started
1. Clone repository
2. Ensure `.env` is present and configured for your environment
3. Build Flutter web assets (requires Flutter on host): `./bantora-docker.sh --build-web http://localhost:3083`
4. Run `./bantora-docker.sh --rebuild-all`
5. Access Swagger UI at `http://localhost:3081/swagger-ui.html`
6. Access web application at `http://localhost:3080`

### Testing Strategy
- **Unit Tests**: JUnit 5 + Spring Boot Test
- **Integration Tests**: Testcontainers (PostgreSQL) and Spring Boot test profile
- **UI Tests**: Patrol 4.0 (Dart) running on web (`--device chrome`), using stable Flutter Semantics labels for interaction and assertions.

### CI/CD Pipeline
- **GitHub Actions**: Automated builds, tests, and Docker image creation
- **Environments**: Development, Staging, Production
- **Deployment**: VPS with Docker Compose or Kubernetes

## Success Criteria

All features MUST meet these criteria:
- No hardcoded values (all config from `.env`)
- Fail-fast on missing configuration
- All endpoints reactive (Mono/Flux)
- Argon2id password hashing
- JWT with refresh tokens
- Phone number validation (E.164)
- Multi-language support
- Swagger documentation
- Health checks pass
- Unit tests > 80% coverage
- Integration tests for critical paths
- Docker builds successfully
- Properties files (no YAML)
- JDK 25 compatible

---

**Last Updated**: 2025-12-15
**Maintainer**: Tsungai Kaviya <tkaviya@t3ratech.co.zw>
