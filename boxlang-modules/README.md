# BoxLang Modules Skills

Skills for working with official BoxLang modules. Each module has its own subdirectory containing one or more topic-focused `SKILL.md` files.

## Modules

| Module | Description | Skills |
|--------|-------------|--------|
| [bx-ai](./bx-ai/) | BoxLang AI — multi-provider AI, agents, RAG, memory, pipelines | 6 skills |
| [bx-orm](./bx-orm/) | BoxLang ORM — Hibernate-backed Object-Relational Mapping | 5 skills |
| [bx-ftp](./bx-ftp/) | FTP/SFTP/FTPS file transfer with `bx:ftp` component | 1 skill |
| [bx-jdbc](./bx-jdbc/) | JDBC driver modules — MySQL, PostgreSQL, MSSQL, Oracle, SQLite, Derby, etc. | 1 skill |
| [bx-markdown](./bx-markdown/) | Markdown-to-HTML and HTML-to-Markdown conversion BIFs | 1 skill |
| [bx-yaml](./bx-yaml/) | YAML serialization/deserialization with `yamlSerialize()` and `yamlDeserialize()` | 1 skill |
| [bx-jsoup](./bx-jsoup/) | HTML parsing, CSS selector scraping, and HTML sanitization via jsoup | 1 skill |
| [bx-jython](./bx-jython/) | Execute Python 2.7 code from BoxLang with `jythonEval()` and `bx:jython` | 1 skill |
| [bx-ini](./bx-ini/) | Read and write INI configuration files via BIFs and fluent `IniFile` object | 1 skill |
| [bx-oshi](./bx-oshi/) | Hardware and system info — CPU, memory, disk usage via OSHI library | 1 skill |
| [bx-unsafe-evaluate](./bx-unsafe-evaluate/) | Dynamic code evaluation with `evaluate()` — for legacy migration only | 1 skill |
| [bx-mail](./bx-mail/) | Send email with `bx:mail`, attachments, multipart HTML+text, S/MIME signing | 1 skill |
| [bx-pdf](./bx-pdf/) | PDF generation with `bx:document`, headers/footers, sections, encryption | 1 skill |
| [bx-csrf](./bx-csrf/) | CSRF protection — `CSRFGenerateToken()`, `CSRFVerifyToken()`, `CSRFHiddenField()` | 1 skill |
| [bx-esapi](./bx-esapi/) | OWASP ESAPI encoding (HTML, JS, URL, SQL, LDAP) and HTML sanitization | 1 skill |
| [bx-password-encrypt](./bx-password-encrypt/) | Secure password hashing — BCrypt, Argon2, SCrypt, PBKDF2 | 1 skill |
| [bx-image](./bx-image/) | Image manipulation — resize, crop, rotate, filters, fluent builder, watermarks | 1 skill |
| [bx-rss](./bx-rss/) | Parse and create RSS 2.0, Atom, and iTunes podcast feeds | 1 skill |
| [bx-web-support](./bx-web-support/) | Mock HTTP requests for testing web-context handlers in CLI/TestBox | 1 skill |
| [bx-charts](./bx-charts/) | Chart.js-powered charts — bar, line, pie, doughnut, radar, area, scatter | 1 skill |
| [bx-docbox](./bx-docbox/) | Generate API documentation from BoxLang source (HTML, JSON, UML) | 1 skill |
| [bx-ui-forms](./bx-ui-forms/) | Semantic HTML form components — `bx:form`, `bx:input`, `bx:select`, `bx:slider` | 1 skill |
| [bx-compat-cfml](./bx-compat-cfml/) | CFML compatibility layer for migrating Adobe CF / Lucee apps to BoxLang | 1 skill |

## Usage

Load a skill when the task involves the corresponding module. Multiple skills can be combined — e.g., load both `bx-ai-agents` and `bx-ai-tools` when building an agent that uses function calling.
