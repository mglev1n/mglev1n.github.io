-- Consolidated Author Highlighting Filter for UPHS CV
-- Highlights "Levin" name variations with smart context-aware initial detection

-- Configuration: Exact patterns that include "Levin"
local levin_patterns = {
  "Levin MG",     
  "Levin M",      
  "Levin",        
  "Levin MG,",    
  "Levin MG.",    
  "Levin M,",     
  "Levin M.",     
  "MG Levin",     
  "M Levin",
  "Levin, MG",
  "Levin, M",
}

-- Create lookup table for exact matches
local levin_lookup = {}
for _, pattern in ipairs(levin_patterns) do
  levin_lookup[pattern] = true
end

-- Track context - set when we see "Levin" to help identify related initials
local levin_context = false
local context_distance = 0

-- Function to check if text should be highlighted
local function should_highlight(text)
  -- Always highlight exact Levin patterns
  if levin_lookup[text] then
    levin_context = true  -- Set context for nearby initials
    context_distance = 0
    return true
  end
  
  -- Pattern matching for Levin variations
  if text:find("Levin") then
    levin_context = true
    context_distance = 0
    if text:match("^Levin,?%s+M?G?[%.,]?$") or 
       text:match("^M?G?%s+Levin[%.,]?$") or
       text:match("^Levin[%.,]?$") then
      return true
    end
  end
  
  -- Highlight standalone initials ONLY if we recently saw "Levin"
  if levin_context and context_distance <= 3 then
    if text == "MG" or text == "MG," or text == "MG." or 
       text == "M" or text == "M," or text == "M." then
      return true
    end
  end
  
  return false
end

-- Function to apply bold formatting
local function make_bold(text)
  return pandoc.Strong({pandoc.Str(text)})
end

-- Function to reset context after distance threshold
local function update_context()
  if levin_context then
    context_distance = context_distance + 1
    if context_distance > 5 then
      levin_context = false
      context_distance = 0
    end
  end
end

-- Main filter function
return {
  {
    -- Process document blocks to maintain context across elements
    Block = function(elem)
      -- Reset context at the start of each bibliography entry
      if elem.t == "Para" or elem.t == "Div" then
        local elem_str = pandoc.utils.stringify(elem)
        -- If this looks like a new bibliography entry (starts with number)
        if elem_str:match("^%d+%.") then
          levin_context = false
          context_distance = 0
        end
      end
      return elem
    end,
    
    Str = function(elem)
      local highlight = should_highlight(elem.text)
      update_context()
      
      if highlight then
        return make_bold(elem.text)
      else
        return elem
      end
    end,
    
    -- Handle spans that might contain author names
    Span = function(elem)
      local new_content = {}
      local changed = false
      
      for i, item in ipairs(elem.content) do
        if item.t == "Str" then
          local highlight = should_highlight(item.text)
          update_context()
          
          if highlight then
            table.insert(new_content, make_bold(item.text))
            changed = true
          else
            table.insert(new_content, item)
          end
        else
          table.insert(new_content, item)
        end
      end
      
      if changed then
        elem.content = new_content
      end
      return elem
    end,
    
    -- Avoid double bolding
    Strong = function(elem)
      return elem
    end
  }
}