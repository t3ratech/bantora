# BANTORA

### *A Pan-African Polling, Consensus & Civic Engagement Platform*

Open-Source • AI-Driven • Built for 1.4 Billion Africans

---

## 🌍 Overview

**BANTORA** is a Pan-African digital platform designed to give Africans a unified voice on political, economic, cultural, and developmental issues. It enables users across all 55 African nations to vote on polls, submit ideas, express opinions, and shape the continent’s future—independently from political actors.

The long-term vision is a secure, scalable system capable of hosting continental-level polls and eventually validating AU-recognized digital elections.

---

## 🎯 Mission

To empower Africans by providing a transparent, secure, and AI-driven platform for collective decision-making—allowing millions of voices to influence policies, agendas, and leadership long before politics catches up.

---

## 💡 Core Concept

BANTORA acts as a **Pan-African digital referendum engine** where ideas evolve into consensus.

The flow is simple:
1.  **Propose**: Users submit raw ideas for reforms, projects, or policies and must select:
    - A **category**
    - One or more **hashtags**
2.  **AI Processing (Hourly)**: The system runs an hourly pipeline that:
    - Selects the **top 2 hashtags** with the most unprocessed ideas
    - Builds a size-bounded prompt from as many idea summaries as possible for that hashtag
    - Asks the AI to deduplicate/merge similar ideas, reject infeasible/unclear ones, and produce a reduced set of high-quality polls
    - Creates polls (and options) and links each poll back to the original idea IDs used
    - Marks the picked-up ideas as processed so they are never picked up again
3.  **Vote**: Users vote on these polls.
    *   **Upvote** an idea.
    *   **Vote Yes/No** on a poll.
    *   **Choose** between multiple options.
4.  **Consensus**: Items with the most upvotes or "Yes" votes are deemed "Popular Concepts" and move to a prominent list.

**The Web UI uses a tabbed Home Page:**
*   **Polls tab**: Current polls + popular polls.
*   **Ideas tab**: New ideas + popular ideas.

Both tabs support filtering by **category** and **hashtag**.

*One platform. One voice. One Africa.*

---

## 🤖 AI Integration

The **AI Service** is the engine that turns noise into signal.

*   **Summarization**: The system stores an AI-ready summary per idea (used for prompt building).
*   **Hashtag batching**: The hourly job processes the 2 biggest unprocessed hashtags.
*   **Poll generation**: The AI returns a reduced set of relevant polls (and options), after deduplication/feasibility filtering.
*   **Traceability**: Every created poll stores the list of source idea IDs that were used.
*   **Deep links + sharing**: Polls and ideas have dedicated links and share buttons (Facebook, X, WhatsApp, Threads, Email).

Note: Users can only vote once per poll. Login via phone number is mandatory for all write actions (vote, submit idea, upvote).

---

## 🧱 Tech Stack

### Frontend

- Flutter Web (Dart)
- Served via Nginx container (`bantora-web`)

### Backend

- Spring Boot 3.5.0 (WebFlux)
- JDK 25 (enforced via Gradle toolchain)
- Gradle wrapper 9.2.1
- PostgreSQL 16
- Redis 7
- JWT access + refresh tokens (HMAC secret)
- Argon2id password hashing

### Infrastructure

* Docker
* Linux
* Terraform (IaC)
* VPS or self-hosted bare metal
* GitHub Actions (CI/CD)

### **Architecture**

* Microservices-ready REST backend
* Stateless JWT auth with refresh tokens
* Redis caching for fast poll results
* AI microservice for classification & poll generation
* PostgreSQL for persistence
* Event-driven modules for scalability

---

## 🛡 Security

* Password hashing: **Argon2id** (quantum-resistant)
* Strict RBAC for admin/moderator access
* Secure JWT implementation
* Audit logs for poll creation & modifications
* Rate limiting & anti-bot protection
* Optional KYC module (off by default)

---

## 🔑 Features (MVP)

### 🎙 **User Features**

*   **Login**: Secure login via phone number (Unique Identifier).
*   **Propose**: Submit raw ideas for the continent.
*   **Vote**:
    *   Strict **One User, One Vote** policy.
    *   Upvote ideas or vote on polls.
*   **View**:
    *   **Popular Concepts** (Left Column).
    *   **New AI Polls** (Middle Column).
    *   **Raw Feed** (Right Column).
*   **Drill-down**: Click summaries to see original user posts.

### Registration Requirements

- Registration requires selecting an African country (African countries only).
- The selected country determines:
  - The phone calling-code prefix shown next to the phone number input
  - A country flag indicator displayed in the phone input
  - The default preferred language and currency used during registration
- Preferred language is persisted to the user profile.

### 🧠 **AI Features**

* Ideas → AI → Poll creation
* Topic classification (AU, SADC, ECOWAS, national)
* Deduplication of similar proposals
* Automatic poll summaries

### 🛠 **Admin/Moderator Features**

* Approve AI-generated polls
* Remove spam/abuse
* Manage user roles
* View dashboards & analytics

---

## Implemented

- Login + registration UI and backend endpoints
- Authenticated-only vote, idea submission, and idea upvote
- Search filtering across polls + ideas
- Theme (light/dark) with persistence
- Patrol 4.0 UI tests (Dart) with screenshot/manual verification support

---

## 🚀 Deployment

### Google Cloud Platform (GCP)

Bantora Deployment is fully automated using Terraform and `bantora-docker.sh`.

