# Backend Workspace

This folder is reserved for the FastAPI backend.

Suggested structure:

```text
backend/
├─ app/
│  ├─ main.py
│  ├─ api/
│  ├─ core/
│  ├─ models/
│  ├─ schemas/
│  └─ services/
├─ tests/
├─ requirements.txt
└─ README.md
```

Backend responsibilities:

- image upload endpoint
- Fashionpedia classification orchestration
- closet item CRUD
- database and storage integration
- LLM assistant endpoint

Keep API contracts synchronized with `docs/integration-contract.md`.

