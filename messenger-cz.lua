local manifest = {
  id = 'messenger-fix-cz',
  name = 'Messenger: zprávy jako jedna položka',
  version = '5.0',
  author = 'Jan Balák (podle skriptu Tomáše Hromádky)',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'V konverzaci Messengeru je každá zpráva jedna položka: kdo ji poslal (Vy nebo jméno), text, fotka, samolepka nebo odkaz, čas a jestli ji druhý viděl. Švihání zůstává jako v SandFly, avatary, časy a tlačítka u zprávy se přeskakují. Ovládací prvek čtení Zprávy přechází po zprávách a konverzaci sám posouvá. Akce u zprávy: Zobrazit celou zprávu, Možnosti zprávy (odpovědět, reagovat, kopírovat…), Přeposlat, To se mi líbí, Přidat reakci, Otevřít profil, u fotky Popsat obrázek a Rozpoznat text na obrázku. Příkaz Přejít do pole pro psaní je v SandFly menu a na SandFly+J.',
  apps = { 'com.facebook.orca' },
  permissions = { 'screen', 'speech', 'input', 'actions', 'dialogs' },
  settings = {
    { key = 'readTime', type = 'switch', title = 'Číst čas zprávy', default = true },
    { key = 'readSeen', type = 'switch', title = 'Číst, že druhý zprávu viděl', default = true },
  },
  commands = {
    { id = 'message', title = 'Zprávy', control = true },
    { id = 'compose', title = 'Přejít do pole pro psaní', menu = true, keys = 'sf+j' },
  },
  rules = {
    -- Bublina zprávy je jedna položka; skript k ní přidá autora, čas a „zobrazeno“. Poklepání
    -- udělá totéž co klepnutí na bublinu (otevře fotku nebo odkaz, u textu ukáže datum).
    {
      match = { longClickable = true, focusable = true, inside = { className = 'view.View', focusable = true } },
      group = true,
      activate = { clickable = true },
    },
    -- Ostatní části řádku se přeskakují, jsou ve zprávě nebo v nabídce Akce.
    { match = { textContains = 'Otevřít profil', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { textContains = 'Přeposlání', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { textContains = 'Zobrazeno', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { contentDescription = 'Přidat vlastní reakci' }, hide = true },
    { match = { textContains = 'Poklepáním dáte To se mi líbí' }, hide = true },
    -- Datum a čas mezi zprávami („PO V 17:48“, „10:52“).
    { match = { textContains = ':', clickable = false, focusable = false, inside = { className = 'view.View', focusable = true } }, hide = true },
    -- Oddíl Právě aktivní v seznamu chatů.
    { match = { text = 'Právě aktivní', clickable = false }, hide = true },
    { match = { text = 'Active now', clickable = false }, hide = true },
  },
}

local TITLE = 'Zpráva'
-- Nápověda, kterou Messenger přidává za text každé zprávy.
local HINT = ', poklepáním zobrazíte'

local function present(text)
  if text ~= nil and text ~= '' then
    return text
  end
end

local function trim(text)
  return ((text or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Odkazy mají kolem sebe neviditelné značky směru textu.
local function clean(text)
  local out = {}
  for _, code in utf8.codes(text or '') do
    if not ((code >= 0x200B and code <= 0x200F) or (code >= 0x202A and code <= 0x202E) or (code >= 0x2066 and code <= 0x2069) or code == 0x2060) then
      out[#out + 1] = utf8.char(code)
    end
  end
  return trim(table.concat(out))
end

local function label_of(item)
  return clean(present(item.contentDescription) or item.text)
end

local function is_list(item)
  return item ~= nil and (item.className or '') == 'android.view.View' and item.focusable
    and (item.childCount or 0) > 0
end

-- Řádek konverzace: přímý potomek seznamu zpráv.
local function row_of(item)
  local current = item
  for _ = 1, 12 do
    if current == nil then
      return nil
    end
    local parent = current:parent()
    if is_list(parent) then
      return current
    end
    current = parent
  end
end

local function bubble_of(row)
  return row and row:find({ longClickable = true })
end

local function all_items(node, out)
  out = out or {}
  for _, child in ipairs(node:children() or {}) do
    out[#out + 1] = child
    all_items(child, out)
  end
  return out
end

-- Datum a čas nad zprávou: „17. 11. 2025 V 9:45“, „PO V 17:48“, „10:52“.
local function is_time(text)
  return text:find('^%d%d?:%d%d$') or text:find(' V %d%d?:%d%d$')
end

local DAYS = { PO = 'pondělí', ['ÚT'] = 'úterý', ST = 'středa', ['ČT'] = 'čtvrtek', ['PÁ'] = 'pátek', SO = 'sobota', NE = 'neděle' }

local function nice_time(text)
  local day, rest = text:match('^(%S+) V (.+)$')
  if day and DAYS[day] then
    return DAYS[day] .. ' v ' .. rest
  end
  return (text:gsub(' V ', ' v '))
end

-- Odkaz se čte jako doména a název stránky z adresy, bez parametrů:
-- „www.idnes.cz: uzavirka pisarecky tunel konec omezeni plny provoz sobota“.
local function link_name(url)
  local domain, path = url:match('^https?://([^/?#]+)([^?#]*)')
  if domain == nil then
    return url
  end
  local best = ''
  for segment in path:gmatch('[^/]+') do
    segment = segment:gsub('%..*$', '')
    if #segment > #best and segment:find('%a') then
      best = segment
    end
  end
  best = best:gsub('[-_+]', ' ')
  if best == '' then
    return domain
  end
  return domain .. ': ' .. best
end

-- Co zpráva obsahuje a kdo ji poslal. Vrací tabulku { author, body, time, seen, own, photo, ... }.
local function parse(row)
  local info = { parts = {} }
  local bubble = bubble_of(row)
  if bubble == nil then
    return nil
  end
  info.bubble = bubble
  -- Vaše bublina je zarovnaná k pravému okraji, cizí začíná za avatarem.
  info.own = bubble.bounds ~= nil and bubble.bounds.right >= 1000 and bubble.bounds.left > 200
  for _, node in ipairs(all_items(row)) do
    local text = label_of(node)
    local inside = row_of(node) == row
    if text == '' or not inside then
      -- nic
    elseif text:find('^Otevřít profil ') then
      info.profile = node
      info.author = info.author or text:gsub('^Otevřít profil ', '')
    elseif text:find('^Přeposlání ') then
      info.forward = node
      local who, when = text:match('odeslal%(a%) (.-) v (.+)$')
      info.forward_time = when
      info.author = info.author or who
    elseif text:find('^Zobrazeno') then
      info.seen = true
    elseif text == 'Přidat vlastní reakci' then
      info.react = node
    elseif text:find('^Poklepáním dáte To se mi líbí') then
      info.like = node
    elseif is_time(text) and node.bounds and node:parent() and not node:parent().longClickable then
      info.time = nice_time(text)
    elseif text:find(HINT, 1, true) then
      -- Text zprávy: „Jméno, text zprávy, poklepáním zobrazíte…“
      local body = text:sub(1, text:find(HINT, 1, true) - 1)
      local name, rest = body:match('^([^,]+), (.*)$')
      if name then
        info.first_name = name
        body = rest
      end
      info.parts[#info.parts + 1] = body
    elseif text:find(' posílá ') then
      local name, what = text:match('^(.-) posílá (.+)$')
      info.first_name = info.first_name or name
      info.parts[#info.parts + 1] = what
    elseif text == 'Přijatá fotozpráva' or text == 'Odeslaná fotozpráva' or text:find('fotozpráva') then
      info.photo = node
      info.parts[#info.parts + 1] = 'fotka'
    elseif node.className and node.className:find('Button$') and node.clickable then
      -- Náhled odkazu: „www.idnes.cz, idnes.cz“; samotná adresa je text uvnitř.
      info.link = node
    elseif not node.clickable and not info.link_text and text:find('^https?://') then
      info.link_text = text
    end
  end
  local full = {}
  for i, part in ipairs(info.parts) do
    full[i] = part
  end
  if info.link then
    local url = info.link_text or label_of(info.link)
    info.parts[#info.parts + 1] = 'odkaz ' .. link_name(url)
    full[#full + 1] = 'odkaz ' .. url
  end
  if #info.parts == 0 then
    return nil
  end
  info.body = table.concat(info.parts, '. ')
  info.full = table.concat(full, '\n')
  info.time = info.time or info.forward_time
  return info
end

local function author_of(info)
  if info.own then
    return 'Vy'
  end
  return info.first_name or info.author or 'Zpráva'
end

local function speech(info)
  local said = author_of(info) .. ': ' .. info.body
  if info.time and sf.settings.get('readTime') ~= false then
    said = said .. '. ' .. info.time
  end
  if info.seen and sf.settings.get('readSeen') ~= false then
    said = said .. ', zobrazeno'
  end
  return said
end

local function info_of(item)
  local row = row_of(item)
  return row and parse(row), row
end

-- Bublina zprávy: dlouze stisknutelná položka v seznamu zpráv.
local function is_bubble(item)
  return item.longClickable and row_of(item) ~= nil
end

sf.onFocus(function(item, text)
  if not is_bubble(item) then
    return
  end
  local info = info_of(item)
  if info then
    return speech(info)
  end
end)

-- Akce ------------------------------------------------------------------------------------------

local function fresh(item)
  local info = info_of(item:refresh() or item)
  if info == nil then
    sf.speak('Zpráva tu už není', { interrupt = true })
  end
  return info
end

local function click(item, key, missing)
  local info = fresh(item)
  local target = info and info[key]
  if target then
    target:click()
  elseif info then
    sf.speak(missing, { interrupt = true })
  end
end

local function describe(item)
  local ok, ran = pcall(sf.commands.run, 'DESCRIBE_IMAGE')
  if not ok or not ran then
    sf.speak('Popis obrázku se nepodařilo spustit', { interrupt = true })
  end
end

local function recognize(item)
  local info = fresh(item)
  if info == nil or info.photo == nil then
    return
  end
  local ok, result = pcall(info.photo.recognizeText, info.photo)
  local text = ok and result and trim(result.text) or ''
  if text == '' then
    sf.speak('Na fotce není text, nebo není celá na obrazovce', { interrupt = true })
    return
  end
  sf.ui.text('Text na fotce', text)
end

sf.onActions(function(item)
  if not is_bubble(item) then
    return
  end
  local info = info_of(item)
  if info == nil then
    return
  end
  local actions = {}
  if info.photo then
    actions[#actions + 1] = { title = 'Popsat obrázek', first = true, run = describe }
    actions[#actions + 1] = { title = 'Rozpoznat text na obrázku', first = true, run = recognize }
  end
  actions[#actions + 1] = {
    title = 'Zobrazit celou zprávu',
    first = true,
    run = function(target)
      local now = fresh(target)
      if now then
        sf.ui.text(TITLE, author_of(now) .. ': ' .. now.full .. (now.time and ('\n' .. now.time) or ''))
      end
    end,
  }
  actions[#actions + 1] = {
    title = 'Možnosti zprávy',
    first = true,
    run = function(target)
      local now = fresh(target)
      if now then
        now.bubble:longClick()
      end
    end,
  }
  if info.forward then
    actions[#actions + 1] = { title = 'Přeposlat', run = function(t) click(t, 'forward', 'Přeposlat tu není') end }
  end
  if info.like then
    actions[#actions + 1] = { title = 'To se mi líbí', run = function(t) click(t, 'like', 'To se mi líbí tu není') end }
  end
  if info.react then
    actions[#actions + 1] = { title = 'Přidat reakci', run = function(t) click(t, 'react', 'Přidat reakci tu není') end }
  end
  if info.profile then
    actions[#actions + 1] = { title = 'Otevřít profil', run = function(t) click(t, 'profile', 'Profil tu není') end }
  end
  return actions
end)

-- Ovládací prvek čtení Zprávy -------------------------------------------------------------------

local function message_list()
  local field = sf.screen.find({ className = 'EditText' })
  for _, view in ipairs(sf.screen.findAll({ className = 'view.View', focusable = true }, 20) or {}) do
    if is_list(view) and (field == nil or (view.bounds and field.bounds and view.bounds.bottom <= field.bounds.top + 4)) then
      return view
    end
  end
end

local function rows_with_messages(list)
  local out = {}
  for _, row in ipairs(list:children() or {}) do
    local info = parse(row)
    if info then
      out[#out + 1] = { row = row, key = info.body .. '|' .. (info.time or '') }
    end
  end
  return out
end

-- Seznam se nehlásí jako posouvatelný, posouvá se tažením prstu uprostřed.
local function scroll(list, newer)
  local b = list.bounds
  local x = (b.left + b.right) // 2
  local top = b.top + (b.bottom - b.top) // 4
  local bottom = b.bottom - (b.bottom - b.top) // 4
  if newer then
    sf.touch.swipe(x, bottom, x, top, 300)
  else
    sf.touch.swipe(x, top, x, bottom, 300)
  end
  sf.sleep(500)
end

sf.onCommand('message', function(event)
  local forward = event.direction ~= 'previous'
  local list = message_list()
  if list == nil then
    sf.speak('Konverzace tu není', { interrupt = true })
    return
  end
  local focused = event.node or sf.screen.focused()
  local current = focused and row_of(focused)
  local info = current and parse(current)
  local key = info and (info.body .. '|' .. (info.time or ''))
  for attempt = 1, 3 do
    local rows = rows_with_messages(list)
    local index
    for i, entry in ipairs(rows) do
      if key ~= nil and entry.key == key then
        index = i
      end
    end
    local target
    if index == nil and key == nil then
      target = rows[forward and 1 or #rows]
    elseif index ~= nil then
      target = rows[index + (forward and 1 or -1)]
    end
    if target then
      bubble_of(target.row):focus()
      return
    end
    if attempt == 3 then
      break
    end
    scroll(list, forward)
    list = message_list()
    if list == nil then
      break
    end
  end
  sf.speak(forward and 'Konec konverzace' or 'Začátek načtené konverzace', { interrupt = true })
end)

sf.onCommand('compose', function()
  local field = sf.screen.find({ className = 'EditText' })
  if field then
    field:focus()
  else
    sf.speak('Pole pro psaní tu není', { interrupt = true })
  end
end)
