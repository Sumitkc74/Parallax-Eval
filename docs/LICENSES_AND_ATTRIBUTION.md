# Open-Source Licenses, Software Bill of Materials (SBOM) & Attributions

**Platform:** Parallax-Eval  
**Root License:** Apache License, Version 2.0  
**License Audit Status:** 100% Permissive Open-Source (MIT, Apache-2.0, BSD-3-Clause). Zero GPL/AGPL copyleft contamination.

---

## 1. Backend Dependencies & License Audit

All Python backend dependencies specified in `backend/requirements.txt` are licensed under permissive open-source licenses:

| Package | Version Range | License | Primary Purpose / Role |
| :--- | :--- | :--- | :--- |
| **fastapi** | `>=0.115.0` | **MIT** | High-performance asynchronous REST API framework |
| **uvicorn** | `>=0.30.0` | **BSD-3-Clause** | Lightning-fast ASGI web server implementation |
| **pydantic** | `>=2.10.0` | **MIT** | Data validation, bounds enforcement, and settings management |
| **pydantic-settings** | `>=2.6.0` | **MIT** | Environment variable management and configuration loading |
| **sqlalchemy** | `>=2.0.36` | **MIT** | Asynchronous ORM and relational database abstraction layer |
| **alembic** | `>=1.13.3` | **MIT** | Database schema migration management |
| **asyncpg** | `>=0.30.0` | **Apache-2.0** | High-performance asynchronous PostgreSQL database driver |
| **aiosqlite** | `>=0.20.0` | **MIT** | Asynchronous SQLite database driver for local development |
| **langgraph** | `>=0.2.40` | **MIT** | Multi-agent state machine and cyclic graph orchestration |
| **langchain-core** | `>=0.3.0` | **MIT** | Agent base abstractions and prompt templates |
| **httpx** | `>=0.28.0` | **BSD-3-Clause** | Next-generation asynchronous HTTP client for LLM gateways |
| **python-json-logger** | `>=3.0.0` | **BSD-2-Clause** | Structured JSON logging for production observability |
| **pytest** | `>=8.3.0` | **MIT** | Automated unit and integration testing framework |
| **pytest-asyncio** | `>=0.24.0` | **Apache-2.0** | Async testing fixtures and event loop management |
| **python-dotenv** | `>=1.0.1` | **BSD-3-Clause** | Loads environment variables from `.env` files |

---

## 2. Mobile Client Dependencies & License Audit

All Dart/Flutter dependencies specified in `mobile/pubspec.yaml` are licensed under permissive open-source licenses:

| Package | Version Range | License | Primary Purpose / Role |
| :--- | :--- | :--- | :--- |
| **flutter** | `SDK (3.7+)` | **BSD-3-Clause** | Cross-platform mobile/desktop UI toolkit (Google) |
| **cupertino_icons** | `^1.0.2` | **MIT** | Apple Cupertino style icons |
| **http** | `^0.13.5` | **BSD-3-Clause** | Composable asynchronous HTTP library |
| **provider** | `^6.0.5` | **MIT** | Reactive state management and dependency injection |
| **flutter_test** | `SDK` | **BSD-3-Clause** | Flutter unit and widget testing utilities |
| **flutter_lints** | `^2.0.0` | **BSD-3-Clause** | Recommended Dart analysis lint rules |

---

## 3. UI Assets, Fonts & Media Licensing Audit

A strict audit of all image, vector, and typography assets across the repository was conducted:

1. **Material Icons (`MaterialIcons-Regular.otf`)**:
   - **Copyright**: Google LLC.
   - **License**: Apache License, Version 2.0.
   - **Usage**: Standard Flutter Material Design icon glyphs. Permitted for distribution in open-source and commercial applications.
2. **Cupertino Icons (`CupertinoIcons.ttf`)**:
   - **Copyright**: Apple Inc. / Flutter Authors.
   - **License**: MIT License.
   - **Usage**: Standard iOS icon glyphs bundled with the `cupertino_icons` package.
3. **Application Icons & Favicons**:
   - All launcher icons in `mobile/android`, `mobile/ios`, and `mobile/web` are generated from standard geometric vector shapes or the official open-source Flutter default template.
   - **Proprietary Trademarks**: No copyrighted logos, registered corporate trademarks, or unlicensed photographic assets are stored in this codebase.

---

## 4. Required Attribution Notices

### FastAPI
```
Copyright (c) 2018 Sebastián Ramírez
Permission is hereby granted, free of charge, to any person obtaining a copy...
```

### SQLAlchemy
```
Copyright (c) 2005-2026 Michael Bayer and contributors.
SQLAlchemy is a trademark of Michael Bayer.
Distributed under the MIT License.
```

### LangGraph / LangChain
```
Copyright (c) 2023-2026 Harrison Chase and LangChain, Inc.
Distributed under the MIT License.
```

### Flutter & Dart SDK
```
Copyright 2014 The Flutter Authors. All rights reserved.
Redistribution and use in source and binary forms...
Distributed under the BSD 3-Clause License.
```

---

## 5. Copyleft & Licensing Conflict Verification

- **GPL / AGPL / LGPL Verification**: None of the backend or mobile dependencies require copyleft distribution or force source code disclosure beyond standard attribution.
- **Commercial & Research Compatibility**: The combination of Apache-2.0 and MIT/BSD dependencies allows Parallax-Eval to be integrated into institutional, educational, government, and enterprise evaluation pipelines without licensing friction.

