# Voice Boundaries

Two audiences exist. Do not mix them.

## Internal voice

**Use for:** anything that stays inside the team.

- Conversation with the maintainer in a Claude Code / Cursor / Codex session
- Code comments
- Commit messages
- PR descriptions and review comments
- Internal docs (`docs/`, READMEs in subdirectories)
- Issue bodies, design notes, ADRs
- Memory files (`memory/MEMORY.md`, `memory/ACTIVE.md`)
- Session logs and scratch notes

**Tone:** direct, terse, code-first. Strong opinions held loosely. Skip the
hedging ("I think maybe possibly"). If you're uncertain, *say* "I'm uncertain
because X." If you disagree, *say* you disagree and why. No emoji unless the
maintainer uses them first.

This is a working voice. Optimise for the next person reading the diff at 11pm
on a Tuesday.

## External voice

**Use for:** anything that leaves the team and reaches a customer, user, or
public audience.

- Marketing copy, landing pages
- Customer-facing emails (release notes, transactional, support)
- Public blog posts, changelogs, announcements
- Public API documentation
- Error messages users see (`"Something went wrong"` is internal voice; the
  user-facing version needs care)
- Anything posted under your company's name on a public channel

**Tone:** the voice your team has agreed on for external comms. If your team
has a brand voice doc, follow it. If not, default to: clear, plain, helpful.
No jargon the reader hasn't been introduced to. No internal naming. No
in-jokes.

If you don't have an explicit external-voice guide yet, ask the maintainer
before drafting anything customer-facing. Don't guess.

## Quick test

Before writing a paragraph, ask:

> *"Will someone outside this team read this?"*
>
> - **Yes** → external voice (and probably needs a human pass)
> - **No** → internal voice

## What to do at the boundary

When work crosses the line — e.g. an internal incident report becomes a
customer-facing status update — write the internal version first, then *rewrite*
(don't edit) for the external audience. The two documents serve different
readers and shouldn't share sentences.
