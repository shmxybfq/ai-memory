<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<!-- aim:doc_id={{DOC_ID}} title=Compressed Project Doc-{{PROJECT_NAME}} tags=compressed created={{CREATED}} created_by={{CREATED_BY}} owner=__project__ status=active source=compress version=1 sources={{SOURCES}} -->
<title>Compressed Project Doc - {{PROJECT_NAME}}</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; line-height: 1.7; color: #333; }
  h1 { border-bottom: 3px solid #4a90d9; padding-bottom: 10px; color: #1a1a1a; }
  h2 { border-bottom: 1px solid #ddd; padding-bottom: 8px; color: #2c3e50; margin-top: 40px; }
  h3 { color: #34495e; margin-top: 25px; }
  table { border-collapse: collapse; width: 100%; margin: 15px 0; }
  th, td { border: 1px solid #ddd; padding: 10px 12px; text-align: left; }
  th { background: #f5f7fa; color: #2c3e50; font-weight: 600; }
  code { background: #f0f0f0; padding: 2px 6px; border-radius: 3px; font-size: 0.9em; }
  pre { background: #1e1e1e; color: #d4d4d4; padding: 15px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
  pre code { background: none; padding: 0; }
  blockquote { border-left: 4px solid #4a90d9; margin: 15px 0; padding: 10px 20px; background: #f9f9f9; }
  .highlight { background: #fff3cd; padding: 12px; border-radius: 5px; margin: 15px 0; }
  .danger { background: #f8d7da; padding: 12px; border-radius: 5px; margin: 15px 0; }
  .success { background: #d4edda; padding: 12px; border-radius: 5px; margin: 15px 0; }
  .section-tag { display: inline-block; background: #4a90d9; color: white; padding: 2px 8px; border-radius: 3px; font-size: 0.8em; margin-right: 5px; }
  /* Archive zone visual distinction */
  #archive { opacity: 0.75; border-left: 3px dashed #999; padding-left: 15px; margin-top: 60px; }
  #archive h2 { color: #666; }
  .deprecated { color: #888; font-style: italic; }
</style>
</head>
<body>

<h1>Compressed Project Doc - {{PROJECT_NAME}}</h1>

<p>owner: <code>__project__</code> | last compress: {{CREATED}} by {{CREATED_BY_NAME}} | version: 1</p>

<div class="highlight">
<strong>How to read this document:</strong>
<ul>
<li><strong>Active section</strong>: AI reads here by default. Contains core knowledge currently in use by the project.</li>
<li><strong>Archive section</strong>: Deprecated content. AI reads on demand.</li>
<li>Each section is annotated with source documents and original authors.</li>
</ul>
</div>

<section id="active">
<h2><span class="section-tag">Active</span>1. Project Overview</h2>

{{PROJECT_OVERVIEW}}

<h2>2. Architecture Evolution</h2>

{{ARCHITECTURE_EVOLUTION}}

<h2>3. Current Architecture</h2>

{{CURRENT_ARCHITECTURE}}

<h2>4. Core Components</h2>

{{CORE_COMPONENTS}}

<h2>5. Technology Choices</h2>

{{TECH_CHOICES}}

<h2>6. Key Decisions</h2>

{{KEY_DECISIONS}}

<h2>7. Known Limitations &amp; TODOs</h2>

{{KNOWN_LIMITATIONS}}

</section>

<section id="archive">
<h2><span class="section-tag" style="background:#999;">Archive</span>Deprecated Content</h2>

<p class="deprecated"><em>The following content has been superseded by later iterations or is no longer in use, but is retained for traceability. AI does not read this section by default.</em></p>

{{ARCHIVE_CONTENT}}

</section>

<hr>

<div class="highlight">
<strong>Compression metadata:</strong>
<ul>
<li>doc_id: {{DOC_ID}}</li>
<li>owner: __project__ (shared)</li>
<li>version: 1</li>
<li>created: {{CREATED}}</li>
<li>created_by: {{CREATED_BY_NAME}} ({{CREATED_BY}})</li>
<li>contributors: {{CONTRIBUTORS}}</li>
</ul>
</div>

</body>
</html>
