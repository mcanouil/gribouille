<%
// @license MIT
// @copyright 2026 Mickaël Canouil
// @author Mickaël Canouil

const sectionOrder = [
  { key: "basics",       heading: "Basics" },
  { key: "bars",         heading: "Bars and counts" },
  { key: "stats",        heading: "Statistics and smoothers" },
  { key: "geoms",        heading: "Layer geometries" },
  { key: "annotations",  heading: "Annotations" },
  { key: "scales",       heading: "Scales and colour" },
  { key: "late-binding", heading: "Late-binding aesthetics" },
  { key: "guides",       heading: "Axes and legends" },
  { key: "facets",       heading: "Facets and coordinates" },
  { key: "themes",       heading: "Themes" }
];
const grouped = {};
for (const item of items) {
  const sec = item.section || "other";
  (grouped[sec] = grouped[sec] || []).push(item);
}
%>
<% for (const { key, heading } of sectionOrder) { %>
<% if (grouped[key]) { %>
```{=html}
<section class="gallery-section">
<h2 id="<%= key %>"><%= heading %></h2>
<div class="gallery">
```
<% for (const item of grouped[key]) { %>
```{=html}
<article class="gallery-item">
<div class="light-content"><img class="lightbox" data-gallery="examples-light" src="../assets/typst-render/examples/<%= item.slug %>-light.svg" alt="<%= item.alt %>" loading="lazy"></div>
<div class="dark-content"><img class="lightbox" data-gallery="examples-dark" src="../assets/typst-render/examples/<%= item.slug %>-dark.svg" alt="<%= item.alt %>" loading="lazy"></div>
<h3 id="<%= item.slug %>"><%= item.title %></h3>
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
