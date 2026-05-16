# Public Website

Default model: `sonnet` — when dispatched as a subagent, use `model: "sonnet"` unless the user specifies otherwise.

Default directory: `docs/site/`

A public-facing documentation website for end users, deployed to GitHub Pages. This is the polished, structured documentation that users see when they visit your project's docs site.

The fundamental principle: the site is for end users, not contributors or developers. Consider who the end user of the project is and what they would actually want to know. If the target demographic is not tech-savvy, focus more on guides, tutorials and explanations. If the audience is technical developers, put more emphasis on the details.

## Generator selection

Offer the user 3 options. If they have no preference, default to Astro Starlight.

| Generator           | When to recommend                               | Why                                                                                         |
| ------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **Astro Starlight** | Default choice. Best for standalone docs sites. | Built-in search, i18n, sidebar generation, accessibility, excellent defaults out of the box |
| **VitePress**       | Project already uses the Vite or Vue ecosystem  | Vue component support in markdown, fast HMR, familiar config for Vue developers             |
| **Docusaurus**      | Project already uses the React ecosystem        | MDX support, rich plugin ecosystem, versioned documentation, React component embedding      |

After the user selects a generator, web search for the latest version, scaffolding command, and current best practices. Generator ecosystems move fast — don't rely on cached knowledge.

## Create flow

1. **Select generator.** Present the table above. Ask the user which they prefer.

2. **Scaffold the site.** Web search for the chosen generator's current scaffolding command and run it inside `docs/site/`. Examples:
   - Starlight: `npm create astro@latest -- --template starlight`
   - VitePress: `npx vitepress init`
   - Docusaurus: `npx create-docusaurus@latest`

3. **Search for relevant plugins.** Web search for plugins and integrations that match what the project does. Evaluate and suggest based on what you find in the codebase:
   - HTTP API present (e.g., Express, Fastify, Hono routes)? Look for an OpenAPI/Swagger docs plugin.
   - CLI tool present (e.g., `bin/` scripts, commander/yargs config)? Look for auto-generated CLI reference plugins.
   - TypeScript library? Look for TypeDoc or API extractor integrations.
   - Component library? Look for live playground or Storybook embed plugins.
   - Present options to the user. Only install the ones they approve.

   **Example plugins by generator** (web search for the latest versions before installing):

   <details>
   <summary>Astro Starlight</summary>

   | Plugin                     | What it does                                                  |
   | -------------------------- | ------------------------------------------------------------- |
   | `starlight-openapi`        | Generates API reference pages from OpenAPI/Swagger specs      |
   | `starlight-typedoc`        | Generates pages from TypeScript source using TypeDoc          |
   | `starlight-sidebar-topics` | Splits docs into separate sections, each with its own sidebar |
   | `@astrojs/sitemap`         | Generates a sitemap for SEO                                   |
   | `starlight-llms-txt`       | Adds an `llms.txt` file for AI agent consumption              |
   | `starlight-giscus`         | Adds Giscus comment threads to doc pages                      |
   | `starlight-videos`         | Embeds video guides and courses alongside docs                |

   </details>

   <details>
   <summary>VitePress</summary>

   | Plugin                                                | What it does                                                             |
   | ----------------------------------------------------- | ------------------------------------------------------------------------ |
   | `vitepress-openapi`                                   | Generates API docs from OpenAPI specs with an interactive theme          |
   | `typedoc-plugin-markdown` + `typedoc-vitepress-theme` | Generates TypeScript API docs as VitePress-compatible Markdown           |
   | `vitepress-sidebar`                                   | Auto-generates sidebar config from file structure                        |
   | `vitepress-plugin-mermaid`                            | Renders interactive, zoomable Mermaid diagrams                           |
   | `vitepress-plugin-llms`                               | Generates `llms.txt` for AI-friendly docs (used by Vite, Vue.js, Vitest) |
   | `@nolebase/vitepress-plugin-enhanced-readabilities`   | Inline link previews, heading highlights, SEO meta generation            |
   | `vitepress-i18n`                                      | Simplifies translation of default theme text and search                  |

   </details>

   <details>
   <summary>Docusaurus</summary>

   | Plugin                                                             | What it does                                                                       |
   | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
   | `docusaurus-plugin-openapi-docs` + `docusaurus-theme-openapi-docs` | Generates API reference from OpenAPI/Swagger specs with interactive try-it console |
   | `docusaurus-plugin-typedoc-api`                                    | Generates TypeScript API pages from source using TypeDoc                           |
   | `docusaurus-search-local`                                          | Offline/local search without external services                                     |
   | `@markprompt/docusaurus-theme-search`                              | AI-powered docs search                                                             |
   | `docusaurus-plugin-sass`                                           | SCSS/Sass support for custom styling                                               |
   | `@docusaurus/plugin-ideal-image`                                   | Optimised responsive images with lazy loading                                      |
   | `docusaurus-plugin-auto-sidebars`                                  | Auto-generates sidebar from file structure                                         |

   </details>

