# Go — Coding Standards

> Illustrative example. Replace with your team's actual Go conventions.
> Loaded on demand when the agent is writing or modifying Go code.

## Project layout

Standard layout, lightly opinionated:

```
cmd/<binary>/main.go        # Entry points, one per binary
internal/handlers/          # HTTP handlers (transport layer)
internal/services/          # Business logic (no DB or HTTP imports here)
internal/repos/             # DB access, one repo per aggregate
internal/models/            # Domain types, no behaviour
pkg/                        # Importable by external code (use sparingly)
migrations/                 # Timestamped SQL migrations
```

Anything outside `internal/` is part of your public API. Be deliberate about
what goes in `pkg/`.

## Error handling

- Errors propagate. Wrap with context at the layer that has it:
  ```go
  return fmt.Errorf("fetching user %d: %w", id, err)
  ```
- Sentinel errors with `errors.Is` / `errors.As`. Don't string-compare error
  messages
- No `panic` in production paths. Reserve panics for impossible states
  (`panic("unreachable")`) or init-time configuration errors
- Log at the boundary (HTTP handler, CLI entry point), not at every layer

## Testing

- Table-driven tests for anything with branches:
  ```go
  tests := []struct{
      name string
      in   int
      want int
  }{
      {"zero", 0, 0},
      {"positive", 1, 1},
  }
  for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) { ... })
  }
  ```
- Test names describe behaviour: `Test_returns_403_when_user_is_not_owner`,
  not `TestUpdate`
- Use `t.Helper()` in test helpers
- Mock at boundaries (HTTP, DB, external APIs). Don't mock your own packages

## Naming

- Receiver names are 1–2 letters and consistent across methods
  (`func (s *Service) ...`, never mixing `s` and `service`)
- Acronyms are uppercase: `userID`, `httpClient`, not `userId` or `httpclient`
- Interfaces named for behaviour, not implementation: `Reader`, not `IReader`
  or `ReaderInterface`

## Concurrency

- Don't start a goroutine without knowing how it ends. Every `go ...` needs
  a clear lifecycle (context cancellation, channel close, `sync.WaitGroup`)
- Pass `context.Context` as the first parameter on functions that do I/O.
  Honour cancellation
- Locks: hold the smallest scope possible. Prefer channels for ownership
  transfer over locks for shared state

## Dependencies

- Stdlib first. Add a dep only when the stdlib version would be substantially
  worse
- Pin major versions. Trust `go.sum`; check it into git
