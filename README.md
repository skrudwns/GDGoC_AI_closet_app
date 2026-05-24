# GDGoC AI Closet App

AI Closet is a team project for a mobile wardrobe assistant.

The app flow:

1. The user captures or imports a clothing photo.
2. The AI pipeline classifies and tags the item.
3. The frontend lets the user review and edit the AI result.
4. The item is saved to the closet.
5. The user asks an LLM-powered assistant for outfit recommendations.

## Repository Layout

```text
.
├─ frontend/
│  └─ ai_closet_app/      # Flutter app
├─ backend/               # FastAPI backend workspace
├─ ai/                    # Fashionpedia / AI model workspace
├─ docs/                  # Shared contracts and team docs
├─ DESIGN.md              # Frontend design system
└─ AGENTS.md              # Agent collaboration guide
```

## Frontend

```bash
cd frontend/ai_closet_app
flutter run -d chrome
```

Useful checks:

```bash
cd frontend/ai_closet_app
flutter analyze
flutter test
flutter build web
```

## Backend

Backend code should live in `backend/`.

Expected stack:

- FastAPI
- database/storage integration
- item upload and classification API
- closet item CRUD
- LLM assistant endpoint

See `docs/integration-contract.md` before changing API shapes.

## AI

AI code should live in `ai/`.

Expected scope:

- Fashionpedia model integration
- image classification and tagging
- confidence handling
- model scripts and notebooks

Do not commit large datasets, checkpoints, or generated model artifacts to Git.

## Team Workflow

Use feature branches and pull requests. See `docs/team-workflow.md`.

