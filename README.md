# BANTORA

### *A Pan-African Polling, Consensus & Civic Engagement Platform*

Open-Source • AI-Driven • Built for 1.4 Billion Africans

---

## 🌍 Overview

**BANTORA** is a Pan-African digital platform designed to give Africans a unified voice on political, economic, cultural, and developmental issues. It enables users across all 55 African nations to vote, create polls, express opinions, and shape the continent’s future—independently from political actors.

The long-term vision is a secure, scalable system capable of hosting continental-level polls and eventually validating AU-recognized digital elections.

---

## 🎯 Mission

To empower Africans by providing a transparent, secure, and AI-driven platform for collective decision-making—allowing millions of voices to influence policies, agendas, and leadership long before politics catches up.

---

## 💡 Core Concept

BANTORA acts as a **Pan-African digital referendum engine** where ideas evolve into consensus.

The flow is simple:
1.  **Propose**: Users submit raw ideas for reforms, projects, or policies.
2.  **AI Processing**: The system (via Gemini API) analyzes these ideas daily (or on restart), summarizes them, and converts them into structured polls or questions.
3.  **Vote**: Users vote on these summarized ideas/polls.
    *   **Upvote** an idea.
    *   **Vote Yes/No** on a poll.
    *   **Choose** between multiple options.
4.  **Consensus**: Items with the most upvotes or "Yes" votes are deemed "Popular Concepts" and move to a prominent list.

**The Web UI features a 3-Column Layout:**
*   **Left Column (Popular)**: The "Hall of Fame" for ideas and polls that have gained significant traction.
*   **Middle Column (New/AI)**: Freshly generated polls and summaries created by the AI from user submissions.
*   **Right Column (Raw)**: A live feed of raw ideas posted by users, waiting to be picked up by the AI.

*One platform. One voice. One Africa.*

---

## 🤖 AI Integration

The **AI Service** is the engine that turns noise into signal.

*   **Summarization**: Uses **Gemini API** to read user ideas and return a concise, neutral summary.
*   **Linkage**: Clicking on an AI-generated summary takes the user back to the original raw idea for full context.
*   **Poll Generation**: Automatically creates voting options based on the idea's content.
*   **Scheduling**: AI processing runs once a day or when the system is restarted to process new batch of ideas.

*Note: Users can only vote ONCE per poll/idea. To ensure this, login via phone number is mandatory.*

---

## 🧱 Tech Stack

### **Frontend**

* Flutter (mobile + web)
* Kotlin (Android native optional module)

### **Backend**

* Spring Boot 3.5.0 with WebFlux (Reactive, Pure Java)
* **JDK 25** (OpenJDK) - Strictly enforced
* **Gradle 9.2.1** (supports JDK 25)
* **Lombok edge-SNAPSHOT** (JDK 25 compatible)
* PostgreSQL 16 + Hibernate + R2DBC (Reactive)
* Redis 7.4 (Cache & Rate Limiting)
* RESTful Reactive API
* Swagger/OpenAPI 3.0 documentation
* JWT authentication with RS256 (Argon2id hashing – quantum-safe)
* Role-Based Access Control (RBAC)
* Phone number as unique identifier (E.164 format)

### **Infrastructure**

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
- **JDK 25** (OpenJDK) - MANDATORY
- **Docker** and **Docker Compose**
- **Gradle 9.2.1** (wrapper included - supports JDK 25)
- **Flutter 3.27.1** (for web/mobile development)

### Setup & Run

1. **Clone the repository**
```bash
git clone https://github.com/t3ratech/bantora.git
cd bantora
```

2. **Configure environment**
```bash
# Review and update .env file with your settings
# At minimum, configure:
# - Database credentials
# - JWT secret
# - SMS provider credentials (Twilio/Africa's Talking)
```

3. **Build and start all services**
```bash
./bantora-docker.sh -rrr bantora-database bantora-redis bantora-api bantora-web bantora-gateway
```

4. **Check service status**
```bash
./bantora-docker.sh --status
```

5. **Access the platform**
- Web UI: http://localhost:8080
- API: http://localhost:8081/api/v1
- Swagger UI: http://localhost:8081/swagger-ui.html
- Gateway: http://localhost:8083

### Development Workflow

```bash
# Rebuild a specific service
./bantora-docker.sh -rrr bantora-api

# View logs
./bantora-docker.sh --logs --tail 200 bantora-api

# Stop all services
./bantora-docker.sh --cleanup
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

Built by **Bantora Community**
Architect & Maintainer: *[Your Name]*

For collaboration: Open a GitHub issue or PR.

---
