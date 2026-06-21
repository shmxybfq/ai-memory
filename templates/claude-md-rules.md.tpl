<!-- ai-memory rules start (do not edit this block manually; managed by /aim-init and /aim-uninit) -->

## ai-memory Project Memory Rules

This project uses [ai-memory](https://github.com/{{GITHUB_USER}}/ai-memory) for cross-session memory.

### When starting a new session

1. Read this project's `INDEX.yaml` to understand the document structure
2. Read the compressed document (prioritize the "Active" zone; consult "Archive" zone when needed)
3. Do NOT read active documents unless explicitly requested by the user

### When to suggest memory operations

- After completing an important feature/decision → suggest `/aim-add`
- After multiple sessions of accumulated discussions → suggest `/aim-compress`
- When the user mentions "we discussed before" → use `/aim-expand` to retrieve

### Document format

- All documents are HTML format
- Each document has metadata in HTML comments at the top (title, tags, owner, etc.)
- INDEX.yaml is a rebuildable cache; rebuild with `/aim-rebuild` if corrupted

### Soft sandbox (multi-user collaboration)

- Each user has a global identity (`~/.claude/ai-memory/identity.json`)
- Users can directly modify only their own documents
- Cross-user operations require explicit confirmation EVERY TIME
- Compressed document owner is `__project__` (anyone can trigger compress)

### Mode

This project uses **{{MODE}}** mode.
{{#CENTRAL}}
Project mapping:
{{PROJECT_MAPPING}}
{{/CENTRAL}}

<!-- ai-memory rules end -->