4. **Propose page structure.** Scan the project (README, reference docs, source code) and propose a set of pages and sections. Start from these common sections and adapt to the project and chosen plugins:
   - Getting Started / Quick Start
   - Installation
   - Core Concepts / Features
   - Usage Guides (one per major feature)
   - API Reference (if applicable)
   - Configuration
   - FAQ
   - Contributing

5. **Refine with the user.** Present the proposed page list. Ask what to add, remove, or restructure. Don't generate content until the structure is approved.

6. **Generate initial content.** Pull from existing sources:
   - README for the getting started / overview pages
   - Reference docs (if they exist) for deeper guides
   - Code comments and docstrings for API reference pages
   - Don't fabricate information. If the source material doesn't exist for a page, write a skeleton with TODOs and tell the user what's missing.

7. **Create the GitHub Actions deployment workflow.** Generate `.github/workflows/site.yml` (or update it if one already exists):

   The workflow should:
   - Trigger on pushes to main that touch `docs/site/**`
   - Install dependencies and build the site using the generator's build command
   - Deploy to GitHub Pages using `actions/deploy-pages`
   - Use `actions/upload-pages-artifact` to bundle the build output

   Key details:
   - Set `permissions: pages: write, contents: read`
   - Use environment `github-pages` with the pages URL
   - The build output directory varies by generator (Starlight: `dist/`, VitePress: `.vitepress/dist/`, Docusaurus: `build/`)

8. **Configure GitHub Pages.** If the `gh` CLI is available and authenticated:
   - Enable Pages in repo settings: `gh api repos/{owner}/{repo}/pages -X POST -f source.branch=main -f build_type=workflow`
   - Verify the site URL and report it to the user
   - If `gh` is not available, tell the user what manual steps they need to take in the GitHub repo settings (Settings > Pages > Source > GitHub Actions)

## Update flow

Important: if you're searching or reading documents, it's much faster to do it in parallel.

1. **Read current site structure.** Check the sidebar configuration file and page listing to understand what currently exists.
   - Starlight: `astro.config.mjs` sidebar config
   - VitePress: `.vitepress/config.ts` sidebar config
   - Docusaurus: `sidebars.js`

2. **Compare against project state.** Identify:
   - New features or modules that need documentation pages
   - Existing pages with content that no longer matches the codebase
   - Broken internal links between pages
   - Missing sections on existing pages (e.g., a new CLI command not listed in the CLI reference)
   - Outdated code examples or screenshots

3. **Update existing pages.** Fix stale content, update examples, correct broken links.

4. **Propose new pages.** If significant new features exist without docs, propose new pages to the user. Don't create them without asking.

5. **Check for ecosystem plugins.** Web search for new plugins or integrations that would benefit the site given recent project changes:
   - New HTTP API added? Suggest an OpenAPI docs plugin if one wasn't installed at creation time.
   - New i18n support? Suggest the generator's i18n plugin.
   - Growing FAQ? Suggest a search plugin if one isn't configured.

6. **Update navigation.** If pages were added or removed, update the sidebar/navigation configuration.

7. **Check the deployment workflow.** Verify the GitHub Actions workflow is current:
   - Are action versions up to date?
   - Does the build command still match the generator's current CLI?
   - Is the output directory still correct?

## Principles

- **If a site already exists, use it.** Even if it uses a generator not in the recommended list (Hugo, MkDocs, Sphinx, etc.), work with what's there. Don't suggest migration unless the user asks.
- **The site must be deployable from a clean checkout.** No local-only dependencies, no manual build steps that aren't in the workflow.
- **Respect existing design choices.** Don't change themes, colors, or branding unless asked. The user chose those intentionally.
- **Write for end users, not contributors.** Site content explains how to use the project. Contributor docs belong in references.
- **Don't fabricate.** If you don't have source material for a page, write a clear skeleton and tell the user what content is needed. A page with honest TODOs is better than a page with invented information.
