# AI Closet Agent Guide

This repository is for the Flutter frontend of an AI closet app.

The user flow:

1. User captures or imports a clothing photo.
2. Backend/Fashionpedia classifies and tags the garment.
3. User reviews and edits the AI metadata.
4. Item is saved into the closet.
5. User asks an LLM-powered assistant for outfit recommendations based on saved closet data.

## Current Responsibility

Frontend only. Assume other teammates own:

- Fashionpedia model and image classification.
- FastAPI backend.
- Database and storage.
- LLM API orchestration.

Frontend should still define clear API expectations and mock against them until backend endpoints are ready.

## Design System

Always follow `DESIGN.md` for UI work.

Use an Apple-inspired, image-first, quiet premium interface. Avoid clutter, heavy gradients, and marketing-page layouts.

## Expected Frontend Stack

- Flutter
- Dart
- Camera/gallery package
- API client layer for FastAPI
- Local mock data until backend is available
- State management chosen conservatively after the Flutter project is created

## Collaboration Rules

- Keep AI-generated classification editable.
- Keep API models typed.
- Do not hard-code backend URLs into widgets.
- Separate screens, domain models, service clients, and reusable UI components.
- Add mock repositories before backend integration is available.
- Verify UI on at least one compact mobile viewport before calling a screen complete.

## Useful Agent Workflows

Use these external skill systems as references or installed tools where available:

- gstack: planning, review, QA, and shipping workflow.
- Matt Pocock skills: PRD, issue breakdown, TDD, architecture critique, interface design.
- Superpowers: brainstorming, plans, TDD, systematic debugging, verification.

See `docs/skills.md` for installation status and usage notes.

