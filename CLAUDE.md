# CLAUDE.md - AI Agent Guidelines for graphql-flutter

This file provides guidelines for AI agents (Claude, Copilot, etc.) contributing to this repository.

## Critical: Commit Style

**Following the commit style is mandatory for PRs to be reviewed.** The commit format is used to generate changelogs and triggers the internal review bot.

### Commit Message Format

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

- **Header is mandatory**, scope is optional
- **No line longer than 100 characters**
- Footer should reference issues if applicable (e.g., `Closes #123`)

### Types (required)

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `deprecate` | Deprecate a feature (starts 3-release or 1-major removal process) |
| `remove` | End of life for a feature |
| `docs` | Documentation only changes |

### Scopes (required for code changes)

| Scope | Description |
|-------|-------------|
| `graphql` | Changes to the `packages/graphql` package |
| `graphql_flutter` | Changes to the `packages/graphql_flutter` package |

### Subject Rules

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No dot (.) at the end

### Examples

```
feat(graphql): add request cancellation support
```

```
fix(graphql_flutter): resolve widget rebuild issue on query refetch

The widget was rebuilding unnecessarily when refetch was called due to
missing equality check in the QueryResult comparison.

Closes #456
```

```
docs(changelog): update changelog to beta.5
```

## Code Style

- All features or bug fixes **must be tested** with unit tests
- All public API methods **must be documented**
- Follow [Effective Dart: Style Guidelines](https://dart.dev/guides/language/effective-dart/style)

## Code Practices

### Use `FIXME` Comments

Use `/* FIXME: */` for:
1. Optimizations that aren't clearly worthwhile yet
2. Ugly corner cases that could be improved later

### Keep It Simple

- Don't overdesign - complexity is a killer
- Start with simple solutions before adding complexity
- Unused code is buggy code

### Keep Patches Reviewable

- Make a single logical change per commit
- Avoid drive-by fixes - use `/* FIXME: */` and move on
- Each commit should be independently reviewable

## Project Structure

This is a monorepo managed with Melos:
- `packages/graphql/` - Core GraphQL client
- `packages/graphql_flutter/` - Flutter widgets and integration
- `examples/` - Example applications

## Testing

Run all tests:
```bash
make check
```

Or for specific packages:
```bash
make ci_check_client      # Test graphql package
make ci_check_flutter     # Test graphql_flutter package
```

## Reference

For full contribution guidelines, see:
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [MAINTAINERS.md](docs/dev/MAINTAINERS.md)
