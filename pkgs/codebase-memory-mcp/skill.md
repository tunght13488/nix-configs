---
name: codebase-memory
description: Use the codebase knowledge graph for structural code queries.
Triggers on: explore the codebase, understand the architecture, what functions exist,
show me the structure, who calls this function, what does X call, trace the call chain,
find callers of, show dependencies, impact analysis, dead code, unused functions,
high fan-out, refactor candidates, code quality audit, graph query syntax,
Cypher query examples, edge types, how to use search_graph.
---

# Codebase Memory — Knowledge Graph Tools

codebase-memory-mcp indexes codebases into a persistent knowledge graph (158 languages,
hybrid LSP for 11 including PHP, TypeScript, Go, Java, Python, Rust, C#, C/C++, Kotlin).
Graph tools return precise structural results in ~500 tokens vs ~80K for grep/file-read loops.

## Code Discovery Protocol

ALWAYS prefer graph tools over grep/glob for code structure discovery.
Graph tools find functions, classes, routes, call chains, and cross-references in
milliseconds — grep and file search are for string literals, config values, and non-code files.

When entering an unfamiliar project, always index it first if not already indexed.
Graph queries only work on indexed projects.

## Quick Decision Matrix

| Question | Tool call |
|----------|----------|
| Who calls X? | `trace_path(function_name=X, direction=inbound)` |
| What does X call? | `trace_path(function_name=X, direction=outbound)` |
| Full call context | `trace_path(function_name=X, direction=both)` |
| Find by name pattern | `search_graph(name_pattern="...")` |
| Find by label | `search_graph(label="Class"/"Function"/"Route"/...)` |
| Dead code | `search_graph(max_degree=0, exclude_entry_points=true)` |
| Cross-service edges | `query_graph` with Cypher |
| Impact of local changes | `detect_changes()` |
| Risk-classified trace | `trace_path(risk_labels=true)` |
| Project overview | `get_architecture(aspects=["all"])` |
| Read symbol source | `get_code_snippet(qualified_name="pkg.FuncName")` |
| Text search (indexed) | `search_code(pattern="...")` |
| Graph schema | `get_graph_schema()` |
| Natural-language search | `semantic_query(query="...")` |

## Available Tools

All tools are invoked via the CLI:

```bash
codebase-memory-mcp cli <tool_name> '<json_args>'
```

Use `--raw` before the tool name to get raw JSON output (pipeable to `jq`):
```bash
codebase-memory-mcp cli --raw search_graph '{"label":"Function"}' | jq '.results[].name'
```

### Indexing
| Tool | Description |
|------|-------------|
| `index_repository` | Index a repository into the graph. Auto-sync keeps it fresh. |
| `index_status` | Check indexing status of a project. |
| `list_projects` | List all indexed projects with node/edge counts. |
| `delete_project` | Remove a project and all its graph data. |

### Querying
| Tool | Description |
|------|-------------|
| `search_graph` | Structured search by label, name pattern, file pattern, degree filters. Pagination via limit/offset. |
| `trace_path` | BFS traversal — who calls a function and what it calls (alias: `trace_call_path`). Depth 1-5. |
| `detect_changes` | Map git diff to affected symbols + blast radius with risk classification. |
| `query_graph` | Execute Cypher-like graph queries (read-only). |
| `get_graph_schema` | Node/edge counts, relationship patterns, property definitions per label. Run this first. |
| `get_code_snippet` | Read source code for a function by qualified name. |
| `get_architecture` | Codebase overview: languages, packages, routes, hotspots, clusters, ADR. |
| `search_code` | Grep-like text search within indexed project files. |
| `manage_adr` | CRUD for Architecture Decision Records. |
| `ingest_traces` | Ingest runtime traces to validate HTTP_CALLS edges. |

## Exploration Workflow (new project)

```
1. cbm cli index_repository '{"repo_path": "."}'         # index the current project
2. cbm cli get_architecture '{}'                          # overview
3. cbm cli get_graph_schema '{}'                          # node/edge types
4. cbm cli search_graph '{"name_pattern":".*","limit":5}' # peek at symbols
5. cbm cli search_graph '{"label":"Route"}'               # see HTTP routes
```

## Tracing Workflow (understanding connections)

```
1. cbm cli search_graph '{"name_pattern":".*Handler.*"}'        # discover exact name
2. cbm cli trace_path '{"function_name":"HandleRequest","direction":"both","depth":3}'
3. cbm cli detect_changes '{}'                                   # impact of uncommitted diff
```

## Quality Analysis

- Dead code: `cbm cli search_graph '{"max_degree":0,"exclude_entry_points":true,"label":"Function"}'`
- High fan-out: `cbm cli search_graph '{"min_degree":10,"relationship":"CALLS","direction":"outbound"}'`
- High fan-in: `cbm cli search_graph '{"min_degree":10,"relationship":"CALLS","direction":"inbound"}'`

## Graph Data Model

### Node Labels
`Project`, `Package`, `Folder`, `File`, `Module`, `Class`, `Function`, `Method`,
`Interface`, `Enum`, `Type`, `Route`, `Resource`

### Edge Types
`CONTAINS_PACKAGE`, `CONTAINS_FOLDER`, `CONTAINS_FILE`, `DEFINES`, `DEFINES_METHOD`,
`IMPORTS`, `CALLS`, `HTTP_CALLS`, `ASYNC_CALLS`, `IMPLEMENTS`, `HANDLES`,
`USAGE`, `CONFIGURES`, `WRITES`, `MEMBER_OF`, `TESTS`, `USES_TYPE`, `FILE_CHANGES_WITH`,
`SIMILAR_TO`, `SEMANTICALLY_RELATED`

## Cypher Examples (for query_graph)

```cypher
MATCH (f:Function)-[r:CALLS]->(g) WHERE f.name = 'main' RETURN g.name
MATCH (a)-[r:HTTP_CALLS]->(b) RETURN a.name, b.name, r.url_path, r.confidence LIMIT 20
MATCH (f:Function) WHERE f.name =~ '.*Handler.*' RETURN f.name, f.file_path
MATCH (f:Function) WHERE NOT EXISTS { (f)<-[:CALLS]-() } RETURN f.name LIMIT 10
MATCH (c:Class)-[:IMPLEMENTS]->(i:Interface) RETURN c.name, i.name
MATCH (p:Project)-->(n) RETURN n.label, count(*) as count ORDER BY count DESC
```

## Gotchas

1. `search_graph(relationship="HTTP_CALLS")` filters nodes by degree — use `query_graph` with Cypher to see actual edges.
2. `query_graph` has a 200-row cap — use `search_graph` with degree filters for counting.
3. `trace_path` needs exact function names — use `search_graph(name_pattern=...)` first.
4. Results default to 10 per page — check `has_more` in the response and use `offset` for pagination.
5. If a project is not indexed yet, run `index_repository` first.
6. Use Grep/Glob/Read freely for text, configs, non-code files — graph tools complement rather than replace them.
7. Qualified names for `get_code_snippet` follow `<project>.<path_parts>.<name>` format. Use `search_graph` to discover them.
