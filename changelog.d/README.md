# Changelog fragments

Do not edit `CHANGELOG.md` by hand. Write each change that a user can see as one fragment in this folder, in the same commit as the change.

- Name a fragment `<yyyymmdd-hhmmss>-<subject>.md`.
- Line 1 is `type: <type>`. The type is one of `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed` or `Security`.
- Line 2 is empty.
- Then write the text of one entry. Start it with a short bold summary. Then say what changed for the user, not how the code changed.

Example:

```markdown
type: Added

**Rex on every machine.** The rex client is installed on each host.
```

A release moves the fragments into a new section of `CHANGELOG.md` and deletes them. If a change has no effect that a user can see, write no fragment.
