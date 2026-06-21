# INDEX.yaml — managed by ai-memory
# This file is a rebuildable cache, not the source of truth.
# Run /aim-rebuild to regenerate from filesystem if corrupted.

project: "{{PROJECT_NAME}}"
mode: "{{MODE}}"                          # central / distributed
root: "{{ROOT_PATH}}"
created: "{{CREATED_DATE}}"
updated: "{{UPDATED_DATE}}"
version: 1

# User identity (who initialized this project)
initialized_by:
  id: "{{USER_ID}}"
  name: "{{USER_NAME}}"

# Compressed document (single file, dual-zone)
compressed: []

# Active documents (not yet compressed)
active: []

# Snapshot directories (historical archives)
snapshots: []
