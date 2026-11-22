-- Telefon Samsung (com.samsung.android.dialer) - Český port v1.1
-- Přidává kontextové akce (Podrobnosti, Přidat kontakt, Videohovor Meet)
-- k položkám v protokolu hovorů a v seznamu kontaktů + hlásí stav rozbalení řádku.

local manifest = {
  id = 'samsung-dialer-actions-cz',
  name = 'Telefon Samsung – Rychlé akce (CZ)',
  version = '1.1-cz',
  author = 'Tomáš Hromádka (česká úprava ruského skriptu Slonobass Телефон Samsung, autor magiyastraha-tech)',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  description = 'Přidává akce pro podrobnosti, přidání kontaktu a videohovor Meet v protokolu hovorů a kontaktech.',
  minApiVersion = 2,
  testedApiVersion = 3,
  apps = { 'com.samsung.android.dialer' },
  permissions = { 'screen', 'actions', 'speech', 'input' },
}

-- Čísla standardních akcí přístupnosti: ACTION_EXPAND a ACTION_COLLAPSE.
local EXPAND_ACTIONS = { 'expand', 1048576 }
local COLLAPSE_ACTIONS = { 'collapse', 524288 }

local KINDS = {
  {
    rowId = 'container_call_log_content',
    mainId = 'text_call_log_main',
    expandedText = 'Rozbaleno',
    markers = {
      { id = 'expand_photo_layout' },
      { id = 'container_expand_multi_number' },
      { textContains = 'Profilový obrázek' },
      { textContains = 'Obrázek profilu' },
    },
    below = {
      { id = 'container_expand_call_type' },
      { id = 'layout_expand_one' },
    },
    actions = {
      {
        title = 'Podrobnosti',
        queries = {
          { id = 'expand_photo_layout' },
          { textContains = 'Historie hovorů' },
          { textContains = 'View contact' },
        },
      },
      {
        title = 'Přidat kontakt',
        kind = 'add',
        queries = {
          { textContains = 'Přidat do kontaktů' },
          { textContains = 'Add to contact' },
          { textContains = 'Create contact' },
          { id = 'expand_photo_layout' },
        },
      },
      {
        title = 'Videohovor Meet',
        queries = {
          { id = 'layout_expand_three' },
          { contentDescription = 'Videohovor' },
          { contentDescription = 'Video call' },
        },
      },
    },
  },
  {
    rowId = 'container_contact_list_item_content',
    mainId = 'contact_list_item_main',
    expandedText = 'Kontakt rozbalen',
    markers = {},
    below = {
      { id = 'expand_item_phone_container' },
      { id = 'expand_item_call' },
    },
    actions = {
      {
        title = 'Videohovor Meet',
        queries = {
          { id = 'expand_item_vcall' },
          { contentDescription = 'Videohovor, Tlačítko' },
          { contentDescription = 'Videohovor' },
        },
      },
      {
        title = 'Podrobnosti',
        queries = {
          { id = 'expand_item_detail' },
          { contentDescription = 'Podrobnosti, Tlačítko' },
          { contentDescription = 'Podrobnosti' },
          { contentDescription = 'Informace, Tlačítko' },
        },
      },
    },
  },
}

local function idTail(id)
  return string.match(id or '', '[^/]*$')
end

local function shortId(item)
  return idTail(item and item.id or '')
end

local function kindFor(item)
  local id = shortId(item)
  for _, kind in ipairs(KINDS) do
    if kind.rowId == id then return kind end
  end
  return nil
end

local function press(item)
  local ok, clicked = pcall(function() return item:click() end)
  if ok and clicked then return true end
  local tappedOk, tapped = pcall(function() return item:tap() end)
  return tappedOk and tapped == true
end

local function fresh(item)
  local ok, refreshed = pcall(function() return item:refresh() end)
  if ok and refreshed then return refreshed end
  return item
end

local function hasAction(item, names)
  local actions = item.actions
  if type(actions) ~= 'table' then return false end
  for _, action in ipairs(actions) do
    for _, name in ipairs(names) do
      if action.id == name then return true end
    end
  end
  return false
end

local function actionState(row)
  local expand = hasAction(row, EXPAND_ACTIONS)
  local collapse = hasAction(row, COLLAPSE_ACTIONS)
  if collapse and not expand then return true end
  if expand and not collapse then return false end
  return nil
end

local function markedExpanded(kind, row)
  for _, query in ipairs(kind.markers) do
    local ok, found = pcall(function() return row:find(query) end)
    if ok and found then return true end
  end
  return nil
end

