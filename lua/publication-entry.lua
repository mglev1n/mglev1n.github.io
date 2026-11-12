-- publication-entry.lua
-- Shared by recent-publications.lua (home page) and bibliography-processor.lua
-- (publications page). It is not a filter itself: the two filters load it.
--
-- It turns one bibliography entry, as citeproc formats it, into the three lines
-- the site shows:
--
--   Title
--   Authors                    every author, with Levin's name emphasised
--   Journal. Year;Vol:Pages. doi:...   the DOI (or URL) is the entry's link; the
--                              publications page adds the authorship note
--
-- How the parts are found: the citation style
-- (templates/american-medical-association-no-et-al-v2.csl) puts a marker character
-- at the start of each part and between author names. This file cuts the entry at
-- the markers and deletes them. It does not look for periods or commas to find
-- where a part ends, so a title with a period, colon, or question mark in it cannot
-- be cut in the wrong place. Names, title, and venue are still formatted by the
-- citation style; nothing about journal, year, volume, or pages is decided here.
-- The marker between author names is what lets Levin's name be found as one whole
-- name, even beside an institution whose name has a comma in it.

local M = {}

-- Levin's name as the citation style prints it ("Levin M" where a reference gives
-- no middle initial). An author name in this list is emphasised on both pages.
local LEVIN_NAMES = { "Levin MG", "Levin M", "Levin", "MG Levin", "M Levin" }

-- ===== Markers ==================================================================
-- These must match the markers in the citation style file. They are Unicode
-- private-use characters, which do not occur in references. "\u{E000}" is how Lua
-- writes the character that the style file writes as &#xE000;.
local MARK = {
  authors = "\u{E000}",  -- the author list starts
  name    = "\u{E001}",  -- the next author name starts
  title   = "\u{E002}",  -- the title starts
  venue   = "\u{E003}",  -- the venue starts (journal, year, volume, pages)
  access  = "\u{E004}",  -- the DOI or URL starts
  note    = "\u{E005}",  -- the note starts
}

-- Matches any one marker. U+E000 to U+E00F are stored as the bytes 238, 128, and
-- then 128 to 143.
local ANY_MARKER = "\238\128[\128-\143]"

local PART_OF_MARKER = {}
for part, marker in pairs(MARK) do
  PART_OF_MARKER[marker] = part
end

local IS_LEVIN = {}
for _, name in ipairs(LEVIN_NAMES) do
  IS_LEVIN[name] = true
end

local stringify = pandoc.utils.stringify

-- ===== Small helpers ============================================================

-- A copy of an entry (or any element) with the markers deleted. The result reads
-- exactly as the entry did before the markers were added to the citation style, so
-- the filters use it wherever they read an entry's text (year, author position).
function M.without_markers(element)
  return element:walk({
    Str = function(str)
      if str.text:find(ANY_MARKER) then
        local text = str.text:gsub(ANY_MARKER, "")
        if text == "" then
          return {}  -- the Str held only markers: delete it
        end
        return pandoc.Str(text)
      end
    end
  })
end

-- Break a list of inlines into pieces at the markers. Each item of the result is
-- either a pandoc inline or a marker (a plain Lua string).
local function cut_at_markers(inlines, pieces)
  pieces = pieces or {}
  for _, inline in ipairs(inlines) do
    if inline.t == "Str" and inline.text:find(ANY_MARKER) then
      local text, pos = inline.text, 1
      while pos <= #text do
        local first, last = text:find(ANY_MARKER, pos)
        if not first then
          table.insert(pieces, pandoc.Str(text:sub(pos)))
          break
        end
        if first > pos then
          table.insert(pieces, pandoc.Str(text:sub(pos, first - 1)))
        end
        table.insert(pieces, text:sub(first, last))
        pos = last + 1
      end
    elseif inline.t == "Span" and stringify(inline):find(ANY_MARKER) then
      -- Citeproc sometimes wraps part of an entry in a <span> that changes nothing
      -- on the page. It wraps the whole author list this way when a name starts
      -- with a lower-case letter, as in the author "null null". Look inside it.
      cut_at_markers(inline.content, pieces)
    else
      table.insert(pieces, inline)
    end
  end
  return pieces
end

