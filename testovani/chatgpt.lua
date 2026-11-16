local manifest = {
  id = 'chatgpt',
  name = 'ChatGPT: zprávy jako jedna položka',
  version = '0.0.2',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'V konverzaci ChatGPT je každá zpráva jedna položka a přečte se celá, i ta část, která není na obrazovce. Tlačítka pod odpovědí (Kopírovat, Přečíst nahlas, Sdílet, hodnocení, Zdroje, Další akce) se při švihání přeskakují a jsou v nabídce Akce, spolu se Zobrazit celou zprávu: okno, ve kterém jde text číst po řádcích, slovech i znacích. Ostatní ovládání aplikace zůstává. Testovací verze.',
  apps = { 'com.openai.chatgpt' },
  permissions = { 'screen', 'speech', 'input', 'actions', 'dialogs' },
  settings = {
    { key = 'readFull', type = 'switch', title = 'Číst celou odpověď', summary = 'Vypnuté: při zaměření se přečte jen první odstavec, celá odpověď je v nabídce Akce.', default = true },
    { key = 'markYou', type = 'switch', title = 'Před vaše zprávy říkat „Vy“', default = true },
  },
  commands = {
    { id = 'last', title = 'Zobrazit poslední zprávu', menu = true },
  },
  rules = {
    -- Text odpovědi: odstavce, seznamy a tabulky jsou jedna položka.
    {
      match = { focusable = true, clickable = false, has = { className = 'TextView' }, inside = { scrollable = true } },
      group = true,
    },
    -- Tlačítka pod odpovědí se při švihání přeskakují, jsou v nabídce Akce.
    { match = { clickable = true, has = { contentDescription = 'Kopírovat' }, inside = { scrollable = true } }, hide = 'all' },
    { match = { clickable = true, has = { contentDescription = 'Dobrá odpověď' }, inside = { scrollable = true } }, hide = 'all' },
    { match = { clickable = true, has = { contentDescription = 'Špatná odpověď' }, inside = { scrollable = true } }, hide = 'all' },
    { match = { clickable = true, has = { contentDescription = 'Přečíst nahlas' }, inside = { scrollable = true } }, hide = 'all' },
    { match = { clickable = true, has = { contentDescription = 'Sdílet' }, inside = { scrollable = true } }, hide = 'all' },
    { match = { clickable = true, has = { contentDescription = 'Další akce' }, inside = { scrollable = true } }, hide = 'all' },
    { match = { clickable = true, has = { text = 'Zdroje' }, inside = { scrollable = true } }, hide = 'all' },
  },
}

local TITLE = 'Zpráva ChatGPT'

-- Tlačítka pod odpovědí: název akce a popisek nebo text tlačítka v aplikaci.
local BUTTONS = {
  { title = 'Kopírovat', query = { contentDescription = 'Kopírovat' } },
  { title = 'Přečíst nahlas', query = { contentDescription = 'Přečíst nahlas' } },
  { title = 'Sdílet', query = { contentDescription = 'Sdílet' } },
  { title = 'Zdroje', query = { text = 'Zdroje' } },
  { title = 'Dobrá odpověď', query = { contentDescription = 'Dobrá odpověď' } },
  { title = 'Špatná odpověď', query = { contentDescription = 'Špatná odpověď' } },
  { title = 'Další akce', query = { contentDescription = 'Další akce' } },
}

local function present(text)
  if text ~= nil and text ~= '' then
    return text
  end
end

