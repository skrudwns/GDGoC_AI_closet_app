# Team Workflow

## Ownership

- `frontend/`: Flutter frontend.
- `backend/`: FastAPI backend.
- `ai/`: Fashionpedia and AI model work.
- `docs/`: shared contracts, plans, and team decisions.

Each team can work mostly inside its own folder. Shared changes should go through docs first.

## Branch Strategy

Use `main` as the stable branch.

Do not commit directly to `main` during team development. Create feature branches:

```text
frontend/<feature-name>
backend/<feature-name>
ai/<feature-name>
docs/<topic-name>
codex/<task-name>
```

Examples:

```text
frontend/closet-filter-ui
backend/item-upload-api
ai/fashionpedia-tagging
docs/api-contract-v1
codex/monorepo-structure
```

## Pull Request Rules

Before opening or merging a PR:

1. Pull the latest `main`.
2. Keep changes focused on one area.
3. Update `docs/integration-contract.md` before changing request or response shapes.
4. Run relevant checks.
5. Ask the affected owner to review.

## Local Sync

```bash
git switch main
git pull origin main
git switch -c frontend/example-feature
```

When work is ready:

```bash
git status
git add .
git commit -m "Describe the change"
git push -u origin frontend/example-feature
```

Then open a pull request on GitHub.

## Frontend Checks

```bash
cd frontend/ai_closet_app
flutter analyze
flutter test
flutter build web
```

## API Contract Rule

Frontend, backend, and AI should treat `docs/integration-contract.md` as the shared agreement.

If an endpoint changes, update the contract first or in the same PR.

