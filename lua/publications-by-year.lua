-- publications-by-year.lua
-- Organizes bibliography by year with headers

-- Extract year from citation
local function get_year(cite)
  if cite.issued and cite.issued['date-parts'] then
    local date_parts = cite.issued['date-parts'][1]
    if date_parts and date_parts[1] then
      return tonumber(date_parts[1])
    end
  end
  return 0
end

-- Process the document and organize refs by year
function Pandoc(doc)
  if not doc.meta.references then
    return doc
  end
  
  local refs = doc.meta.references
  local refs_by_year = {}
  local years = {}
  
  -- Group references by year
  for i, ref in ipairs(refs) do
    local year = get_year(ref)
    if year > 0 then
      if not refs_by_year[year] then
        refs_by_year[year] = {}
        table.insert(years, year)
      end
      table.insert(refs_by_year[year], ref)
    end
  end
  
  -- Sort years descending
  table.sort(years, function(a, b) return a > b end)
  
  -- Build new document blocks
  local new_blocks = {}
  
  for _, year in ipairs(years) do
    -- Add year header
    table.insert(new_blocks, pandoc.Header(3, tostring(year)))
    
    -- Add this year's references
    local year_refs = refs_by_year[year]
    
    -- Create a temporary doc with just this year's refs
    local temp_meta = pandoc.Meta({references = year_refs})
    local temp_doc = pandoc.Pandoc({}, temp_meta)
    
    -- Use pandoc's citation processing
    temp_doc = pandoc.utils.citeproc(temp_doc)
    
    -- Extract the references div
    for _, block in ipairs(temp_doc.blocks) do
      if block.t == "Div" and block.attr.identifier == "refs" then
        -- Add the contents of the refs div
        for _, ref_block in ipairs(block.content) do
          table.insert(new_blocks, ref_block)
        end
      end
    end
  end
  
  -- Replace the refs div with our year-organized content
  local function replace_refs(blocks)
    local result = {}
    for _, block in ipairs(blocks) do
      if block.t == "Div" and block.attr.identifier == "refs-by-year" then
        -- Replace with our organized blocks
        for _, new_block in ipairs(new_blocks) do
          table.insert(result, new_block)
        end
      else
        table.insert(result, block)
      end
    end
    return result
  end
  
  doc.blocks = replace_refs(doc.blocks)
  
  return doc
end

return {{Pandoc = Pandoc}}
