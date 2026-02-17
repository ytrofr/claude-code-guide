# Project Registry

**Scope**: Universal -- Claude MUST know these
**Authority**: ALWAYS look here when ANY project is mentioned

---

## Project Map

Replace this table with your own projects:

| Project     | Repo            | Local Path    | Tech Stack        |
| ----------- | --------------- | ------------- | ----------------- |
| My Backend  | org/my-backend  | ~/my-backend  | Node.js, Express  |
| My Frontend | org/my-frontend | ~/my-frontend | React, TypeScript |
| My Mobile   | org/my-mobile   | ~/my-mobile   | React Native      |

---

## Port Registry (NEVER conflict)

| Port | Project     | Service           |
| ---- | ----------- | ----------------- |
| 3000 | My Frontend | Dev server (Vite) |
| 3001 | My Backend  | API server        |
| 5432 | Shared      | PostgreSQL        |
| 6379 | Shared      | Redis             |

---

## Quick Access

| When user says...             | Go to...      |
| ----------------------------- | ------------- |
| "backend", "api", "server"    | ~/my-backend  |
| "frontend", "ui", "dashboard" | ~/my-frontend |
| "mobile", "app"               | ~/my-mobile   |
