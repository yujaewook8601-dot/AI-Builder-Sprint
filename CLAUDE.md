# CLAUDE.md
# AI Builder Sprint 2026 - 용사의 여정 (Pixel Hero)

이 문서는 본 프로젝트에 참여하는 AI 코딩 에이전트(Claude, Gemini, Google Antigravity, ChatGPT 등)를 위한 개발 가이드입니다.

---

# Project Overview

- Project: 용사의 여정 (Pixel Hero)
- Platform: Flutter
- State Management: Provider
- Language: Dart
- Architecture: 중앙 GameState 기반
- AI Model: Upstage Solar API

---

# Core Principles

## 1. 기존 코드 우선

기존 구조를 최대한 유지한다.

이미 존재하는 아키텍처를 변경하지 않는다.

동일 기능을 중복 구현하지 않는다.

추측해서 코드를 작성하지 않는다.

필요한 파일을 먼저 확인한 뒤 수정한다.

---

## 2. Architecture

### GameState

모든 게임 상태는

lib/providers/game_state.dart

를 기준으로 관리한다.

새로운 상태를 여러 곳에 분산시키지 않는다.

---

### AI

LLM 관련 기능은

lib/services/

안에서만 관리한다.

특히

- llm_fitness_config.dart
- solar_api_service.dart

를 중심으로 수정한다.

---

### UI

UI는 픽셀 아트 스타일을 유지한다.

Material 기본 스타일을 무분별하게 사용하지 않는다.

반응형은 MediaQuery 기반으로 구현한다.

---

# AI Prompt Rules

Fitness System Prompt는 다음 규칙을 절대 훼손하지 않는다.

- Injection Guard
- Strict Formatter
- JSON Output Format

LLM은 판단만 수행한다.

계산은 반드시 Flutter 코드에서 수행한다.

AI는 운동량을 계산하지 않는다.

---

# Fitness System

사용자의 자연어에서

- 운동 종류
- 횟수
- 거리
- 시간
- 컨디션

만 추출한다.

실제 경험치 계산은 Flutter에서 수행한다.

---

# Coding Rules

새로운 패키지는 꼭 필요한 경우에만 추가한다.

기존 Provider 구조를 유지한다.

Null Safety를 준수한다.

불필요한 리팩터링은 하지 않는다.

기존 변수명을 임의로 변경하지 않는다.

---

# UI / UX Rules

Pixel RPG 분위기를 유지한다.

애니메이션은 기존 스타일을 따른다.

Dialog는 PopScope를 고려한다.

Navigation 흐름을 깨지 않는다.

---

# Debugging Rules

에러를 수정할 때는

- 원인 분석
- 영향 범위
- 해결 방법

순서대로 접근한다.

임시 해결책보다 근본 원인을 우선 해결한다.

---

# Performance

불필요한 rebuild를 피한다.

setState보다 Provider를 우선 사용한다.

비동기 호출은 await 및 예외 처리를 포함한다.

---

# AI Collaboration

이 프로젝트는 Claude, Gemini, Google Antigravity, ChatGPT를 함께 활용하여 개발되었다.

AI는 다음 역할을 수행하였다.

- 코드 생성
- 코드 리뷰
- 버그 수정
- 아키텍처 설계
- UI/UX 개선
- 프롬프트 엔지니어링
- 리팩터링

모든 AI는 기존 프로젝트 구조를 최대한 존중하며 협업하도록 한다.
