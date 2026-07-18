<%
// @license MIT
// @copyright 2026 Mickaël Canouil
// @author Mickaël Canouil

const monthNames = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

function ordinalSuffix(day) {
  const rem100 = day % 100;
  if (rem100 >= 11 && rem100 <= 13) return "th";
  switch (day % 10) {
    case 1: return "st";
    case 2: return "nd";
    case 3: return "rd";
    default: return "th";
  }
}

function formatDate(value) {
  const date = value instanceof Date ? value : new Date(value);
  if (isNaN(date.getTime())) return String(value);
  const day = date.getUTCDate();
  return `${day}${ordinalSuffix(day)} ${monthNames[date.getUTCMonth()]} ${date.getUTCFullYear()}`;
}
%>
```{=html}
<ol class="news-releases">
```
<% for (const item of items) { %>
```{=html}
<li class="news-release">
<a class="news-thumb-link" href="<%= item.path %>" target="_blank" rel="noopener noreferrer" tabindex="-1" aria-hidden="true">
<img class="news-thumb" src="<%= item.path %>featured.png" alt="Social card for <%= item.title %>" loading="lazy">
</a>
<div class="news-release-body">
<div class="news-release-head">
<span class="news-version">v<%= item.version %></span>
<div class="listing-date"><%= formatDate(item.date) %></div>
</div>
<h2 class="news-release-title"><%= item.title %></h2>
```

::: {.news-release-description}
<%= item.description %>
:::

```{=html}
<a class="news-read" href="<%= item.path %>" target="_blank" rel="noopener noreferrer">Read the announcement</a>
</div>
</li>
```
<% } %>
```{=html}
</ol>
```
