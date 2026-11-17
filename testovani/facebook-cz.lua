-- Facebook Actions and Skip (Česká lokalizace pro Facebook com.facebook.katana)
-- Podpora pro příspěvky ve feedu, Upozornění i přeskakování sekcí.

local manifest = {
  id = 'facebook-actions-skip-cz',
  name = 'Facebook Actions and Skip (CZ)',
  version = '1.9-cz',
  author = 'Tomáš Hromádka (česká úprava skriptu Facebook Actions and Skip, autor Atlas)',
  description = 'Švihnutím nahoru/dolů na příspěvku nebo upozornění listuje akcemi, poklepáním je spustí. Švihnutí dvěma prsty doprava nebo SandFly+J přeskočí sekce.',
  minApiVersion = 2,
  testedApiVersion = 3,
  apps = { 'com.facebook.katana' },
  permissions = { 'screen', 'actions', 'input', 'speech' },
  commands = {
    { id = 'next_action', title = 'Další akce', gesture = 'swipeDown' },
    { id = 'prev_action', title = 'Předchozí akce', gesture = 'swipeUp' },
    { id = 'run_action', title = 'Spustit vybranou akci', gesture = 'doubleTap' },
    { id = 'skip_section', title = 'Přeskočit sekci', gesture = { 'twoFingerSwipeRight', 'threeFingerSwipeRight' }, keys = 'sf+j' },
  },
}

-- ---------------------------------------------------------------------------
-- Pomocné funkce
-- ---------------------------------------------------------------------------

