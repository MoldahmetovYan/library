# BookHub Backend

Spring Boot backend for BookHub with:
- JWT auth and role-based access (`ROLE_USER`, `ROLE_ADMIN`)
- REST API
- GraphQL endpoint
- Realtime WebSocket endpoint
- PostgreSQL + JPA
- Docker and Docker Compose setup

## Run locally

1. Create `.env` from `.env.example`.
2. Start DB + app:

```bash
docker compose up --build
```

App: `http://localhost:8080`

## Key REST endpoints

### Auth
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/reset` (authenticated, requires `currentPassword` + `newPassword`)

### Books
- `GET /api/books`
- `GET /api/books/{id}`
- `GET /api/books/search?query=...`
- `GET /api/books/sorted?sortBy=title&page=0&size=10`
- `POST /api/books` (admin)
- `PUT /api/books/{id}` (admin)
- `DELETE /api/books/{id}` (admin)
- `POST /api/books/{id}/cover` (admin)
- `POST /api/books/{id}/pdf` (admin)

### User/Favorites/History/Reviews
- `GET /api/users/me`
- `POST /api/users/update`
- `DELETE /api/users/delete`
- `GET /api/favorites`
- `POST /api/favorites?bookId=...`
- `DELETE /api/favorites?bookId=...`
- `GET /api/history`
- `GET /api/reviews/{bookId}`
- `POST /api/reviews/{bookId}`
- `PUT /api/reviews/{bookId}`
- `DELETE /api/reviews/{bookId}`

### Admin
- `GET /api/admin/stats`
- `GET /api/admin/stats/extended`

## GraphQL

Endpoint: `POST /graphql`

Query example:

```graphql
query {
  books {
    id
    title
    author
  }
}
```

Mutation example (admin only):

```graphql
mutation {
  addBook(input: { title: "GraphQL Book", author: "Admin" }) {
    id
    title
  }
}
```

## WebSocket

Endpoint: `ws://localhost:8080/ws/realtime`

Behavior:
- on connect: `connected:<timestamp>`
- send `ping` -> receive `pong:<timestamp>`
- send any text -> receive `echo:<text>`

## Tests

Run backend tests:

```bash
./mvnw test
```

Run Flutter tests from project root:

```bash
flutter test
```
