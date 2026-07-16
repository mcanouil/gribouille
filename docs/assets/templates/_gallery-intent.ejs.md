<%
// @license MIT
// @copyright 2026 Mickaël Canouil
// @author Mickaël Canouil

const showcase = items.filter((item) => item.showcase);
const rest = items.filter((item) => !item.showcase);
const sections = [
  { key: "showcase", heading: "Showcase", entries: showcase, extraClass: " gallery-item--showcase" },
  { key: "feature-demos", heading: "Feature demos", entries: rest, extraClass: "" }
];
%>
<% for (const { key, heading, entries, extraClass } of sections) { %>
<% if (entries.length > 0) { %>
```{=html}
<section class="gallery-section">
<h2 id="<%= key %>"><%= heading %></h2>
<div class="gallery">
```
<% for (const item of entries) { %>
```{=html}
<article class="gallery-item<%= extraClass %>">
<div class="light-content"><img class="lightbox" data-gallery="gallery-light" src="../assets/typst-render/gallery/<%= item.slug %>-light.svg" alt="<%= item.alt %>" loading="lazy"></div>
<div class="dark-content"><img class="lightbox" data-gallery="gallery-dark" src="../assets/typst-render/gallery/<%= item.slug %>-dark.svg" alt="<%= item.alt %>" loading="lazy"></div>
<h3 id="<%= item.slug %>"><%= item.title %></h3>
<p class="gallery-badges">
<% if (item.data) { %><span class="gallery-badge gallery-badge--data"><%= item.data %></span><% } %>
<% if (item.chart) { %><span class="gallery-badge"><%= item.chart %></span><% } %>
</p>
```

::: {.gallery-description}
<%= item.description %>
:::

```{=html}
<button type="button" class="btn btn-sm gallery-source-btn" data-bs-toggle="modal" data-bs-target="#modal-<%= item.slug %>" aria-label="View source for <%= item.title %>">View source</button>
</article>
```
<% } %>
```{=html}
</div>
</section>
```
<% } %>
<% } %>
