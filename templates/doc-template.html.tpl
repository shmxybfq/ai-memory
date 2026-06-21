<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<!-- aim:doc_id={{DOC_ID}} title={{TITLE}} tags={{TAGS}} created={{CREATED}} created_by={{CREATED_BY}} owner={{OWNER}} status=active source={{SOURCE}} -->
<title>{{TITLE}}</title>
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
</style>
</head>
<body>

<h1>{{TITLE}}</h1>

<p>操作时间：{{CREATED}}（创建 by {{OWNER_NAME}}）</p>

<!-- Content goes here -->
{{CONTENT}}

<hr>

<div class="highlight">
<strong>文档元数据：</strong>
<ul>
<li>doc_id: {{DOC_ID}}</li>
<li>owner: {{OWNER_NAME}} ({{OWNER}})</li>
<li>tags: {{TAGS}}</li>
<li>source: {{SOURCE}}</li>
</ul>
</div>

</body>
</html>
