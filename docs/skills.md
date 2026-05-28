# Skill Systems

This project intends to use three external skill/workflow systems.

## gstack

Repository: https://github.com/garrytan/gstack

Status:

- Repository cloned to `~/.codex/skills/gstack`.
- Setup was attempted with `./setup --host codex`.
- Setup is blocked because `bun` is not installed.

Use for:

- Product framing with office-hours style thinking.
- Planning review.
- Engineering review.
- Design review.
- Browser QA.
- Release discipline.

Next action:

1. Install Bun.
2. Run `~/.codex/skills/gstack/setup --host codex`.
3. Restart Codex if new skills are not picked up automatically.

## Matt Pocock Skills

Repository: https://github.com/mattpocock/skills

Status:

- Installed to Codex skills:
  - `to-prd`
  - `tdd`
  - `diagnose`
  - `improve-codebase-architecture`
  - `setup-matt-pocock-skills`
  - `grill-me`

Useful skills for this project:

- `to-prd`: turn rough product ideas into PRDs.
- `write-a-prd`: write detailed product requirements.
- `prd-to-plan`: convert PRDs into implementation plans.
- `prd-to-issues`: turn PRDs into issues.
- `design-an-interface`: plan UI screens and component behavior.
- `tdd`: drive implementation with tests.
- `diagnose`: investigate bugs.
- `improve-codebase-architecture`: critique architecture.
- `grill-me`: challenge weak assumptions.

Because this repo is currently frontend-first, start with:

1. `to-prd`
2. `grill-me`
3. `improve-codebase-architecture`
4. `tdd`

## Superpowers

Repository: https://github.com/obra/superpowers

Status:

- Installed to Codex skills:
  - `using-superpowers`
  - `brainstorming`
  - `writing-plans`
  - `executing-plans`
  - `test-driven-development`
  - `systematic-debugging`
  - `verification-before-completion`
  - `requesting-code-review`

Use for:

- Brainstorming before creative feature work.
- Writing implementation plans.
- TDD for features and bug fixes.
- Systematic debugging.
- Verification before completion.
- Requesting code review before merging.

Codex App note:

The Superpowers README says Codex App users can install it through the Codex plugin marketplace. In this environment, the installable plugin list did not show Superpowers, so the core repository skills were installed manually.

## Recommended Team Workflow

For every meaningful feature:

1. Write or update a short PRD in `docs/`.
2. Confirm UI direction against `DESIGN.md`.
3. Make a frontend implementation plan.
4. Build against mock API data first.
5. Connect FastAPI endpoints when backend is ready.
6. Run review and QA before merging.
