<%
// @license MIT
// @copyright 2026 Mickaël Canouil
// @author Mickaël Canouil

const groups = [
  { key: "story", heading: "What do you want to show?", extraClass: "" },
  { key: "craft", heading: "Craft", extraClass: " intent-cards--craft" }
];
%>
<% for (const { key, heading, extraClass } of groups) { %>
<% const cards = items.filter((item) => item.group === key); %>
<% if (cards.length > 0) { %>
```{=html}
<section class="gallery-section">
<h2 id="<%= key %>"><%= heading %></h2>
<div class="intent-cards<%= extraClass %>">
```
<% for (const card of cards) { %>
```{=html}
<article class="intent-card">
<div class="light-content"><img src="../assets/typst-render/gallery/hero-<%= card.hero %>-light.svg" alt="<%= card.alt %>" loading="lazy"></div>
<div class="dark-content"><img src="../assets/typst-render/gallery/hero-<%= card.hero %>-dark.svg" alt="<%= card.alt %>" loading="lazy"></div>
<h3><a href="<%= card.href %>"><%= card.title %></a></h3>
<p><%= card.blurb %></p>
</article>
```
<% } %>
```{=html}
</div>
</section>
```
<% } %>
<% } %>
