# Testing Report

Last updated: 2026-02-20

## Automated tests

### Flutter (client)

Command:

```bash
flutter test
```

Result:
- Total: 15 tests
- Status: passed
- Covered areas: model parsing, JSON utilities, error mapping, basic widget smoke test

### Spring Boot (server)

Command:

```bash
cd BookHub
./mvnw test
```

Result:
- Total: 11 tests
- Status: passed
- Covered areas: API security integration, GraphQL integration, application context startup

## Manual checks

Performed scenarios:
- Registration and login
- Role checks for admin-only endpoints
- Book CRUD from admin UI
- Favorites/history flow for user role
- Docker Compose startup for app + PostgreSQL
- WebSocket demo page connection and incoming message display

## Notes and known gaps

- Cross-device mobile matrix (real iOS/Android hardware) is not fully automated yet.
- UI automation (integration tests with full navigation flows) should be added as a next step.
