## Mi Academy brand

Before making any UI, branding, asset, theme, typography, or game-screen change, read these files in order:

1. docs/brand/BRAND_GUIDELINES.md
2. docs/brand/UI_IMPLEMENTATION_PLAN.md
3. docs/brand/mi-academy-brand-reference.png
4. Relevant package-level AGENTS.md files
5. Only the source files required for the current task

The image is a visual direction, not a pixel-perfect production asset.

Do not use real-child photography anywhere in the product.
Do not introduce a second mascot style.
Do not use emoji, random icon packs, or temporary placeholder graphics in production UI.
Do not scan the entire repository by default.

Start from the project mapping or repository index, locate the relevant feature, then inspect only:

- the app shell
- the design system
- shared game UI
- the requested game or screen
- directly related tests

Before implementation:

1. Audit the existing design system.
2. Identify reusable components.
3. Produce a concise implementation plan.
4. List files expected to change.
5. State unresolved asset dependencies.

During implementation:

- Extend shared tokens before adding local style constants.
- Reuse shared components.
- Keep Vietnamese and English localization working.
- Preserve tablet-first responsive behavior.
- Keep child touch targets at least 48 logical pixels.
- Add or update tests for changed behavior.
- Run formatter, analyzer, and relevant tests.

Do not claim completion when:

- placeholder assets remain
- localization is incomplete
- tests fail
- layouts overflow on supported device sizes
- the mascot is inconsistent
- production screens still use generic Material styling

For large visual changes, implement one reference screen first and wait for validation before propagating the system across all games.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
