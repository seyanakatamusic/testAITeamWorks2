# testAITeamWorks2

勤務表管理SaaS（Attendance/Shift Management SaaS）

## Overview
This repository is being built end-to-end by an autonomous multi-agent development pipeline
(auto-team-dev). See GitHub Issues / Projects for the task backlog and progress.

## Stack (planned)
- Frontend: Next.js + TypeScript (tests: Vitest)
- Backend: Python + FastAPI (tests: pytest)
- Infra: Terraform (AWS EKS)

## Branching
- `main`: stable, release-tagged
- `develop`: integration branch, auto-deployed to the develop environment on merge
- `feature/*`: per-issue feature branches
