# TypeScript / React — Coding Standards

> Illustrative example. Replace with your team's actual TS/React conventions.
> Loaded on demand when the agent is writing or modifying TypeScript or React.

## TypeScript

### Types

- No `any`. If you need it, use `unknown` and narrow. The lint config should
  enforce this — if it doesn't, it's a rule violation, not a style choice
- Prefer `type` for unions and primitives, `interface` for object shapes that
  may be extended
- Discriminated unions for state:
  ```ts
  type RequestState =
    | { status: "idle" }
    | { status: "loading" }
    | { status: "success"; data: User }
    | { status: "error"; error: Error };
  ```
- Branded types for IDs that should not be confused:
  ```ts
  type UserID = string & { readonly __brand: "UserID" };
  ```

### Imports

- Absolute imports from a configured root (`@/components/Button`), not
  `../../../../components/Button`
- One import block per source: stdlib / external / internal, separated by a
  blank line
- No barrel files at the top of large directories — they break tree-shaking
  and slow up cold-start in dev

### Async

- `async/await` over `.then()` chains
- One `try/catch` per logical operation. Don't wrap entire functions in a
  catch-all that loses the failure point
- Never swallow an error silently. At minimum, `console.error` it; ideally,
  surface it via your error boundary / logging pipeline

## React

### Components

- Function components only. No class components in new code
- One component per file, named export. Filename matches component name
  (`UserCard.tsx` exports `UserCard`)
- Props are typed inline or via a `Props` interface above the component:
  ```tsx
  interface Props {
    user: User;
    onEdit?: (id: UserID) => void;
  }
  export function UserCard({ user, onEdit }: Props) { ... }
  ```

### State & data

- Server state lives in TanStack Query / SWR / equivalent. Don't mirror
  server data into `useState`
- Form state lives in a form library (React Hook Form, Formik, etc.). Don't
  hand-roll for anything beyond a single input
- Lift state only as far as it needs to go. Component-local state is fine

### Hooks

- Hook order matters. Don't put a hook inside a conditional
- Custom hooks named `useX`, return either a tuple or an object — be
  consistent within a hook
- Effects are a last resort. If you can derive instead of effect, derive.
  If you can event-handler instead of effect, event-handler

### Styling

- Pick one styling system and stick with it (Tailwind, CSS modules, styled-components).
  Don't mix
- No inline styles except for genuinely dynamic values (computed widths,
  user-provided colours)
- Component variants via a `cva` / `clsx` pattern, not a wall of conditionals