-- Remove spaces from both ends of a list of inlines.
local function trim(inlines)
  local function is_space(inline)
    return inline and (inline.t == "Space" or inline.t == "SoftBreak")
  end
  while is_space(inlines[1]) do
    inlines:remove(1)
  end
  while is_space(inlines[#inlines]) do
    inlines:remove(#inlines)
  end
  return inlines
end

-- Remove one closing character ("." or ",") from the end of a list of inlines,
-- if it is there.
local function drop_closing(inlines, character)
  local last = inlines[#inlines]
  if last and last.t == "Str" and last.text:sub(-1) == character then
    if #last.text == 1 then
      inlines:remove(#inlines)
    else
      inlines[#inlines] = pandoc.Str(last.text:sub(1, -2))
    end
  end
  return inlines
end

-- One line of an entry: <div class="..."> around the inlines.
local function line(class, inlines)
  return pandoc.Div({pandoc.Plain(inlines)}, pandoc.Attr("", {class}))
end

-- ===== Cutting an entry into its parts ==========================================

-- Returns a table with the parts of an entry, or nil if the entry does not have
-- the markers (then the entry is shown as one paragraph, see M.format below).
--   number  inlines  "12."
--   names   list of inlines, one per author
--   title, venue     inlines
--   access, note     inlines, or nil if the entry has none
local function split_entry(entry)
  local paragraph = entry.content[1]
  if #entry.content ~= 1 or (paragraph.t ~= "Para" and paragraph.t ~= "Plain") then
    return nil
  end

  local parts = { number = pandoc.Inlines({}), names = {} }
  local current = parts.number  -- the part that the next piece belongs to
  for _, piece in ipairs(cut_at_markers(paragraph.content)) do
    if type(piece) == "string" then
      -- A marker: a new part starts here
      local part = PART_OF_MARKER[piece]
      if part == "authors" or part == "name" then
        current = pandoc.Inlines({})
        table.insert(parts.names, current)
      elseif part then
        current = pandoc.Inlines({})
        parts[part] = current
      end
    else
      current:insert(piece)
    end
  end

  if not parts.title or not parts.venue or #parts.names == 0 then
    return nil
  end

  -- Tidy each part. The citation style ends the author list and the title with a
  -- period and puts a comma after each name. On a line of their own they do not
  -- need them. A title that ends with "?" or "!" keeps it.
  trim(parts.number)
  local names = {}
  for i, name in ipairs(parts.names) do
    drop_closing(trim(name), i == #parts.names and "." or ",")
    if #name > 0 then
      table.insert(names, name)
    end
  end
  parts.names = names
  drop_closing(trim(parts.title), ".")
  trim(parts.venue)
  if parts.note then
    trim(parts.note)
  end

  -- A reference with no authors: the citation style prints the title in the
  -- authors' place and leaves the title part empty.
  if #parts.title == 0 and #parts.names > 0 then
    parts.title = parts.names[1]
    parts.names = {}
  end

  return parts
end

-- ===== The author line ==========================================================

local function is_levin(name)
  return IS_LEVIN[stringify(name)] == true
end

-- Returns the inlines of the author line: every name, with ", " between names
-- as the citation style has it, and Levin's name in <strong>. Also returns true
-- if Levin's name was found.
local function author_line(names)
  local out = pandoc.Inlines({})
  local found_levin = false

  for i, name in ipairs(names) do
    if i > 1 then
      out:extend({pandoc.Str(","), pandoc.Space()})
    end
    if is_levin(name) then
      out:insert(pandoc.Strong(name))
      found_levin = true
    else
      out:extend(name)
    end
  end

  return out, found_levin
end

-- ===== Fallback: the entry as one paragraph =====================================

-- Used only if an entry has no markers, for example if the site is built with a
-- different citation style. The entry stays one paragraph, as the style wrote it.
local function one_paragraph(entry, options)
  local flat = M.without_markers(entry)
  local blocks = flat.content
  local paragraph = blocks[1]
  if paragraph and (paragraph.t == "Para" or paragraph.t == "Plain") then
    local inlines = paragraph.content
    local first = inlines[1]
    -- The citation number: in its own span for the gutter, or removed
    if first and first.t == "Str" and first.text:match("^%d+%.$") then
      inlines:remove(1)
      trim(inlines)
      if options.show_number then
        inlines:insert(1, pandoc.Span({first}, {class = "csl-num"}))
      end
      paragraph.content = inlines
      blocks[1] = paragraph
      flat.content = blocks
    end
  end
  return flat
end

-- ===== The entry in three lines =================================================

-- entry:    one bibliography entry from citeproc (a Div with class csl-entry)
-- options:  show_number  true to keep the citation number (set in the gutter)
--           show_note    true to print the authorship note after the venue
-- Returns the new entry and a table that says what was done:
--   three_lines  false if the entry had no markers and stayed one paragraph
--   levin        true if Levin's name was found and emphasised
function M.format(entry, options)
  local parts = split_entry(entry)
  if not parts then
    return one_paragraph(entry, options), { three_lines = false, levin = false }
  end

  local lines = pandoc.List({})

  -- Line 1: the title, as plain text. The entry's link is the DOI on line 3, which is
  -- underlined like every other link on the site.
  local title = parts.title
  if options.show_number and #parts.number > 0 then
    -- The number goes inside the title line so that the two share a text baseline
    title:insert(1, pandoc.Space())
    title:insert(1, pandoc.Span(parts.number, {class = "csl-num"}))
  end
  lines:insert(line("pub-title", title))

  -- Line 2: the authors
  local levin = false
  if #parts.names > 0 then
    local authors
    authors, levin = author_line(parts.names)
    lines:insert(line("pub-authors", authors))
  end

  -- Line 3: the venue, then the DOI (or the URL, when the style printed one instead),
  -- then the authorship note. The style prints the note in bold italics; here it is
  -- plain text in a span, which styles.css sets in grey italics.
  local venue = parts.venue
  local with_note = options.show_note and parts.note and #parts.note > 0
  if parts.access then
    -- The style puts a period after the DOI only when a note follows. Take it off
    -- here and put it back below if the note is shown, so that an entry without a
    -- note, and every entry on the home page, ends at the DOI.
    local access = drop_closing(trim(parts.access), ".")
    if #access > 0 then
      if #venue > 0 then
        venue:insert(pandoc.Space())
      end
      venue:extend(access)
      if with_note then
        venue:insert(pandoc.Str("."))
      end
    end
  end
  if with_note then
    local note = parts.note:walk({
      Strong = function(strong) return strong.content end,
      Emph = function(emph) return emph.content end,
    })
    if #venue > 0 then
      venue:insert(pandoc.Space())
    end
    venue:insert(pandoc.Span(note, {class = "authorship-note"}))
  end
  if #venue > 0 then
    lines:insert(line("pub-venue", venue))
  end

  return pandoc.Div(lines, entry.attr), { three_lines = true, levin = levin }
end

return M