local function blockOf(kind, row)
  local okParent, parent = pcall(function() return row:parent() end)
  if not okParent or not parent then return nil end
  local okKids, kids = pcall(function() return parent:children() end)
  if not okKids or type(kids) ~= 'table' then return nil end
  local top = row.bounds and row.bounds.top
  local index
  for i, child in ipairs(kids) do
    if shortId(child) == kind.rowId then
      local childTop = child.bounds and child.bounds.top
      if top and childTop then
        if math.abs(childTop - top) <= 2 then
          index = i
          break
        end
      elseif child.focused then
        index = i
        break
      end
    end
  end
  if not index then return nil end
  local siblings = {}
  for i = index + 1, #kids do
    local child = kids[i]
    if shortId(child) == kind.rowId or child.heading then break end
    siblings[#siblings + 1] = child
  end
  return siblings
end

local function windowLimit(kind, row)
  local bottom = row.bounds and row.bounds.bottom
  if not bottom then return nil end
  local ok, rows = pcall(function() return sf.screen.findAll({ id = kind.rowId }, 50) end)
  local limit
  if ok and type(rows) == 'table' then
    for _, candidate in ipairs(rows) do
      local top = candidate.bounds and candidate.bounds.top
      if top and top > bottom - 1 and (limit == nil or top < limit) then
        limit = top
      end
    end
  end
  return (limit or bottom + 400) - 1
end

local function blockBelow(row, queries, maxQueries, limit)
  local bounds = row.bounds
  if not bounds or not bounds.bottom then return false end
  local bottom = bounds.bottom
  local reach = limit or (bottom + 400)
  for index, query in ipairs(queries) do
    if index > (maxQueries or #queries) then break end
    local ok, found = pcall(function() return sf.screen.findAll(query, 10) end)
    if ok and type(found) == 'table' then
      for _, item in ipairs(found) do
        local top = item.bounds and item.bounds.top
        if top and top >= bottom - 40 and top <= reach then
          return true
        end
      end
    end
  end
  return false
end

local function expandedFor(kind, row, cheap)
  if markedExpanded(kind, row) then return true end
  if not cheap then
    local okBlock, siblings = pcall(blockOf, kind, row)
    if okBlock and type(siblings) == 'table' and #siblings > 0 then return true end
  end
  local state = actionState(row)
  if state ~= nil then return state end
  local bottom = row.bounds and row.bounds.bottom or 0
  local ok, below = pcall(blockBelow, row, kind.below, cheap and 1 or nil, bottom + (cheap and 200 or 150))
  return ok and below or false
end

local function ensureExpanded(kind, row)
  if expandedFor(kind, row) then return true end
  row = fresh(row)
  if expandedFor(kind, row) then return true end
  if hasAction(row, EXPAND_ACTIONS) then
    local ok, done = pcall(function() return row:perform('expand') end)
    if ok and done then
      sf.sleep(350)
      if expandedFor(kind, fresh(row)) then return true end
    end
  end
  if not press(row) then return false end
  sf.sleep(450)
  return expandedFor(kind, fresh(row))
end

local function near(kind, row, queries, tries)
  row = fresh(row)
  local bounds = row.bounds
  local top = bounds and bounds.top or 0
  local bottom = bounds and (bounds.bottom or bounds.top) or 0
  local limit
  if bounds then
    local okLimit, computed = pcall(windowLimit, kind, row)
    if okLimit then limit = computed end
  end
  local reach = limit or (bottom + 400)
  for attempt = 1, tries or 3 do
    local blockOk, siblings = pcall(blockOf, kind, row)
    if blockOk and type(siblings) == 'table' then
      for _, query in ipairs(queries) do
        for _, sibling in ipairs(siblings) do
          if query.id and idTail(query.id) == shortId(sibling) then
            return sibling
          end
          local insideOk, inside = pcall(function() return sibling:find(query) end)
          if insideOk and inside then return inside end
        end
      end
    end
    for _, query in ipairs(queries) do
      local insideOk, inside = pcall(function() return row:find(query) end)
      if insideOk and inside then return inside end
    end
    for _, query in ipairs(queries) do
      local foundOk, found = pcall(function() return sf.screen.findAll(query, 10) end)
      if foundOk and type(found) == 'table' and #found > 0 then
        if #found == 1 then return found[1] end
        local best, bestDistance
        for _, candidate in ipairs(found) do
          local candidateTop = candidate.bounds and candidate.bounds.top
          if not bounds then
            best = candidate
            break
          end
          if candidateTop and candidateTop >= top and candidateTop <= reach then
            local distance = candidateTop - bottom
            if bestDistance == nil or distance < bestDistance then
              best, bestDistance = candidate, distance
            end
          end
        end
        if best then return best end
      end
    end
    if attempt < (tries or 3) then sf.sleep(150) end
  end
  return nil
end

local function rowName(kind, row)
  local ok, item = pcall(function() return row:find({ id = kind.mainId }) end)
  if ok and item then return item.text end
  return nil
end

local function looksLikeNumber(text)
  if not text or text == '' then return false end
  return string.match(text, '^%+?[%d%s%-%(%)]+$') ~= nil
end

local function perform(kind, row, action)
  local name = rowName(kind, row)

  if action.kind == 'add' and name and not looksLikeNumber(name) then
    sf.speak('Číslo už je v kontaktech')
    return
  end

  local expanded = expandedFor(kind, row)

  if not expanded and action.presence then
    local present = false
    for _, query in ipairs(action.presence) do
      local ok, found = pcall(function() return row:find(query) end)
      if ok and found then
        present = true
        break
      end
    end
    if not present then
      sf.speak(action.absentText or (action.title .. ': položka nenalezena'))
      return
    end
  end

  local target
  if expanded then
    target = near(kind, row, action.queries, 4)
  elseif ensureExpanded(kind, row) then
    target = near(kind, row, action.queries, 5)
  end
  if not target then
    sf.sleep(300)
    target = near(kind, row, action.queries, 1)
  end
  if target then
    press(target)
    return
  end
  if not expanded and not expandedFor(kind, row) then
    sf.speak('Nepodařilo se rozbalit položku')
    return
  end
  sf.speak(action.absentText or (action.title .. ': položka nenalezena'))
end

sf.onActions(function(item)
  local kind = kindFor(item)
  if not kind then return nil end
  local list = {}
  for _, action in ipairs(kind.actions) do
    list[#list + 1] = {
      title = action.title,
      run = function(row) perform(kind, row or item, action) end,
    }
  end
  return list
end)

sf.onFocus(function(item, text)
  local kind = kindFor(item)
  if not kind then return nil end
  local ok, expanded = pcall(expandedFor, kind, item, true)
  if not ok or not expanded then return nil end
  if text and text ~= '' then
    return { speak = text .. ' ' .. kind.expandedText }
  end
  return { speak = kind.expandedText }
end)