#### Prerequisites
1. **Google Cloud SDK**: Install `gcloud` CLI.
2. **Terraform**: Install Terraform (>= 1.0).
3. **GCP Project**: A GCP project with billing enabled.
4. **Credentials**:
  - Ensure the required environment variables for deployment are set locally (do not commit secrets):
    - Create `~/.gcp/credentials_bantora` file:
      ```bash
      export GCP_PROJECT_ID="your-project-id"
      export GCP_REGION="us-central1"
      export DB_PASSWORD="secure-password"
      export JWT_SECRET="secure-jwt-secret"
      export GEMINI_API_KEY="your-gemini-api-key"
      ```
  - Authenticate: `gcloud auth login` and `gcloud auth application-default login`.

#### Deploy
Run the following command to build and deploy all services:
```bash
./bantora-docker.sh --deploy
```

This will:
1. Initialize Terraform.
2. Create/Update Infrastructure (Cloud Run, Cloud SQL, Redis).
3. Build and push Docker images to Artifact Registry.
4. Deploy services to Cloud Run.

#### Production URLs
After successful deployment, the services are available at:
- **API Service**: https://bantora-api-a2y2msttda-bq.a.run.app
- **Web Frontend**: https://bantora-web-a2y2msttda-bq.a.run.app

### Local Development
Use `bantora-docker.sh` for container lifecycle and testing.

---

## 🚀 Roadmap

### **Phase 1 — MVP (2–4 weeks)**

* Flutter app
* Spring Boot API
* Basic poll creation & voting
* PostgreSQL + Redis setup
* AI auto-generation of polls
* Dockerized deployment
* GitHub Actions CI/CD
* VPS deployment

### **Phase 2 — Scaling (1–3 months)**

* Federation of polls by region
* Moderator dashboard
* Social sharing
* Voter verification (phone/email)
* Low-bandwidth mode for rural users

### **Phase 3 — Long-Term (6–24 months)**

* Election-grade cryptographic proofs
* AU-level or regional adoption
* Blockchain-backed transparency module
* Multi-country local chapters
* Offline voting (USSD)
* Research API for universities & policymakers

---

## 💬 Philosophy & Vision

Africa has 1.4 billion people but no single democratic platform where citizens can directly shape the future of the continent.

**BANTORA exists to change that.**

This is not a political party—
It is a *people’s platform for collective decision-making.*

When 200 million Africans vote, that consensus becomes a permanent, unstoppable truth.

---

## 👥 Contributing

We welcome contributors, especially Africans in tech.

### Tech stack contributions needed:

* Spring Boot engineers
* Flutter engineers
* AI/ML specialists
* DevOps & Terraform
* Translators (Swahili, Yoruba, Zulu, Amharic, Arabic, etc.)

Fork → Create PR → Peer review → Merge.

---

## 📂 Repository Structure

```
bantora/
 ├── bantora-api/                      # RESTful Reactive API (Spring Boot WebFlux)
 ├── bantora-web/                      # Web interface (Flutter Web/SPA)
 ├── bantora-common/
 │   ├── bantora-common-shared/        # Shared DTOs, utilities, exceptions
 │   └── bantora-common-persistence/   # JPA entities, repositories
 ├── bantora-database/                 # PostgreSQL initialization scripts
 ├── bantora-gateway/                  # Nginx reverse proxy configuration
 ├── logs/                             # Service logs
 ├── .env                              # Environment configuration
 ├── docker-compose.yml                # Docker Compose orchestration
 ├── bantora-docker.sh                 # Management script
 ├── ARCHITECTURE.md                   # Technical architecture documentation
 └── README.md
```

## 🚀 Quick Start

### Prerequisites
- JDK 25
- Docker and Docker Compose
- Gradle 9.2.1
- Flutter (for building `bantora-web` assets)

### Setup & Run

1. Clone the repository

2. Configure `.env` (non-secret runtime configuration only)

3. Configure `~/.gcp/credentials_bantora` (secrets: JWT, Twilio, Gemini, DB/Redis passwords)

4. Build Flutter web assets (required; `bantora-web` Dockerfile expects `bantora_app/build/web` to exist):

```bash
./bantora-docker.sh --build-web http://localhost:3083
```

5. Rebuild and start everything:

```bash
./bantora-docker.sh --rebuild-all
```

### Database Seed Data (Local + Tests)

The API uses Flyway migrations under `bantora-api/src/main/resources/db/migration`.

- **`V1__bantora_schema.sql`** creates the full schema.
- **`V2__bantora_seed.sql`** seeds:
  - African country metadata (for registration)
  - Categories and hashtags
  - Baseline polls (ACTIVE and non-expired) and ideas

Patrol UI tests rely on this baseline data to ensure the home screen is not empty.

6. Access:

- Web UI: `http://localhost:3080`
- Gateway: `http://localhost:3083`
- API (direct): `http://localhost:3081/api`
- Swagger UI: `http://localhost:3081/swagger-ui.html`

### Common Commands

Build Flutter web assets:

```bash
./bantora-docker.sh --build-web http://localhost:3083
```

Rebuild all services:

```bash
./bantora-docker.sh --rebuild-all
```

Check service status:

```bash
./bantora-docker.sh --status
```

Run all tests:

```bash
./bantora-docker.sh --test all
```

Run Patrol UI tests only:

```bash
./bantora-docker.sh --test patrol
```

View logs:

```bash
./bantora-docker.sh --logs --tail 200 bantora-api
```

---

## 📜 License

Open-source (MIT or Apache 2.0 recommended)

---

## 🔥 Slogan Ideas

* **One Africa. One Voice.**
* **Where Africans Decide.**
* **Your Vote, Our Future.**
* **Digital Democracy for a United Africa.**

---

## 🟧 Author

Built by **Bantora Community**.
Architech & Maintainer: **Tsungai Kaviya**
For collaboration, please join our WhatsApp Channel: https://chat.whatsapp.com/BnlKyxTtLg57nwL7aX92fV