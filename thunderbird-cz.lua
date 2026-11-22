-- Thunderbird Klávesy a akce pro SandFly (script API v2+) - Český port v1.5.1-cz
-- Stabilní verze: 100% nativní pohyb po seznamu zpráv (bez zmlknutí hlasu),
-- funkční přepínání hvězdičky přímo v řádku, akce šviháním nahoru/dolů a klávesové zkratky.

local manifest = {
  id = 'thunderbird-keys-actions-cz',
  name = 'Thunderbird – Klávesy a akce (CZ)',
  version = '1.5.1-cz',
  author = 'Tomáš Hromádka (česká úprava skriptu Thunderbird Keys and Actions, autor Atlas)',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  description = 'Klávesové zkratky z počítačového Thunderbirdu a akce na zprávách šviháním nahoru/dolů s plynulou nativní navigací.',
  minApiVersion = 2,
  testedApiVersion = 3,
  apps = { 'net.thunderbird.android' },
  permissions = { 'screen', 'actions', 'input', 'speech' },
  commands = {
    { id = 'next_action', title = 'Další akce', gesture = 'swipeDown' },
    { id = 'prev_action', title = 'Předchozí akce', gesture = 'swipeUp' },
    { id = 'run_action', title = 'Provést vybranou akci', gesture = 'doubleTap' },
    { id = 'compose_new', title = 'Nová zpráva', keys = 'ctrl+n' },
    { id = 'reply', title = 'Odpovědět', keys = 'ctrl+r' },
    { id = 'reply_all', title = 'Odpovědět všem', keys = 'ctrl+shift+r' },
    { id = 'forward', title = 'Přeposlat', keys = 'ctrl+l' },
    { id = 'delete_key', title = 'Smazat zprávu nebo výběr', keys = 'delete' },
    { id = 'toggle_select', title = 'Přepnout výběr', keys = 'space' },
    { id = 'jump', title = 'Skočit mezi hlavičkou a tělem / lištou', keys = 'sf+j' },
    { id = 'send', title = 'Odeslat', keys = 'sf+enter' },
    { id = 'send_ctrl', title = 'Odeslat (Ctrl+Enter)', keys = 'ctrl+enter' },
  },
}

local PKG = 'net.thunderbird.android'
local ID = PKG .. ':id/'

-- ----------------------------------------------------------------
-- Pomocné funkce
-- ----------------------------------------------------------------

local function label(item)
  if not item then return '' end
  local d = item.contentDescription
  if d and d ~= '' then return d end
  return item.text or ''
end

local function isInside(inner, outer)
  if not inner or not outer or not inner.bounds or not outer.bounds then
    return false
  end
  local cx = (inner.bounds.left + inner.bounds.right) / 2
  local cy = (inner.bounds.top + inner.bounds.bottom) / 2
  return cx >= outer.bounds.left and cx <= outer.bounds.right
     and cy >= outer.bounds.top and cy <= outer.bounds.bottom
end

local function findId(short)
  return sf.screen.find({ id = ID .. short })
end

local function activityName()
  local ok, app = pcall(sf.app)
  if ok and app and app.activity then return app.activity end
  return ''
end

local function inCompose()
  if activityName():find('MessageCompose', 1, true) then return true end
  return findId('send') ~= nil and findId('message_content') ~= nil
end

local function inMessageView()
  return findId('menu_primary_action') ~= nil and findId('message_list') == nil
end

local function messageList()
  return sf.screen.find({ id = ID .. 'message_list' })
      or sf.screen.find({ className = 'RecyclerView' })
end

local function selectionActive()
  return sf.screen.find({ id = ID .. 'action_mode_bar' }) ~= nil
      or sf.screen.find({ id = ID .. 'action_bar_title' }) ~= nil
end

-- ----------------------------------------------------------------
-- Řádky seznamu zpráv
-- ----------------------------------------------------------------

local function selectArea(row)
  if not row then return nil end
  return row:find({ id = ID .. 'contact_picture_click_area' })
end

local function findRowContainer(node, list)
  local cur = node
  for _ = 1, 6 do
    if not cur then return nil end
    local p = cur:parent()
    if not p then return nil end
    if p == list or (p.id and p.id:find('message_list', 1, true)) or p.className == 'RecyclerView' then
      return cur
    end
    cur = p
  end
  return nil
end

