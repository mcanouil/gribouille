#' Register a passthrough knitr engine for `{typst}` code blocks.
#'
#' Without this, knitr emits "Unknown language engine 'typst'" warnings and
#' wraps the block in a cell-output div with a `typst` (singular) class. The
#' engine simply re-emits the chunk source as a `` ```{typst} `` fenced block
#' so pandoc sees the literal `{typst}` class that the typst-render filter
#' expects.
if (requireNamespace("knitr", quietly = TRUE)) {
  knitr::knit_engines$set(typst = function(options) {
    code <- paste(options[["code"]], collapse = "\n")
    knitr::asis_output(paste0("\n```{typst}\n", code, "\n```\n"))
  })
}

#' Session-local accumulator for `typst_define()` payloads.
#'
#' Each call to `typst_define()` updates this list (last-write-wins on names,
#' insertion order preserved) and re-emits the full accumulated payload as a
#' Pandoc YAML metadata block. Pandoc merges metadata blocks at parse time
#' (later same-key wins), so the final document metadata sees the largest
#' accumulator state.
.typst_define_state <- new.env(parent = emptyenv())
.typst_define_state[["entries"]] <- list()

#' Pass R values into Typst code cells of the document.
#'
#' Emits a Pandoc YAML metadata block carrying a JSON payload that the
#' typst-render Lua filter ingests and converts into a
#' `#let typst_define = (...)` binding available in every `{typst}` code
#' block of the document. The filter ingests the metadata before it processes
#' any block, so a block above this call sees the values as well.
#'
#' @param ... Named or positional values.
#'   Unnamed positional values use the deparsed expression as the key.
#' @return A `knitr::asis_output` object; visible only as a side effect when
#'   placed in a knitr chunk.
typst_define <- function(...) {
  named_vars <- rlang::list2(...)
  names(named_vars) <- names(rlang::quos_auto_name(rlang::enquos(...)))
  for (name in names(named_vars)) {
    .typst_define_state[["entries"]][[name]] <- named_vars[[name]]
  }
  entries <- .typst_define_state[["entries"]]
  contents <- jsonlite::toJSON(
    list(contents = unname(Map(
      function(name, value) list(name = name, value = value),
      names(entries), entries
    ))),
    dataframe = "columns",
    null = "null",
    na = "null",
    auto_unbox = TRUE,
    digits = NA
  )
  # Hex-encode the JSON. Pandoc's smart-quote / dash / ellipsis transforms
  # would otherwise corrupt JSON quotes (`"` -> `“`/`”`) and any `--`/`...`
  # sequences inside string values during metadata block parsing.
  encoded <- paste(charToRaw(enc2utf8(contents)), collapse = "")
  knitr::asis_output(paste0(
    "\n---\ntypst-define: ", encoded, "\n---\n"
  ))
}
