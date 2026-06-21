<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<!-- aim:doc_id={{DOC_ID}} title=项目压缩文档-{{PROJECT_NAME}} tags=compressed created={{CREATED}} created_by={{CREATED_BY}} owner=__project__ status=active source=compress version=1 -->
<title>项目压缩文档 - {{PROJECT_NAME}}</title>
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

<h1>项目压缩文档 - {{PROJECT_NAME}}</h1>

<p>owner: <code>__project__</code> | last compress: {{CREATED}} by {{CREATED_BY_NAME}} | version: 1</p>

<div class="highlight">
<strong>如何阅读这份文档：</strong>
<ul>
<li><strong>当前有效区</strong>：AI 默认读这里,包含项目当前还在用的核心知识</li>
<li><strong>历史归档区</strong>：deprecated 内容,AI 按需扩展阅读</li>
<li>每个章节标注了来源文档和原作者</li>
</ul>
</div>

<section id="active">
<h2><span class="section-tag">当前有效</span>一、项目概述</h2>

{{PROJECT_OVERVIEW}}

<h2>二、架构演进</h2>

{{ARCHITECTURE_EVOLUTION}}

<h2>三、当前架构</h2>

{{CURRENT_ARCHITECTURE}}

<h2>四、核心组件</h2>

{{CORE_COMPONENTS}}

<h2>五、技术选型</h2>

{{TECH_CHOICES}}

<h2>六、关键决策记录</h2>

{{KEY_DECISIONS}}

<h2>七、已知限制与待办</h2>

{{KNOWN_LIMITATIONS}}

</section>

<section id="archive">
<h2><span class="section-tag" style="background:#999;">历史归档</span>deprecated 内容</h2>

<p class="deprecated"><em>以下内容已被后续迭代替代或不再使用,但保留以备追溯。AI 默认不读这里。</em></p>

{{ARCHIVE_CONTENT}}

</section>

<hr>

<div class="highlight">
<strong>压缩元数据：</strong>
<ul>
<li>doc_id: {{DOC_ID}}</li>
<li>owner: __project__ (公共)</li>
<li>version: 1</li>
<li>created: {{CREATED}}</li>
<li>created_by: {{CREATED_BY_NAME}} ({{CREATED_BY}})</li>
<li>contributors: {{CONTRIBUTORS}}</li>
</ul>
</div>

</body>
</html>