local function listRows()
  local list = messageList()
  if not list then return nil, nil end

  local rows = {}
  local seenBounds = {}

  local kids = list:children() or {}
  for _, k in ipairs(kids) do
    if k.visible and k.bounds and (selectArea(k) or k:find({ id = ID .. 'subject' })) then
      local key = tostring(k.bounds.top) .. ':' .. tostring(k.bounds.bottom)
      if not seenBounds[key] then
        seenBounds[key] = true
        rows[#rows + 1] = k
      end
    end
  end

  if #rows == 0 then
    local subjects = list:findAll({ id = ID .. 'subject' }, 40) or {}
    for _, s in ipairs(subjects) do
      local container = findRowContainer(s, list) or s:parent()
      if container and container.visible and container.bounds then
        local key = tostring(container.bounds.top) .. ':' .. tostring(container.bounds.bottom)
        if not seenBounds[key] then
          seenBounds[key] = true
          rows[#rows + 1] = container
        end
      end
    end
  end

  table.sort(rows, function(a, b)
    return (a.bounds and a.bounds.top or 0) < (b.bounds and b.bounds.top or 0)
  end)

  return rows, list
end

local function rowKey(row)
  local subj = row:find({ id = ID .. 'subject' })
  local date = row:find({ id = ID .. 'date' })
  local who = subj and (subj.contentDescription or subj.text or '') or ''
  local when = date and (date.text or '') or ''
  if who ~= '' or when ~= '' then
    return who .. '|' .. when
  end
  if row.bounds then
    return tostring(row.bounds.top) .. '|' .. tostring(row.bounds.bottom)
  end
  return tostring(row)
end

local function rowUnread(row)
  local subj = row:find({ id = ID .. 'subject' })
  local d = (subj and subj.contentDescription or ''):lower()
  return d:find('nepřečten', 1, true) ~= nil
      or d:sub(1, 7) == 'unread,'
end

local function rowSelected(row)
  local area = selectArea(row)
  if not area then return false end
  local lbl = label(area):lower()
  return lbl:find('zrušit výběr', 1, true) ~= nil
      or lbl:find('odebrat z výběru', 1, true) ~= nil
      or lbl == 'deselect'
end

local function focusedRow()
  local f = sf.screen.focused()
  if not f then return nil end
  local rows = listRows()
  if not rows then return nil end
  for _, r in ipairs(rows) do
    if f == r or isInside(f, r) then return r end
  end
  return nil
end

local function focusablePartOf(row)
  if not row then return nil end
  if row.focusable then return row end
  local subj = row:find({ id = ID .. 'subject' })
  if subj and subj.focusable then return subj end
  local all = row:findAll({ focusable = true }, 10) or {}
  for _, item in ipairs(all) do
    local id = item.id or ''
    if id ~= ID .. 'contact_picture_click_area'
      and id ~= ID .. 'star'
      and id ~= ID .. 'flagged' then
      return item
    end
  end
  return row
end

-- Najde přímo tlačítko hvězdičky uvnitř řádku e-mailu a přepne ho
local function toggleRowStar(row)
  if not row then return false end
  local starBtn = row:find({ id = ID .. 'star' })
    or row:find({ id = ID .. 'flagged' })
    or row:find({ contentDescriptionContains = 'hvězdičk' })
    or row:find({ contentDescriptionContains = 'Přidat *' })
    or row:find({ contentDescriptionContains = 'Odebrat *' })
    or row:find({ contentDescriptionContains = 'star' })

  if not starBtn then
    sf.speak('Tlačítko hvězdičky nenalezeno')
    return true
  end

  local before = label(starBtn):lower()
  starBtn:click()
  sf.sleep(250)

  if before:find('odebrat', 1, true) or before:find('remove', 1, true) then
    sf.speak('Hvězdička odebrána')
  else
    sf.speak('Hvězdička přidána')
  end
  return true
end

local function toggleRowSelection(row)
  local area = selectArea(row)
  if not area then return false end
  local key = rowKey(row)
  area:click()
  sf.sleep(300)
  local f = sf.screen.focused()
  local stillThere = false
  if f then
    local rows = listRows()
    if rows then
      for _, r in ipairs(rows) do
        if rowKey(r) == key and (f == r or isInside(f, r)) then
          stillThere = true
          break
        end
      end
    end
  end
  local rows = listRows()
  if rows then
    for _, r in ipairs(rows) do
      if rowKey(r) == key then
        if not stillThere then
          local target = focusablePartOf(r)
          if target then target:focus() end
        else
          sf.speak(rowSelected(r) and 'Vybráno' or 'Výběr zrušen')
        end
        return true
      end
    end
  end
  return true
end

-- ----------------------------------------------------------------
-- Akce na řádku: výběr šviháním nahoru/dolů a spuštění poklepáním
-- ----------------------------------------------------------------

local pending = nil -- { key=..., idx=..., labels={...} }

sf.onFocus(function(item)
  if pending and item then
    local r = nil
    local rows = listRows()
    if rows then
      for _, cand in ipairs(rows) do
        if item == cand or isInside(item, cand) then r = cand break end
      end
    end
    if r and rowKey(r) ~= pending.key then pending = nil end
    if not r and inMessageView() then pending = nil end
  end
end)

local function actionLabels(row)
  local labels = {}
  labels[#labels + 1] = rowSelected(row) and 'Zrušit výběr' or 'Vybrat'
  labels[#labels + 1] = 'Odpovědět'
  labels[#labels + 1] = 'Odpovědět všem'
  labels[#labels + 1] = 'Přeposlat'
  labels[#labels + 1] = 'Smazat'
  labels[#labels + 1] = rowUnread(row) and 'Označit jako přečtené' or 'Označit jako nepřečtené'
  labels[#labels + 1] = 'Přepnout hvězdičku'
  return labels
end

local function cycleAction(dir)
  if inCompose() or inMessageView() then return false end
  local row = focusedRow()
  if not row then return false end
  local key = rowKey(row)
  local labels = actionLabels(row)
  if not pending or pending.key ~= key then
    pending = { key = key, idx = dir > 0 and 1 or #labels, labels = labels }
  else
    pending.labels = labels
    pending.idx = pending.idx + dir
    if pending.idx > #labels then pending.idx = 1 end
    if pending.idx < 1 then pending.idx = #labels end
  end
  sf.speak(labels[pending.idx])
  return true
end

local function tapMenuItem(candidates, timeout)
  if type(candidates) == 'string' then
    candidates = { candidates }
  end
  local deadline = timeout or 2000
  local step = 100
  local elapsed = 0
  while elapsed <= deadline do
    for _, text in ipairs(candidates) do
      local t = sf.screen.find({ text = text })
      if t then
        local p = t:parent()
        if p then p:click() else t:click() end
        return true
      end
    end
    sf.sleep(step)
    elapsed = elapsed + step
  end
  return false
end

local function menuCandidatesFor(what)
  if what == 'Odpovědět všem' then
    return { 'Odpovědět všem', 'Reply all' }
  elseif what == 'Přeposlat' then
    return { 'Přeposlat', 'Forward' }
  end
  return { what }
end

local function overflowAction(what)
  local ov = findId('menu_overflow')
  if not ov then return false end
  ov:click()
  return tapMenuItem(menuCandidatesFor(what), 2000)
end

local function openThen(row, what)
  local clickable = focusablePartOf(row) or row
  clickable:click()
  if what == 'Odpovědět' then
    local b = sf.screen.waitFor({ id = ID .. 'menu_primary_action' }, 2500, 100)
    if not b then return false end
    b:click()
    return true
  end
  local ov = sf.screen.waitFor({ id = ID .. 'menu_overflow' }, 2500, 100)
  if not ov then return false end
  ov:click()
  return tapMenuItem(menuCandidatesFor(what), 2000)
end

local function barAction(row, barId)
  if selectionActive() then
    if not rowSelected(row) then
      sf.speak('Je aktivní režim výběru')
      return true
    end
  else
    local area = selectArea(row)
    if not area then return false end
    area:click()
  end
  local b = sf.screen.waitFor({ id = ID .. barId }, 2000, 100)
  if not b then
    sf.speak('Není k dispozici')
    return true
  end
  b:click()
  return true
end

local function runAction()
  if inCompose() or inMessageView() then return false end
  local row = focusedRow()
  if not row then return false end
  if selectionActive() and not (pending and pending.key == rowKey(row)) then
    return toggleRowSelection(row)
  end
  if not pending or pending.key ~= rowKey(row) then
    return false
  end
  local pick = pending.labels[pending.idx]
  pending = nil
  if pick == 'Vybrat' or pick == 'Zrušit výběr' then
    return toggleRowSelection(row)
  elseif pick == 'Odpovědět' or pick == 'Odpovědět všem' or pick == 'Přeposlat' then
    if not openThen(row, pick) then sf.speak('Nepodařilo se otevřít zprávu') end
    return true
  elseif pick == 'Smazat' then
    return barAction(row, 'delete')
  elseif pick == 'Označit jako přečtené' or pick == 'Označit jako nepřečtené' then
    return barAction(row, 'mark_as_read')
  elseif pick == 'Přepnout hvězdičku' then
    return toggleRowStar(row)
  end
  return true
end

-- ----------------------------------------------------------------
-- Klávesové příkazy
-- ----------------------------------------------------------------

local function doComposeNew()
  if inCompose() then return false end
  local descs = { 'Napsat', 'Nová zpráva', 'Vytvořit zprávu', 'Compose' }
  for _, desc in ipairs(descs) do
    local btns = sf.screen.findAll({ contentDescription = desc, clickable = true }, 5)
    for _, b in ipairs(btns or {}) do
      b:click()
      return true
    end
  end
  return false
end

local function doReplyLike(what)
  if inCompose() then return false end
  if inMessageView() then
    if what == 'Odpovědět' then
      local b = findId('menu_primary_action')
      if not b then return false end
      b:click()
      return true
    end
    return overflowAction(what)
  end
  local row = focusedRow()
  if not row then return false end
  if not openThen(row, what) then sf.speak('Nepodařilo se otevřít zprávu') end
  return true
end

local function doDeleteKey()
  if inCompose() then return false end
  if inMessageView() then
    local b = findId('delete')
    if not b then return false end
    b:click()
    return true
  end
  if selectionActive() then
    local b = findId('delete')
    if not b then return false end
    b:click()
    return true
  end
  local row = focusedRow()
  if not row then return false end
  return barAction(row, 'delete')
end

local function doToggleSelectKey()
  local row = focusedRow()
  if not row then return false end
  return toggleRowSelection(row)
end

local function doJump()
  if inCompose() then return false end
  if inMessageView() then
    local f = sf.screen.focused()
    local inBody = false
    if f then
      if (f.className or ''):find('WebView', 1, true) then
        inBody = true
      else
        local wvs = sf.screen.findAll({ className = 'WebView' }, 10) or {}
        for _, wv in ipairs(wvs) do
          if isInside(f, wv) then inBody = true break end
        end
      end
    end
    if inBody then
      local subj = findId('subject')
      if subj then subj:focus() return true end
      local pc = findId('participants_container')
      if pc then pc:focus() return true end
      return false
    end
    local wvs = sf.screen.findAll({ className = 'WebView' }, 10) or {}
    local best, bestArea = nil, -1
    for _, wv in ipairs(wvs) do
      if wv.focusable and wv.bounds then
        local area = (wv.bounds.right - wv.bounds.left) * (wv.bounds.bottom - wv.bounds.top)
        if area > bestArea then best, bestArea = wv, area end
      end
    end
    if best then best:focus() return true end
    local heads = sf.screen.findAll({ heading = true }, 20) or {}
    for _, h in ipairs(heads) do
      for _, wv in ipairs(wvs) do
        if isInside(h, wv) then h:focus() return true end
      end
    end
    return false
  end
  local rows = listRows()
  if not rows or #rows == 0 then return false end
  if focusedRow() then
    local navDescs = { 'Přejít nahoru', 'Otevřít navigační panel', 'Navigate up' }
    for _, desc in ipairs(navDescs) do
      local nav = sf.screen.find({ contentDescription = desc, clickable = true })
      if nav then nav:focus() return true end
    end
    local compDescs = { 'Napsat', 'Nová zpráva', 'Compose' }
    for _, desc in ipairs(compDescs) do
      local comp = sf.screen.find({ contentDescription = desc, clickable = true })
      if comp then comp:focus() return true end
    end
    return false
  end
  local first = focusablePartOf(rows[1])
  if first then first:focus() return true end
  return false
end

local function doSend()
  if not inCompose() then return false end
  local b = findId('send')
  if not b then
    sf.speak('Tlačítko odeslat nenalezeno')
    return true
  end
  if b.enabled == false then
    sf.speak('Není co odeslat')
    return true
  end
  b:click()
  return true
end

-- ----------------------------------------------------------------
-- Propojení příkazů
-- ----------------------------------------------------------------

sf.onCommand('next_action', function(event) return cycleAction(1) end)
sf.onCommand('prev_action', function(event) return cycleAction(-1) end)
sf.onCommand('run_action', function(event) return runAction() end)
sf.onCommand('compose_new', function(event) return doComposeNew() end)
sf.onCommand('reply', function(event) return doReplyLike('Odpovědět') end)
sf.onCommand('reply_all', function(event) return doReplyLike('Odpovědět všem') end)
sf.onCommand('forward', function(event) return doReplyLike('Přeposlat') end)
sf.onCommand('delete_key', function(event) return doDeleteKey() end)
sf.onCommand('toggle_select', function(event) return doToggleSelectKey() end)
sf.onCommand('jump', function(event) return doJump() end)
sf.onCommand('send', function(event) return doSend() end)
sf.onCommand('send_ctrl', function(event) return doSend() end)

return manifest