local function endsWith(s, tail)
  if s == nil then return false end
  return tail == '' or s:sub(-#tail) == tail
end

local function startsWith(s, head)
  if s == nil then return false end
  return head == '' or s:sub(1, #head) == head
end

local function nodeLabel(node)
  if node == nil then return '' end
  local d = node.contentDescription
  if d ~= nil and d ~= '' then return d end
  local t = node.text
  if t ~= nil and t ~= '' then return t end
  return ''
end

local function containsText(node)
  return nodeLabel(node) ~= ''
end

local function isInside(node, anc)
  local p = node
  local guard = 0
  while p ~= nil and guard < 40 do
    if p == anc then return true end
    p = p:parent()
    guard = guard + 1
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Část 1: Listování akcemi příspěvku a upozornění + spuštění poklepáním
-- ---------------------------------------------------------------------------

local selNode = nil
local selIdx = nil
local selLabel = nil
local selId = nil
local selKind = nil

local function clearSelection()
  selNode, selIdx, selLabel, selId, selKind = nil, nil, nil, nil, nil
end

local postState = {}

local function postKey(node)
  return nodeLabel(node)
end

local function postMenuItems(state)
  local first, second
  if state == 'like' then
    first, second = 'Odebrat reakci To se mi líbí', 'Změnit reakci'
  elseif state == 'other' then
    first, second = 'Odebrat reakci', 'Změnit reakci'
  else
    first, second = 'To se mi líbí', 'Zareagovat'
  end
  return {
    first,
    second,
    'Okomentovat',
    'Sdílet',
    'Zobrazit další možnosti pro tento příspěvek',
    'Získat podrobné popisy obrázků',
  }
end

-- Položky nabídky po otevření možností u Upozornění
local function notificationMenuItems()
  return {
    'Odebrat toto upozornění',
    'Vypnout upozornění',
    'Nahlásit problém týmu Upozornění',
  }
end

-- Systémové technické akce, které nechceme nikdy číst jako uživatelské akce
local IGNORED_SYSTEM_ACTIONS = {
  focusinput = true,
  select = true,
  clearselection = true,
  click = true,
  longclick = true,
  showonscreen = true,
  scrollforward = true,
  scrollbackward = true,
  accessibilityfocus = true,
  clearaccessibilityfocus = true,
  ['action_focus'] = true,
  ['action_select'] = true,
  ['action_clear_selection'] = true,
  ['action_click'] = true,
  ['action_show_on_screen'] = true,
}

local function usableActions(node)
  local out = {}
  local acts = node.actions
  if acts == nil then return out end
  for _, a in ipairs(acts) do
    local rawLabel = nil
    local id = nil
    if type(a) == 'table' then
      rawLabel = a.label
      id = a.id
    elseif type(a) == 'string' then
      rawLabel = a
    end
    if rawLabel ~= nil and rawLabel ~= '' then
      local check = rawLabel:lower():gsub('%s+', '')
      if not IGNORED_SYSTEM_ACTIONS[check] then
        out[#out + 1] = {
          label = rawLabel,
          rawLabel = rawLabel,
          id = id
        }
      end
    end
  end
  return out
end

local function hasAction(node, targetLabels)
  local acts = node.actions
  if acts == nil then return false end
  for _, a in ipairs(acts) do
    local lbl = type(a) == 'table' and a.label or (type(a) == 'string' and a or '')
    for _, target in ipairs(targetLabels) do
      if lbl == target then return true end
    end
  end
  return false
end

local function isPost(node)
  return hasAction(node, { 'Otevřít nabídku akcí', 'Open actions menu' })
end

-- Upozornění má v českém Facebooku akci přesně "Zobrazit další možnosti"
local function isNotificationItem(node)
  if node == nil or isPost(node) then return false end
  return hasAction(node, {
    'Zobrazit další možnosti',
    'See more options',
    'Další možnosti',
    'More options',
    'Odebrat toto upozornění',
    'Remove this notification'
  })
end

local function cycle(dir, node)
  if node == nil then return false end
  local items = nil
  local kind = nil
  if isPost(node) then
    items = {}
    for _, label in ipairs(postMenuItems(postState[postKey(node)])) do
      items[#items + 1] = { label = label, rawLabel = label }
    end
    kind = 'menu'
  elseif isNotificationItem(node) then
    items = {}
    for _, label in ipairs(notificationMenuItems()) do
      items[#items + 1] = { label = label, rawLabel = label }
    end
    kind = 'notif_menu'
  else
    items = usableActions(node)
    kind = 'action'
  end
  if #items == 0 then return false end
  if selNode ~= node or selIdx == nil or selKind ~= kind then
    selIdx = (dir > 0) and 1 or #items
  else
    selIdx = selIdx + dir
    if selIdx > #items then selIdx = 1 end
    if selIdx < 1 then selIdx = #items end
  end
  selNode = node
  selKind = kind
  selLabel = items[selIdx].rawLabel or items[selIdx].label
  selId = items[selIdx].id
  sf.speak(items[selIdx].label)
  return true
end

sf.onCommand('next_action', function(event)
  local node = event.node or sf.screen.focused()
  if not cycle(1, node) then return false end
end)

sf.onCommand('prev_action', function(event)
  local node = event.node or sf.screen.focused()
  if not cycle(-1, node) then return false end
end)

local function scanMenuElements()
  local byLabel = {}
  local allEntries = {}
  local removeBtn, removeLabel = nil, nil

  local nodes = sf.screen.findAll({ clickable = true }, 80) or {}
  local buttons = sf.screen.findAll({ className = 'Button' }, 60) or {}
  for _, b in ipairs(buttons) do
    nodes[#nodes + 1] = b
  end

  for _, b in ipairs(nodes) do
    local d = nodeLabel(b)
    if d ~= '' then
      if byLabel[d] == nil then
        byLabel[d] = b
        allEntries[#allEntries + 1] = { label = d, lower = d:lower(), node = b }
      end
      if startsWith(d, 'Odebrat reakci') or startsWith(d:lower(), 'odebrat reakci') then
        removeBtn, removeLabel = b, d
      end
    end
  end
  return byLabel, allEntries, removeBtn, removeLabel
end

local function findMatchingButton(byLabel, allEntries, keywords)
  for _, kw in ipairs(keywords) do
    if byLabel[kw] ~= nil then return byLabel[kw] end
  end
  for _, kw in ipairs(keywords) do
    local kwLower = kw:lower()
    for _, entry in ipairs(allEntries) do
      if entry.lower == kwLower or entry.lower:find(kwLower, 1, true) then
        return entry.node
      end
    end
  end
  return nil
end

-- Spuštění akce z kontextového menu Upozornění přes akci "Zobrazit další možnosti"
local function runNotificationPick(notif, label)
  local opened = false
  local triggerActions = { 'Zobrazit další možnosti', 'See more options', 'Další možnosti', 'More options' }
  for _, actName in ipairs(triggerActions) do
    local ran, res = pcall(function() return notif:perform(actName) end)
    if ran and res then
      opened = true
      break
    end
  end

  if not opened then
    local menuBtn = notif:find({ contentDescription = 'Zobrazit další možnosti' })
      or notif:find({ contentDescription = 'Další možnosti' })
      or notif:find({ contentDescription = 'More options' })
    if menuBtn ~= nil and menuBtn.clickable then
      menuBtn:click()
      opened = true
    end
  end

  if not opened then
    sf.speak('Nabídku upozornění se nepodařilo otevřít')
    return
  end

  local byLabel, allEntries
  local menuReady = false
  for _ = 1, 10 do
    sf.sleep(200)
    byLabel, allEntries = scanMenuElements()
    if findMatchingButton(byLabel, allEntries, { 'Odebrat toto upozornění', 'Vypnout', 'Nahlásit', 'Zavřít', 'Odebrat' }) ~= nil then
      menuReady = true
      break
    end
  end

  if not menuReady then
    sf.speak('Nabídka se neotevřela')
    return
  end

  if label == 'Odebrat toto upozornění' then
    local b = findMatchingButton(byLabel, allEntries, { 'Odebrat toto upozornění', 'Odebrat' })
    if b ~= nil then
      b:click()
      sf.speak('Upozornění odebráno')
    else
      sf.speak('Položka není v nabídce')
    end
    return
  end

  if label == 'Vypnout upozornění' then
    local b = findMatchingButton(byLabel, allEntries, { 'Vypnout upozornění', 'Vypnout' })
    if b ~= nil then
      b:click()
      sf.speak('Upozornění vypnuto')
    else
      sf.speak('Položka není v nabídce')
    end
    return
  end

  if label == 'Nahlásit problém týmu Upozornění' then
    local b = findMatchingButton(byLabel, allEntries, { 'Nahlásit problém', 'Nahlásit' })
    if b ~= nil then b:click() else sf.speak('Položka není v nabídce') end
    return
  end
end

local function runMenuPick(post, label)
  local key = postKey(post)
  local opened = false
  local ran, res = pcall(function() return post:perform('Otevřít nabídku akcí') end)
  if ran and res then
    opened = true
  else
    local ranEn, resEn = pcall(function() return post:perform('Open actions menu') end)
    if ranEn and resEn then opened = true end
  end

  if not opened then
    sf.speak('Nabídku se nepodařilo otevřít')
    return
  end

  local byLabel, allEntries, removeBtn, removeLabel
  local menuReady = false
  for _ = 1, 10 do
    sf.sleep(200)
    byLabel, allEntries, removeBtn, removeLabel = scanMenuElements()
    if findMatchingButton(byLabel, allEntries, { 'Zavřít', 'Close', 'Sdílet', 'Okomentovat', 'Komentář', 'To se mi líbí' }) ~= nil then
      menuReady = true
      break
    end
  end

  if not menuReady then
    sf.speak('Nabídka se neotevřela')
    return
  end

  local function closeMenu()
    local c = findMatchingButton(byLabel, allEntries, { 'Zavřít', 'Close' })
    if c ~= nil then c:click() end
  end

  local function learnFromRemove()
    if removeLabel and removeLabel:lower():find('to se mi líbí', 1, true) then
      postState[key] = 'like'
    else
      postState[key] = 'other'
    end
  end

  if label == 'To se mi líbí' then
    local likeBtn = findMatchingButton(byLabel, allEntries, { 'To se mi líbí' })
    if likeBtn ~= nil and (removeBtn == nil or likeBtn ~= removeBtn) then
      likeBtn:click()
      postState[key] = 'like'
      sf.speak('To se mi líbí přidáno')
    elseif removeBtn ~= nil then
      learnFromRemove()
      closeMenu()
      sf.speak('Již jste zareagovali')
    else
      sf.speak('Položka není v nabídce')
    end
    return
  end

  if label == 'Odebrat reakci To se mi líbí' or label == 'Odebrat reakci' then
    if removeBtn ~= nil then
      removeBtn:click()
      postState[key] = nil
      sf.speak('Reakce odebrána')
    elseif findMatchingButton(byLabel, allEntries, { 'To se mi líbí' }) ~= nil then
      postState[key] = nil
      closeMenu()
      sf.speak('Zatím bez reakce')
    else
      sf.speak('Položka není v nabídce')
    end
    return
  end

  if label == 'Zareagovat' or label == 'Změnit reakci' then
    local b = findMatchingButton(byLabel, allEntries, { 'Zareagovat', 'Změnit reakci', 'Reagovat' })
    if b ~= nil then
      b:click()
      if postState[key] == nil then postState[key] = 'other' end
      if label == 'Změnit reakci' then postState[key] = 'other' end
    else
      sf.speak('Položka není v nabídce')
    end
    return
  end

  if label == 'Okomentovat' then
    local b = findMatchingButton(byLabel, allEntries, { 'Okomentovat', 'Komentář', 'Přidat komentář' })
    if b ~= nil then b:click() else sf.speak('Položka není v nabídce') end
    return
  end

  if label == 'Sdílet' then
    local b = findMatchingButton(byLabel, allEntries, { 'Sdílet' })
    if b ~= nil then b:click() else sf.speak('Položka není v nabídce') end
    return
  end

  if label == 'Zobrazit další možnosti pro tento příspěvek' then
    local b = findMatchingButton(byLabel, allEntries, { 'Zobrazit další možnosti', 'Další možnosti' })
    if b ~= nil then b:click() else sf.speak('Položka není v nabídce') end
    return
  end

  if label == 'Získat podrobné popisy obrázků' then
    local b = findMatchingButton(byLabel, allEntries, { 'podrobné popisy obrázků', 'popis obrázku', 'popisy obrázků' })
    if b ~= nil then b:click() else sf.speak('Položka není v nabídce') end
    return
  end

  local b = findMatchingButton(byLabel, allEntries, { label })
  if b ~= nil then
    b:click()
  else
    sf.speak('Položka není v nabídce')
  end
end

sf.onCommand('run_action', function(event)
  local node = event.node or sf.screen.focused()
  if selNode == nil or selLabel == nil or node == nil or node ~= selNode then
    return false
  end
  local fresh = node:refresh()
  if fresh == nil then
    clearSelection()
    return false
  end
  local label, id, kind = selLabel, selId, selKind
  clearSelection()
  if kind == 'menu' then
    runMenuPick(fresh, label)
    return true
  elseif kind == 'notif_menu' then
    runNotificationPick(fresh, label)
    return true
  end
  local ok = false
  local ran, res = pcall(function() return fresh:perform(label) end)
  if ran and res then ok = true end
  if not ok and id ~= nil then
    local ran2, res2 = pcall(function() return fresh:perform(id) end)
    if ran2 and res2 then ok = true end
  end
  if not ok then sf.speak('Akci se nepodařilo spustit') end
  return true
end)

sf.onFocus(function(item)
  if selNode ~= nil and item ~= nil and item ~= selNode then
    clearSelection()
  end
end)

-- ---------------------------------------------------------------------------
-- Část 2: Přeskakování sekcí (Příběhy, Reels, Lidé, které možná znáte)
-- ---------------------------------------------------------------------------

local function feedList()
  local lists = sf.screen.findAll({ className = 'RecyclerView' }, 50) or {}
  for _, l in ipairs(lists) do
    local nested = false
    local p = l:parent()
    local guard = 0
    while p ~= nil and guard < 40 do
      if endsWith(p.className or '', 'RecyclerView') then
        nested = true
        break
      end
      p = p:parent()
      guard = guard + 1
    end
    if not nested then return l end
  end
  return nil
end

local function containsList(node, depth)
  if depth > 6 then return false end
  local kids = node:children() or {}
  for _, k in ipairs(kids) do
    local cn = k.className or ''
    if endsWith(cn, 'RecyclerView') or endsWith(cn, 'ListView') then
      return true
    end
    if containsList(k, depth + 1) then return true end
  end
  return false
end

local SECTION_WORDS = {
  'příběhy',
  'lidé, které možná znáte',
  'koho možná znáte',
  'reels',
  'story tray',
  'people you may know'
}

local function isSection(child)
  if containsList(child, 0) then return true end
  local d = child.contentDescription
  if d ~= nil then
    local lower = d:lower()
    for _, w in ipairs(SECTION_WORDS) do
      if lower:find(w, 1, true) then return true end
    end
  end
  return false
end

local function postTarget(node, depth)
  if depth > 6 then return nil end
  if node.focusable and containsText(node) then return node end
  local kids = node:children() or {}
  for _, k in ipairs(kids) do
    local t = postTarget(k, depth + 1)
    if t ~= nil then return t end
  end
  return nil
end

local function focusPostBelow(kids, fromIdx)
  for i = fromIdx, #kids do
    local k = kids[i]
    if not isSection(k) then
      local t = postTarget(k, 0)
      if t ~= nil then
        t:focus()
        return true
      end
    end
  end
  return false
end

local function scanPostBelow(minTop)
  local items = sf.screen.findAll({ focusable = true }, 200) or {}
  local best, bestTop = nil, nil
  for _, p in ipairs(items) do
    if isPost(p) and p.bounds ~= nil and p.bounds.top ~= nil then
      local top = p.bounds.top
      local bottom = p.bounds.bottom or top
      if bottom > 0 and (minTop == nil or top >= minTop - 4) then
        if bestTop == nil or top < bestTop then
          best, bestTop = p, top
        end
      end
    end
  end
  if best ~= nil then
    best:focus()
    return true
  end
  return false
end

local function touchScrollSmall()
  local root = sf.screen.root()
  local b = root ~= nil and root.bounds or nil
  local cx, y1, y2 = 500, 900, 650
  if b ~= nil and b.right ~= nil and b.bottom ~= nil then
    local h = (b.bottom or 0) - (b.top or 0)
    cx = math.floor(((b.left or 0) + b.right) / 2)
    y1 = math.floor((b.top or 0) + h * 0.60)
    y2 = math.floor((b.top or 0) + h * 0.44)
  end
  pcall(function() return sf.touch.swipe(cx, y1, cx, y2, 250) end)
end

local function landAfterScroll()
  local list2 = feedList()
  if list2 == nil then return false end
  local kids2 = list2:children() or {}
  local secIdx2, secBottom = nil, nil
  for i, k in ipairs(kids2) do
    if isSection(k) then
      secIdx2 = i
      if k.bounds ~= nil then secBottom = k.bounds.bottom end
      break
    end
  end
  if secIdx2 ~= nil then
    if focusPostBelow(kids2, secIdx2 + 1) then return true end
    return scanPostBelow(secBottom)
  end
  for _, k in ipairs(kids2) do
    if not isSection(k) then
      local onScreen = true
      if k.bounds ~= nil then
        if k.bounds.bottom ~= nil and k.bounds.bottom <= 0 then onScreen = false end
        if k.bounds.top ~= nil and k.bounds.top < 0 then onScreen = false end
      end
      if onScreen then
        local t = postTarget(k, 0)
        if t ~= nil then
          t:focus()
          return true
        end
      end
    end
  end
  return false
end

sf.onCommand('skip_section', function(event)
  local node = event.node or sf.screen.focused()
  if node == nil then return end
  local list = feedList()
  if list == nil then return end
  local kids = list:children() or {}
  local curIdx = nil
  for i, k in ipairs(kids) do
    if node == k or isInside(node, k) then
      curIdx = i
      break
    end
  end
  if curIdx == nil then return end
  if not isSection(kids[curIdx]) then return end
  if focusPostBelow(kids, curIdx + 1) then return end
  local secBottom = nil
  if kids[curIdx].bounds ~= nil then secBottom = kids[curIdx].bounds.bottom end
  if scanPostBelow(secBottom) then return end
  for _ = 1, 4 do
    touchScrollSmall()
    sf.sleep(350)
    if landAfterScroll() then return end
  end
  sf.speak('Níže není žádný příspěvek')
end)