# AI Changelog — AL Motos

Memória contínua do agente (ADR-005). Entradas em ordem inversa (mais recente primeiro).

## 2026-08-15 — Isolamento do orquestrador AI (MCP) e governança RFC 2119

- **Arquivos modificados:** `CLAUDE.md`, `docs/ai/CHANGELOG.md`
- **Por que:** A inteligência do produto foi isolada em `almotos-ai` (MCP Server em Node.js/TypeScript) como Anti-Corruption Layer, para que catálogo e WhatsApp sejam thin clients e o Kotlin permaneça o único System of Record. O `CLAUDE.md` passou a ser o documento canônico de guardrails, com palavras-chave RFC 2119, para impedir que agentes violem persistência, PII ou lógica de LLM fora do orquestrador.
