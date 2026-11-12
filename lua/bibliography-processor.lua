-- bibliography-processor.lua
-- Manually runs citeproc, then adds year headers and lays each entry out in
-- three lines (title, authors, venue)
-- Leverages the fact that citeproc already sorts entries by year

io.stderr:write("\n=== BIBLIOGRAPHY PROCESSOR ===\n")

-- lua/publication-entry.lua builds the three-line entry, emphasises Levin's name,
-- and holds the setting for shortening long author lists (MAX_AUTHORS). Both
-- filters load it from the folder this file is in, much as source() does in R.
local pub = dofile(pandoc.path.join({pandoc.path.directory(PANDOC_SCRIPT_FILE), "publication-entry.lua"}))

-- Mark preprints so that the CSL can print their server ("medRxiv. Preprint. 2026.").
-- Zotero exports a preprint to BibTeX as @misc with the server name as publisher.
-- Pandoc reads that as a reference with no type and no journal, so the CSL has no
-- venue to print and cannot tell the entry from any other untyped one. A preprint
-- is recognised here by a server name containing "rxiv" (medRxiv, bioRxiv, arXiv)
-- in its publisher or journal. It goes to citeproc as CSL type "article", with the
-- bare server name as publisher. References in the metadata take precedence over
-- bibliography entries with the same id, so all other entries still come straight
-- from the bibliography file.
-- lua/recent-publications.lua has the same function: change both together.
local function retype_preprints(doc)
  local preprints = pandoc.List()
  for _, ref in ipairs(pandoc.utils.references(doc)) do
    local venue = pandoc.utils.stringify(ref.publisher or "") .. " " ..
                  pandoc.utils.stringify(ref["container-title"] or "")
    local server = venue:match("%a*[Rr][Xx][Ii][Vv]%a*")
    if server then
      ref.type = "article"
      ref.publisher = server
      preprints:insert(ref)
    end
  end
  io.stderr:write("Retyped " .. #preprints .. " preprints\n")
  doc.meta.references = preprints
  return doc
end

-- Run citeproc on a document
local function citeproc(doc)
  doc = retype_preprints(doc)
  io.stderr:write("Running citeproc...\n")
  if PANDOC_VERSION >= '2.19.1' then
    return pandoc.utils.citeproc(doc)
  else
    local args = {'--from=json', '--to=json', '--citeproc'}
    local result = pandoc.utils.run_json_filter(doc, 'pandoc', args)
    return result or pandoc.Pandoc({})
  end
end

-- Extract year from entry - multiple patterns for maximum flexibility
local function extract_year(blocks)
  local text = pandoc.utils.stringify(blocks)

  -- Try multiple patterns in order of specificity
  local patterns = {
    -- Traditional formats with volume/issue
    "%.%s*(%d%d%d%d);",           -- . 2025;14(23)
    "%.%s*(%d%d%d%d):",           -- . 2025:347

    -- Online-first / no volume formats
    "%.%s*(%d%d%d%d)%.:e",        -- . 2025.:e038921 (article ID)
    "%.%s*(%d%d%d%d)%.%s+doi:",   -- . 2025. doi:
    "%.%s*(%d%d%d%d)%.%s+http",   -- . 2025. http (URL follows)

    -- General formats
    "%.%s*(%d%d%d%d)%.",          -- . 2025.
    ",?%s*(%d%d%d%d)%.",          -- , 2025. or 2025.
    "%((%d%d%d%d)%)",             -- (2025)

    -- Fallback: any 4-digit number that could be a year
    -- This will match standalone years in various contexts
    "[^%d](%d%d%d%d)[^%d]",       -- Any 4 digits not adjacent to other digits
  }

  for _, pattern in ipairs(patterns) do
    local year = text:match(pattern)
    if year then
      local y = tonumber(year)
      -- Sanity check: year should be reasonable
      if y >= 1900 and y <= 2100 then
        io.stderr:write("  Extracted year " .. y .. " using pattern: " .. pattern .. "\n")
        return y
      end
    end
  end

  -- If no pattern matched, log the text for debugging
  io.stderr:write("  WARNING: Could not extract year from: " .. text:sub(1, 100) .. "...\n")
  return nil
end

-- Get the #refs div
local function get_refs_div(doc)
  local refs_div = nil
  doc:walk({
    Div = function(div)
      if div.identifier == "refs" then
        refs_div = div
      end
    end
  })
  return refs_div
end

-- Main processing function
function Pandoc(doc)
  io.stderr:write("\nProcessing document...\n")

  -- Run citeproc to generate bibliography
  doc = citeproc(doc)

  -- Find the #refs div
  local refs_div = get_refs_div(doc)

  if not refs_div then
    io.stderr:write("WARNING: No #refs div found after citeproc\n")
    return doc
  end

  io.stderr:write("Found #refs div with " .. #refs_div.content .. " blocks\n")

  -- Process entries sequentially, adding year headers when year changes
  local new_content = {}
  local current_year = nil
  local entry_count = 0
  local total_highlighted = 0
  local shortened_count = 0
  local one_paragraph_count = 0
  local year_count = 0
  local entries_without_year = 0

  for _, block in ipairs(refs_div.content) do
    if block.t == "Div" and block.classes:includes("csl-entry") then
      entry_count = entry_count + 1

      -- Extract year from this entry. The citation style puts marker characters in
      -- each entry (see lua/publication-entry.lua), so the year is read from a copy
      -- without the markers, which reads as one plain citation:
      -- "12. Authors. Title. Journal. Year;Vol:Pages. doi:..."
      local year = extract_year(pub.without_markers(block).content)

      if not year then
        entries_without_year = entries_without_year + 1
      end

      -- If year changed, add a header
      if year and year ~= current_year then
        io.stderr:write("  Adding year header: " .. year .. "\n")
        table.insert(new_content, pandoc.Header(3, {pandoc.Str(tostring(year))}))
        current_year = year
        year_count = year_count + 1
      end

      -- Lay the entry out in three lines: title, authors, venue. This also puts the
      -- citation number ("12.") in its own span, which the stylesheet sets in a
      -- gutter beside the entry, emphasises Levin's name, and puts the authorship
      -- note after the venue.
      local entry, done = pub.format(block, {show_number = true, show_note = true})
      if done.levin then total_highlighted = total_highlighted + 1 end
      if done.shortened then shortened_count = shortened_count + 1 end
      if not done.three_lines then one_paragraph_count = one_paragraph_count + 1 end

      -- Add the entry
      table.insert(new_content, entry)
    end
  end

  io.stderr:write("Processed " .. entry_count .. " entries\n")
  io.stderr:write("Added " .. year_count .. " year headers\n")
  io.stderr:write("Emphasised Levin in " .. total_highlighted .. " entries\n")
  io.stderr:write("Shortened " .. shortened_count .. " author lists\n")

  if entries_without_year > 0 then
    io.stderr:write("WARNING: " .. entries_without_year .. " entries without detectable year\n")
  end

  if one_paragraph_count > 0 then
    io.stderr:write("WARNING: " .. one_paragraph_count .. " entries have no part markers and are shown " ..
                    "as one paragraph. Is the csl file templates/american-medical-association-no-et-al-v2.csl?\n")
  end

  -- Update the refs div in the document
  doc = doc:walk({
    Div = function(div)
      if div.identifier == "refs" then
        div.content = new_content
        return div
      end
    end
  })

  io.stderr:write("Bibliography processing complete!\n\n")

  return doc
end

return {{Pandoc = Pandoc}}