local function trim(text)
  return ((text or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function short_class(item)
  return (item.className or ''):match('[^.]*$')
end

-- Odkazy v textu končí neviditelnými znaky (spojovač slov a zástupný znak za ikonu).
local function clean(text)
  return trim((text or ''):gsub('\u{2060}', ''):gsub('\u{FFFC}', ''))
end

local function length(text)
  return utf8.len(text) or #text
end

-- Zpráva je položka přímo v posouvatelném seznamu konverzace. Hledá se od zaměřené položky nahoru.
local function row_of(item)
  local current = item
  for _ = 1, 40 do
    local parent = current:parent()
    if parent == nil then
      return nil
    end
    if parent.scrollable then
      return current
    end
    current = parent
  end
end

-- Texty zprávy v pořadí. Tlačítka pod odpovědí a odkazy na zdroje se vynechají.
local function collect(node, out, state, list)
  for _, child in ipairs(node:children() or {}) do
    local class = short_class(child)
    if (child.clickable and not child.longClickable) or class == 'Button' then
      -- Tlačítko.
    elseif class == 'TextView' then
      local text = clean(present(child.text) or child.contentDescription)
      if text ~= '' then
        out[#out + 1] = { text = text, list = list }
      end
    elseif class == 'ListView' then
      state.lists = state.lists + 1
      collect(child, out, state, state.lists)
    else
      collect(child, out, state, list)
    end
  end
  return out
end

-- Krátký text bez interpunkce na konci je nejspíš buňka tabulky.
local function is_cell(text)
  return length(text) <= 25 and not text:find('[:.!?]$')
end

-- Tabulka přijde jako řada buněk za sebou. Počet sloupců je největší dělitel, při kterém
-- v prvním řádku (záhlaví) nejsou čísla.
local function table_text(cells)
  local count = #cells
  for columns = 6, 2, -1 do
    if count % columns == 0 and count // columns >= 2 then
      local header_ok = true
      for i = 1, columns do
        if cells[i]:find('%d') then
          header_ok = false
        end
      end
      if header_ok then
        local lines = {}
        for first = 1, count, columns do
          lines[#lines + 1] = table.concat(cells, ', ', first, first + columns - 1)
        end
        return table.concat(lines, '\n')
      end
    end
  end
  return table.concat(cells, ', ')
end

-- Odstavce zprávy. Body seznamu jsou jeden odstavec po řádcích, číslo bodu je u jeho textu.
local function paragraphs(entries)
  local blocks = {}
  local i = 1
  while i <= #entries do
    local entry = entries[i]
    if entry.list then
      local lines = {}
      while i <= #entries and entries[i].list == entry.list do
        local text = entries[i].text
        local nxt = entries[i + 1]
        if text:find('^%d+[.)]$') and nxt and nxt.list == entry.list then
          lines[#lines + 1] = text .. ' ' .. nxt.text
          i = i + 2
        else
          lines[#lines + 1] = '• ' .. text
          i = i + 1
        end
      end
      blocks[#blocks + 1] = table.concat(lines, '\n')
    elseif is_cell(entry.text) then
      local cells = {}
      while i <= #entries and not entries[i].list and is_cell(entries[i].text) do
        cells[#cells + 1] = entries[i].text
        i = i + 1
      end
      if #cells >= 6 then
        blocks[#blocks + 1] = table_text(cells)
      else
        for _, cell in ipairs(cells) do
          blocks[#blocks + 1] = cell
        end
      end
    else
      blocks[#blocks + 1] = entry.text
      i = i + 1
    end
  end
  return blocks
end

local function blocks_of(node)
  return paragraphs(collect(node, {}, { lists = 0 }))
end

-- Vaše zpráva je bublina, na kterou jde klepnout i dlouze. Text odpovědi na klepnutí nereaguje.
local function is_user(item)
  return item.clickable and item.longClickable
end

local last_item, last_text

local function speak_once(item, text)
  if not present(text) or (last_item ~= nil and item == last_item and text == last_text) then
    return
  end
  last_item, last_text = item, text
  sf.speak(text, { interrupt = true })
end

local function say(item, fallback)
  local row = row_of(item)
  if row == nil then
    speak_once(item, fallback)
    return
  end
  local blocks = blocks_of(item)
  if #blocks == 0 then
    speak_once(item, fallback)
    return
  end
  local text
  if is_user(item) then
    text = table.concat(blocks, '\n')
    if sf.settings.get('markYou') ~= false then
      text = 'Vy: ' .. text
    end
  elseif sf.settings.get('readFull') == false and #blocks > 1 then
    text = blocks[1] .. '\n…'
  else
    text = table.concat(blocks, '\n')
  end
  speak_once(item, text)
end

sf.onFocus(function(item, text)
  if short_class(item) == 'View' and item.focusable and (item.childCount or 0) > 0
    and (is_user(item) or not item.clickable) then
    sf.setTimeout(say, 0, item, text)
    return false
  end
  last_item, last_text = nil, nil
end)

local function full_text(item)
  local message = row_of(item) and item
  return message and table.concat(blocks_of(message), '\n\n') or ''
end

local function show(item)
  local text = full_text(item)
  if text == '' then
    sf.speak('Tady není text zprávy', { interrupt = true })
    return
  end
  sf.ui.text(TITLE, text)
end

local function read(item)
  local text = full_text(item)
  if text == '' then
    sf.speak('Tady není text zprávy', { interrupt = true })
    return
  end
  sf.speak(text, { interrupt = true })
end

local function press(item, query)
  local row = row_of(item)
  local found = row and row:find(query)
  if found == nil then
    sf.speak('Tlačítko tu není', { interrupt = true })
    return
  end
  local target = found
  if not target.clickable then
    target = found:parent() or found
  end
  target:click()
end

sf.onActions(function(item)
  if short_class(item) ~= 'View' or not item.focusable or (item.childCount or 0) == 0 then
    return
  end
  local actions = {
    { title = 'Zobrazit celou zprávu', first = true, run = show },
    { title = 'Přečíst celou zprávu', run = read },
  }
  if not item.clickable then
    for _, button in ipairs(BUTTONS) do
      actions[#actions + 1] = {
        title = button.title,
        run = function(target)
          press(target, button.query)
        end,
      }
    end
  end
  return actions
end)

-- Poslední zpráva v seznamu konverzace, která má text.
sf.onCommand('last', function()
  local list = sf.screen.find({ scrollable = true })
  if list == nil then
    sf.speak('Konverzace tu není', { interrupt = true })
    return
  end
  local rows = list:children() or {}
  for i = #rows, 1, -1 do
    local blocks = blocks_of(rows[i])
    if #blocks > 0 then
      sf.ui.text(TITLE, table.concat(blocks, '\n\n'))
      return
    end
  end
  sf.speak('Konverzace je prázdná', { interrupt = true })
end)
