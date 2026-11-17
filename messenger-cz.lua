local manifest = {
  id = 'messenger-fix-cz',
  name = 'Messenger: zprávy jako jedna položka',
  version = '5.30',
  author = 'Jan Balák (podle skriptu Tomáše Hromádky)',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'V konverzaci Messengeru je každá zpráva jedna položka: kdo ji poslal (Vy nebo jméno), text, fotka, samolepka nebo odkaz (doména a název stránky), souřadnice česky, počet reakcí, jestli byla upravená, čas a jestli ji druhý viděl. Švihání zůstává jako v SandFly, avatary, časy a tlačítka u zprávy se přeskakují; švihnutí přes první zprávu na obrazovce načte starší zprávy a přes poslední novější, místo aby fokus utekl z konverzace. Zpráva u okraje vidět jen zčásti se před přečtením ukáže celá. Sdílené příspěvky se čtou celé. Ovládací prvek čtení Zprávy přechází po zprávách a konverzaci sám posouvá. Akce u zprávy: Otevřít polohu v mapách (Android nabídne mapové aplikace), Sdílet polohu, Otevřít odkaz, Zobrazit celou zprávu, Odpovědět, Reagovat (výběr reakce ze seznamu), Zkopírovat, Přeložit, Možnosti zprávy (nabídka po dlouhém stisku, reakce v ní jdou aktivovat poklepáním), Zobrazit reakce, Přeposlat, To se mi líbí, Otevřít profil, telefonní čísla, u fotky Popsat obrázek a Rozpoznat text na obrázku. Příkaz Přejít do pole pro psaní je v SandFly menu a na SandFly+J.',
  apps = { 'com.facebook.orca' },
  permissions = { 'screen', 'speech', 'input', 'actions', 'dialogs', 'system' },
  settings = {
    { key = 'readTime', type = 'switch', title = 'Číst čas zprávy', default = true },
    { key = 'readSeen', type = 'switch', title = 'Číst, že druhý zprávu viděl', default = true },
    {
      key = 'scrollFeedback', type = 'list', title = 'Ohlásit posouvání konverzace', default = 'sound',
      options = {
        { value = 'sound', label = 'Zvuk a krátká vibrace' },
        { value = 'vibrate', label = 'Jen vibrace' },
        { value = 'speech', label = 'Říct „Posouvám“' },
        { value = 'none', label = 'Nic' },
      },
    },
    { key = 'debugTiming', type = 'switch', title = 'Zapisovat do Logu, jak dlouho trvá posouvání', summary = 'Pro ladění: po každém posunutí konverzace zapíše do Logu skriptu, kolik milisekund trvala která část.', default = false },
    { key = 'autoScroll', type = 'switch', title = 'Švihnutím přes první zprávu načíst starší', summary = 'Na první zprávě na obrazovce švihnutí na předchozí položku posune konverzaci ke starším zprávám, na poslední zprávě švihnutí na další k novějším. Vypnuté: fokus přejde na tlačítka nahoře nebo na pole pro psaní.', default = true },
  },
  commands = {
    { id = 'message', title = 'Zprávy', control = true },
    { id = 'compose', title = 'Přejít do pole pro psaní', menu = true, keys = 'sf+j' },
    -- Na první a poslední zprávě na obrazovce posune konverzaci, jinak běžné švihnutí.
    { id = 'olderSwipe', title = 'Předchozí položka, na první zprávě načíst starší', gesture = 'swipeLeft' },
    { id = 'newerSwipe', title = 'Další položka, na poslední zprávě načíst novější', gesture = 'swipeRight' },
  },
  rules = {
    -- Bublina zprávy je jedna položka; skript k ní přidá autora, čas a „zobrazeno“. Poklepání
    -- udělá totéž co klepnutí na bublinu (otevře fotku nebo odkaz, u textu ukáže datum).
    {
      match = { longClickable = true, focusable = true, inside = { className = 'view.View', focusable = true } },
      group = true,
      activate = { clickable = true },
    },
    -- Náhled odkazu a fotka uvnitř bubliny nejsou další zastávka: zpráva by se četla znovu.
    { match = { longClickable = true, inside = { longClickable = true, focusable = true } }, hide = 'all' },
    -- Ostatní části řádku se přeskakují, jsou ve zprávě nebo v nabídce Akce.
    { match = { textContains = 'Otevřít profil', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { textContains = 'Přeposlání', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { contentDescription = 'Přeposlat', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { textContains = 'Zobrazeno', inside = { className = 'view.View', focusable = true } }, hide = true },
    { match = { contentDescription = 'Přidat vlastní reakci' }, hide = true },
    { match = { textContains = 'Poklepáním dáte To se mi líbí' }, hide = true },
    -- „Upraveno“ nad zprávou: řekne se u zprávy.
    { match = { focusable = true, has = { text = 'Upraveno' }, inside = { className = 'view.View', focusable = true } }, hide = 'all' },
    -- Datum a čas mezi zprávami („PO V 17:48“, „10:52“).
    { match = { textContains = ':', clickable = false, focusable = false, inside = { className = 'view.View', focusable = true } }, hide = true },
    -- Nabídka po dlouhém stisku zprávy: reakce nejdou aktivovat přístupností (nejsou klikací),
    -- jen klepnutím na obrazovku. Text uvnitř tlačítek Odpovědět, Zkopírovat… se neopakuje.
    { match = { className = 'Button', inside = { contentDescription = 'Na panelu najdete seznam možných reakcí na zprávu.' } }, touchToActivate = true },
    { match = { contentDescription = 'Na panelu najdete seznam možných reakcí na zprávu.' }, label = 'Reakce na zprávu' },
    { match = { clickable = false, inside = { { className = 'Button' }, { className = 'AbsListView' } } }, hide = true },
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
-- Jedním nahrazením po bajtech: znak po znaku to u dlouhých příspěvků nestihlo časový limit SandFly.
-- U+200B–200F a U+202A–202E jsou E2 80 xx, U+2060 a U+2066–2069 jsou E2 81 xx.
local function clean(text)
  text = (text or ''):gsub('\xE2\x80[\x8B-\x8F\xAA-\xAE]', ''):gsub('\xE2\x81[\xA0\xA6-\xA9]', '')
  return trim(text)
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
  -- Bublina je v řádku nanejvýš pár úrovní hluboko; dál nahoru je to pomalé a zbytečné.
  for _ = 1, 6 do
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

-- Všechny položky řádku jedním dotazem; procházení po jednotlivých potomcích je pomalé.
local function all_items(node)
  return node:findAll({}, 80) or {}
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
    -- Bez přípony a bez čísla článku na začátku („496563-bezpecnost-…“).
    segment = segment:gsub('%..*$', ''):gsub('^%d+[-_]', '')
    if #segment > #best and segment:find('%a') then
      best = segment
    end
  end
  -- Krátký odkaz (mapy.com/s/dalelanufa) nemá v adrese název, řekne se jen doména.
  if best == '' or not best:find('[-_+]') then
    return domain
  end
  return domain .. ': ' .. best:gsub('[-_+]', ' ')
end

-- Souřadnice v textu, jak je posílají Mapy.com: „49.1411795N, 16.6666782E“.
local function geo_of(text)
  local lat, ns, lon, ew = text:match('(%d+%.%d+)%s*([NS]),%s*(%d+%.%d+)%s*([EW])')
  if lat then
    return {
      lat = (ns == 'S' and '-' or '') .. lat,
      lon = (ew == 'W' and '-' or '') .. lon,
      said = lat:gsub('%.', ',') .. (ns == 'N' and ' severní šířky, ' or ' jižní šířky, ')
        .. lon:gsub('%.', ',') .. (ew == 'E' and ' východní délky' or ' západní délky'),
      raw = text:match('%d+%.%d+%s*[NS],%s*%d+%.%d+%s*[EW]'),
    }
  end
end

-- Text zprávy k přečtení: souřadnice česky, adresy jako doména a název stránky.
local function say_text(text)
  local geo = geo_of(text)
  if geo then
    local s, e = text:find(geo.raw, 1, true)
    text = text:sub(1, s - 1) .. 'souřadnice ' .. geo.said .. text:sub(e + 1)
  end
  text = text:gsub('https?://[^%s,]+', function(url)
    return 'odkaz ' .. link_name(url)
  end)
  -- Řádky textu jako věty; prázdné řádky a čárka za dvojtečkou nebo tečkou se vynechají.
  text = text:gsub('%s*\n[%s\n]*', ', '):gsub('([:.!?]), ', '%1 ')
  return text
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
    if text == '' then
      -- nic
    elseif text:find('^Otevřít profil ') then
      info.profile = node
      info.author = info.author or text:gsub('^Otevřít profil ', '')
    elseif text:find('^Přeposlání ') or text == 'Přeposlat' then
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
      info.anchor = info.anchor or body
    elseif text:find(' posílá ') then
      local name, what = text:match('^(.-) posílá (.+)$')
      info.first_name = info.first_name or name
      info.parts[#info.parts + 1] = what
      info.anchor = info.anchor or text
    elseif text == 'Přijatá fotozpráva' or text == 'Odeslaná fotozpráva' or text:find('fotozpráva') then
      info.photo = node
      info.parts[#info.parts + 1] = 'fotka'
    elseif text:find('^%d+ reakc') then
      -- „1 reakce“: Messenger neříká jaká, jen kolik. Klepnutí ukáže, kdo a čím reagoval.
      info.reactions = node
      info.reactions_text = text
    elseif text == 'Upraveno' then
      info.edited = true
    elseif node.className and node.className:find('Button$') and node.clickable then
      -- Odkaz, souřadnice nebo telefonní číslo v textu zprávy, nebo náhled odkazu.
      info.buttons = info.buttons or {}
      info.buttons[#info.buttons + 1] = node
    elseif not node.clickable and #text < 40 and not text:find('https?://') then
      -- Krátký text bez další role, např. zdroj sdíleného příspěvku („Facebook“).
      info.small = info.small or {}
      info.small[#info.small + 1] = text
    elseif not node.clickable and not info.link_text and text:find('https?://') then
      -- Text v náhledu odkazu: „tak už to taky můžete vyplnit :-) https://…“
      local url = text:match('https?://%S+')
      info.link_text = url
      info.anchor = info.anchor or url
      info.link_caption = trim(text:gsub('https?://%S+', ''))
    end
  end
  local raw = table.concat(info.parts, '\n')
  info.geo = geo_of(raw)
  info.urls, info.numbers = {}, {}
  for _, button in ipairs(info.buttons or {}) do
    local text = label_of(button)
    if text:find('^https?://') then
      info.urls[#info.urls + 1] = text
    elseif raw:find(text, 1, true) then
      -- Tlačítko je kus textu zprávy: souřadnice (ty jsou v akci polohy), nebo číslo.
      if not (info.geo and text:find('^%-?%d+%.%d+$')) and text:find('%d%d%d') then
        info.numbers[#info.numbers + 1] = button
      end
    elseif text:find('^[%w%.%-]+%.%a+, [%w%.%-]+$') then
      -- Náhled odkazu: „www.idnes.cz, idnes.cz“; samotná adresa je text uvnitř. Zprávu poznávat
      -- podle náhledu: text s adresou u bubliny vidět jen zčásti chybí.
      info.link = button
      info.anchor = 'odkaz ' .. text
    elseif text ~= '' then
      -- Sdílený příspěvek (z Facebooku apod.): celý text je popisek tlačítka v bublině.
      info.shared = text
      info.anchor = info.anchor or text
    end
  end
  if info.shared then
    -- Popisek končí zdrojem („…, Facebook“), ten je i zvlášť jako krátký text.
    local source
    for _, small in ipairs(info.small or {}) do
      local tail = ', ' .. small
      if info.shared:sub(-#tail) == tail then
        source = small
        info.shared = info.shared:sub(1, -#tail - 1)
        break
      end
    end
    table.insert(info.parts, 1, 'sdílený příspěvek' .. (source and (', ' .. source) or '') .. ': ' .. info.shared)
  end
  local spoken, full = {}, {}
  for i, part in ipairs(info.parts) do
    spoken[i] = say_text(part)
    full[i] = part
  end
  if info.link then
    -- Bez adresy v textu zůstane z popisku náhledu „www.idnes.cz, idnes.cz“ jen první část.
    local url = info.link_text or label_of(info.link):match('^[^,]+')
    if present(info.link_caption) then
      spoken[#spoken + 1] = info.link_caption
      full[#full + 1] = info.link_caption
    end
    spoken[#spoken + 1] = 'odkaz ' .. link_name(url)
    full[#full + 1] = 'odkaz ' .. url
    if url:find('^https?://') then
      info.urls[#info.urls + 1] = url
    end
  end
  if #spoken == 0 then
    return nil
  end
  info.body = table.concat(spoken, '. ')
  info.full = table.concat(full, '\n')
  if info.reactions_text then
    info.body = info.body .. ', ' .. info.reactions_text
  end
  if info.edited then
    info.body = info.body .. ', upraveno'
  end
  info.time = info.time or info.forward_time
  return info
end

-- Jméno z názvu konverzace („Petr Opluštil, Podrobnosti o konverzaci“), pro zprávy bez jména.
local function chat_name()
  local header = sf.screen.find({ textContains = ', Podrobnosti o konverzaci' })
  local name = header and (header.contentDescription or ''):match('^(.-), Podrobnosti o konverzaci')
  return name and name:match('^%S+')
end

local function author_of(info)
  if info.own then
    return 'Vy'
  end
  return info.first_name or (info.author and info.author:match('^%S+')) or chat_name() or 'Zpráva'
end

local function speech(info)
  local said = author_of(info) .. ': ' .. info.body
  if info.time and sf.settings.get('readTime') ~= false then
    said = said .. (said:find('[.!?]$') and ' ' or '. ') .. info.time
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

-- Zpráva se složí a přečte až po návratu z háčku: SandFly na háček čeká jen krátce a skript,
-- který čas opakovaně překročí, vypne. Háček jen umlčí SandFly u dlouze stisknutelných položek.
local focus_count = 0

-- Bublina u okraje obrazovky vidět jen zčásti: chybí v ní, co je mimo obrazovku (text nad náhledem
-- odkazu, zdroj příspěvku, reakce). Ať ji Messenger nejdřív ukáže celou, pak se teprve přečte.
local function reveal(item)
  local row = row_of(item)
  local list = row and row:parent()
  local b, lb = item.bounds, list and list.bounds
  if b == nil or lb == nil or b.bottom - b.top >= lb.bottom - lb.top - 6 then
    return item
  end
  if b.top > lb.top + 3 and b.bottom < lb.bottom - 3 then
    return item
  end
  local ok, done = pcall(item.perform, item, 'showOnScreen')
  if ok and done then
    sf.sleep(150)
    return item:refresh() or item
  end
  return item
end

local function say_message(item, text, count)
  local started = sf.clock()
  local said = text
  if is_bubble(item) then
    item = reveal(item)
    local info = info_of(item)
    if info then
      said = speech(info)
    end
  end
  if sf.settings.get('debugTiming') then
    sf.log.error('MSGTIME čtení zprávy ' .. (sf.clock() - started))
  end
  -- Mezitím mohl fokus odejít jinam: starou zprávu už neříkat.
  if count == focus_count and present(said) then
    sf.speak(said, { interrupt = true })
  end
end

sf.onFocus(function(item, text)
  focus_count = focus_count + 1
  if not item.longClickable then
    return
  end
  sf.setTimeout(say_message, 0, item, text, focus_count)
  return false
end)

-- Akce ------------------------------------------------------------------------------------------

local function fresh(item)
  local info = info_of(item:refresh() or item)
  if info == nil then
    sf.speak('Zpráva tu už není', { interrupt = true })
  end
  return info
end

-- Nabídka po dlouhém stisku: otevřít a počkat, až se ukáže.
local REACTIONS = {
  { '❤', 'Srdce' }, { '😆', 'Smích' }, { '😮', 'Údiv' }, { '😢', 'Smutek' }, { '😡', 'Vztek' },
  { '👍', 'Palec nahoru' }, { 'Další emoji', 'Jiná reakce…' },
}

-- Hledá ve všech oknech: nabídka může být ve vlastním okně nad konverzací.
local function find_anywhere(query)
  local found = sf.screen.find(query)
  if found then
    return found
  end
  local ok, windows = pcall(sf.screen.windows)
  for _, window in ipairs(ok and windows or {}) do
    found = window.root and window.root:find(query)
    if found then
      return found
    end
  end
end

local MENU_SIGNS = {
  { contentDescription = 'Na panelu najdete seznam možných reakcí na zprávu.' },
  { className = 'Button', contentDescription = 'Odpovědět' },
  { contentDescription = '❤' },
  { className = 'Button', contentDescription = 'Víc položek' },
}

local function menu_shown()
  for _, query in ipairs(MENU_SIGNS) do
    local found = find_anywhere(query)
    if found then
      return found
    end
  end
end

local function wait_menu(ms)
  local deadline = sf.clock() + ms
  repeat
    local found = menu_shown()
    if found then
      return found
    end
    sf.sleep(120)
  until sf.clock() >= deadline
end

local function open_menu(item)
  local now = fresh(item)
  if now == nil then
    return nil
  end
  now.bubble:longClick()
  local menu = wait_menu(2000)
  if menu == nil then
    -- Dlouhý stisk přes přístupnost nezabral: podržet prst na bublině (jen když nabídka opravdu není,
    -- klepnutí mimo otevřenou nabídku by ji zavřelo).
    local b = now.bubble.bounds
    if b then
      sf.touch.longPress((b.left + b.right) // 2, (b.top + b.bottom) // 2, 700)
      menu = wait_menu(2000)
    end
  end
  if menu == nil then
    local ok, windows = pcall(sf.screen.windows)
    local names = {}
    for _, window in ipairs(ok and windows or {}) do
      names[#names + 1] = tostring(window.type) .. ':' .. tostring(window.title)
    end
    sf.log.error('MSGTIME nabídka nenalezena, okna: ' .. table.concat(names, ', '))
    sf.speak('Nabídka zprávy se neotevřela', { interrupt = true })
  end
  return menu
end

-- Položka dole v nabídce (Odpovědět, Zkopírovat, Přeložit). Když tam není, nabídka se zavře.
local function menu_item(item, name)
  if open_menu(item) == nil then
    return
  end
  local button = find_anywhere({ className = 'Button', contentDescription = name })
  if button then
    button:click()
  else
    sf.system.back()
    sf.speak(name .. ' u této zprávy není', { interrupt = true })
  end
end

-- Reakce: nejdřív výběr, pak nabídka a klepnutí na reakci (přístupností na ni klepnout nejde).
local function react(item)
  local names = {}
  for i, reaction in ipairs(REACTIONS) do
    names[i] = reaction[2]
  end
  local chosen = sf.ui.choose('Reagovat na zprávu', names)
  local emoji
  for i, name in ipairs(names) do
    if name == chosen then
      emoji = REACTIONS[i][1]
    end
  end
  if emoji == nil or open_menu(item) == nil then
    return
  end
  local button = find_anywhere({ contentDescription = emoji })
  local b = button and button.bounds
  if b == nil then
    sf.system.back()
    sf.speak('Reakce v nabídce není', { interrupt = true })
    return
  end
  sf.touch.tap((b.left + b.right) // 2, (b.top + b.bottom) // 2)
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

-- Poloha ---------------------------------------------------------------------------------------
local function geo_uri(geo)
  return 'geo:' .. geo.lat .. ',' .. geo.lon .. '?q=' .. geo.lat .. ',' .. geo.lon
end

-- Poloha se předá Androidu: ten nabídne mapové aplikace (Jen jednou / Vždy), nebo ji otevře
-- ve výchozí, pokud ji tak máte nastavenou.
local function open_geo(geo)
  local ok, opened = pcall(sf.system.openUrl, geo_uri(geo))
  if not ok or opened == false then
    sf.speak('Polohu nejde otevřít, v telefonu asi není aplikace s mapami', { interrupt = true })
  end
end

-- Klasický sdílecí dialog Androidu s textem zprávy (název místa, souřadnice, odkaz).
local function share_geo(item)
  local now = fresh(item)
  if now then
    sf.system.share(now.full, { title = 'Sdílet polohu' })
  end
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
  actions[#actions + 1] = { title = 'Odpovědět', first = true, run = function(t) menu_item(t, 'Odpovědět') end }
  actions[#actions + 1] = { title = 'Reagovat', first = true, run = react }
  actions[#actions + 1] = { title = 'Zkopírovat', run = function(t) menu_item(t, 'Zkopírovat') end }
  actions[#actions + 1] = { title = 'Přeložit', run = function(t) menu_item(t, 'Přeložit') end }
  actions[#actions + 1] = {
    title = 'Možnosti zprávy',
    first = true,
    run = function(target)
      -- Otevřít nabídku a dát fokus na její první položku, jinak o ní není slyšet.
      if open_menu(target) then
        local first = find_anywhere({ className = 'Button', contentDescription = 'Odpovědět' })
          or find_anywhere({ contentDescription = '❤' })
        if first then
          first:focus()
        end
      end
    end,
  }
  -- Poloha a odkazy jsou v nabídce hned na začátku.
  local front = info.photo and 3 or 1
  if info.geo then
    local geo = info.geo
    table.insert(actions, front, {
      title = 'Otevřít polohu v mapách',
      first = true,
      run = function()
        open_geo(geo)
      end,
    })
    front = front + 1
    table.insert(actions, front, { title = 'Sdílet polohu', first = true, run = share_geo })
    front = front + 1
  end
  for _, url in ipairs(info.urls or {}) do
    table.insert(actions, front, {
      title = 'Otevřít odkaz ' .. link_name(url),
      first = true,
      run = function()
        sf.system.openUrl(url)
      end,
    })
    front = front + 1
  end
  if info.reactions then
    actions[#actions + 1] = {
      title = 'Zobrazit reakce',
      run = function(t) click(t, 'reactions', 'Reakce tu nejsou') end,
    }
  end
  for i, number in ipairs(info.numbers or {}) do
    local digits = label_of(number)
    actions[#actions + 1] = {
      title = 'Číslo ' .. digits,
      run = function(target)
        local now = fresh(target)
        local again = now and now.numbers and now.numbers[i]
        if again then
          again:click()
        end
      end,
    }
  end
  if info.forward then
    actions[#actions + 1] = { title = 'Přeposlat', run = function(t) click(t, 'forward', 'Přeposlat tu není') end }
  end
  if info.like then
    actions[#actions + 1] = { title = 'To se mi líbí', run = function(t) click(t, 'like', 'To se mi líbí tu není') end }
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

-- Zpráva se po posunutí pozná podle obsahu. Čas ne: datum nad zprávou bývá i mimo obrazovku.
-- Zpráva se pozná podle začátku hlavního textu. Celé čtení ne: u bubliny vidět jen zčásti chybí
-- spodní řádek (zdroj příspěvku, „1 reakce“, „upraveno“) a po posunutí by to byla „jiná“ zpráva.
local function key_of(info)
  if info == nil then
    return nil
  end
  local anchor = info.anchor
  if anchor == nil and info.photo then
    anchor = 'fotka ' .. (info.forward_time or '')
  end
  return (info.own and 'Vy|' or '|') .. (anchor or info.body):sub(1, 60)
end

local function rows_with_messages(list)
  local out = {}
  for _, row in ipairs(list:children() or {}) do
    local info = parse(row)
    if info then
      out[#out + 1] = { row = row, key = key_of(info) }
    end
  end
  return out
end

-- Podpis toho, co je teď v seznamu vidět, aby šlo poznat, že se seznam přestal hýbat.
local function snapshot()
  local list = message_list()
  if list == nil then
    return nil, ''
  end
  -- Jen polohy bublin zpráv, bez čtení textu: stačí poznat, že se seznam přestal hýbat.
  local tops = {}
  for _, child in ipairs(list:children() or {}) do
    local bubble = bubble_of(child)
    if bubble and bubble.bounds then
      tops[#tops + 1] = bubble.bounds.top
    end
  end
  return list, table.concat(tops, ';')
end

-- Měření posouvání (nastavení Hlásit, jak dlouho trvá posouvání).
local timing, timing_start, logged_actions
local busy_since -- kdy začalo posouvání, které ještě běží
local function mark(name)
  if timing then
    timing[#timing + 1] = name .. ' ' .. (sf.clock() - timing_start)
  end
end

-- Dát najevo, že se konverzace posouvá (podle nastavení skriptu).
local function feedback()
  local mode = sf.settings.get('scrollFeedback') or 'sound'
  if mode == 'sound' then
    sf.playSound('scroll')
    sf.vibrate(30)
  elseif mode == 'vibrate' then
    sf.vibrate(40)
  elseif mode == 'speech' then
    sf.speak('Posouvám', { interrupt = true })
  end
end

-- Seznam se nehlásí jako posouvatelný, posouvá se tažením prstu uprostřed. Táhne se pomalu,
-- aby seznam po puštění nedojížděl setrvačností, a čeká se, až se přestane hýbat.
local function scroll(list, newer, fraction)
  local b = list.bounds
  if b == nil then
    return message_list()
  end
  local x = (b.left + b.right) // 2
  -- Výchozí posun o víc než půl obrazovky, aby se načetlo víc zpráv a další švihnutí šla bez
  -- posouvání. Táhne se pomaleji: délka tažení celkový čas skoro nemění (SandFly k němu přidává
  -- kolem půl sekundy), ale seznam po puštění méně dojíždí a nepřeskočí tolik zpráv.
  local height = b.bottom - b.top
  local span = math.floor(height * (fraction or 0.6))
  local top = b.top + (height - span) // 2
  local bottom = top + span
  mark('před tažením')
  local from, to = top, bottom
  if newer then
    from, to = bottom, top
  end
  -- Tažení s přidržením prstu na konci: seznam se po puštění nerozjede setrvačností, posune se
  -- přesně o taženou vzdálenost a hned stojí. Body jdou rovnoměrně v čase: 12 kroků pohybu,
  -- pak 6 bodů na stejném místě (asi třetina doby).
  local points = {}
  for i = 0, 12 do
    points[#points + 1] = { x = x, y = from + (to - from) * i // 12 }
  end
  for _ = 1, 6 do
    points[#points + 1] = { x = x, y = to }
  end
  local ok = sf.touch.gesture ~= nil and pcall(sf.touch.gesture, { { points = points, start = 0, duration = 420 } })
  if not ok then
    sf.touch.swipe(x, from, x, to, 600)
  end
  mark(ok and 'po tažení s přidržením' or 'po tažení')
  sf.sleep(ok and 80 or 150)
  local fresh_list = list:refresh() or message_list()
  mark('seznam stojí')
  -- O kolik se seznam posunul: o taženou dráhu bez prahu, než seznam začne táhnout (asi 25 px).
  -- Jen u tažení s přidržením; obyčejné tažení dojíždí setrvačností.
  return fresh_list, ok and (span - 25) or nil
end

-- Přesune fokus na zprávu a ověří, že tam zůstal; seznam řádky po posunutí ještě přestavuje.
local function focus_message(key)
  for _ = 1, 4 do
    local list = message_list()
    if list == nil then
      return
    end
    for _, entry in ipairs(rows_with_messages(list)) do
      local bubble = bubble_of(entry.row)
      if entry.key == key and bubble then
        bubble:focus()
        sf.sleep(120)
        local focused = sf.screen.focused()
        local row = focused and row_of(focused)
        if row and key_of(parse(row)) == key then
          return true
        end
        sf.log('Fokus se na zprávě neudržel, znovu')
        break
      end
    end
    sf.sleep(250)
  end
  sf.log('Fokus na zprávu se nepodařilo přesunout: ' .. key)
end

-- Zpráva, ze které je vidět aspoň řádek. Na kousek u kraje obrazovky se SandFly nedostane.
local function shown(entry)
  local bubble = bubble_of(entry.row)
  local b = bubble and bubble.bounds
  return b ~= nil and b.bottom - b.top >= 60
end

-- Začátek zprávy pro záznam v Logu.
local function short_key(key)
  return ((key or '?'):gsub('^Vy|', 'Vy: '):gsub('^|', ''):sub(1, 30))
end

-- Přejde na sousední zprávu; když je zpráva na kraji obrazovky, konverzaci posune.
-- Okraj bubliny, podle kterého se zpráva po posunutí najde: u horního okraje obrazovky spodní
-- (horní může být uříznutý), u spodního horní.
local function edge_of(entry, forward)
  local bubble = bubble_of(entry.row)
  local b = bubble and bubble.bounds
  if b == nil then
    return nil
  end
  return forward and b.top or b.bottom
end

local function move(list, key, forward)
  local expected -- kde má být okraj výchozí zprávy po posunutí
  local seen -- zprávy, které byly vidět před posunutím
  local partly -- sousední zpráva vidět jen kouskem
  local backed -- po příliš dlouhém posunu se už jednou vracelo
  for attempt = 1, 5 do
    local rows = rows_with_messages(list)
    local index
    for i, entry in ipairs(rows) do
      if key ~= nil and entry.key == key then
        index = i
      end
    end
    -- Po posunutí s přidržením je známo, kam se výchozí zpráva posunula: najít ji podle polohy.
    -- Text nestačí: u bubliny vidět jen zčásti chybí část textu a stejné odkazy se opakují.
    if expected ~= nil and key ~= nil then
      local own = key:sub(1, 3) == 'Vy|'
      local best, best_error
      for i, entry in ipairs(rows) do
        local edge = edge_of(entry, forward)
        if edge and (entry.key:sub(1, 3) == 'Vy|') == own then
          local miss = math.abs(edge - expected)
          if best_error == nil or miss < best_error then
            best, best_error = i, miss
          end
        end
      end
      if best and best_error <= 45 then
        if index ~= best then
          mark('podle polohy (odchylka ' .. best_error .. ')')
        end
        index = best
      elseif index then
        mark('podle textu')
      end
      expected = nil
    end
    local target
    if index ~= nil then
      target = rows[index + (forward and 1 or -1)]
    elseif key ~= nil and seen ~= nil and not backed then
      -- Posun odjel tak daleko, že výchozí zpráva zmizela: kousek zpátky, ať se nic nepřeskočí.
      backed = true
      mark('posun odjel, vracím')
      if timing then
        local keys = {}
        for _, entry in ipairs(rows) do
          keys[#keys + 1] = '„' .. short_key(entry.key) .. '“'
        end
        sf.log.error('MSGTIME hledám „' .. short_key(key) .. '“, vidět ' .. #rows .. ': ' .. table.concat(keys, ', '))
      end
      list = scroll(list, not forward, 0.3)
      if list == nil then
        break
      end
      goto continue
    elseif key == nil or seen ~= nil then
      -- Výchozí zprávu se nepodařilo najít ani po vrácení: nejbližší nově načtená zpráva.
      local first, last, step = 1, #rows, 1
      if not forward then
        first, last, step = #rows, 1, -1
      end
      for i = first, last, step do
        if seen == nil or not seen[rows[i].key] then
          target = rows[i]
          break
        end
      end
    end
    if target and attempt == 1 and not shown(target) then
      partly = target.key
      target = nil
    end
    if target then
      mark('z „' .. short_key(key) .. '“ na „' .. short_key(target.key) .. '“'
        .. (index and '' or ' (výchozí zpráva už není vidět)'))
      local bubble = bubble_of(target.row)
      if attempt == 1 then
        if bubble then
          bubble:focus()
        end
        return
      end
      -- Po posunutí: zaměřit a krátce ověřit; přes znovunačtení zpráv jen když se fokus neudržel.
      mark('zpráva nalezena')
      local ok = false
      if bubble then
        bubble:focus()
        sf.sleep(120)
        ok = sf.screen.focused() == bubble
      end
      if not ok then
        mark('fokus neudržen')
        ok = focus_message(target.key)
      end
      -- Fokus je na zprávě: další švihnutí už může přijít, nečekat na kontrolu.
      busy_since = nil
      local my_focus = focus_count
      if ok then
        -- Messenger po dojetí nahoru donačítá starší zprávy a seznam ještě přeskládá: ověřit znovu,
        -- ale jen když uživatel mezitím sám nešvihl dál (nevracet mu fokus zpátky).
        sf.sleep(200)
        if focus_count ~= my_focus then
          mark('uživatel pokračuje')
          return
        end
        local focused = sf.screen.focused()
        local row = focused and row_of(focused)
        if not (row and key_of(parse(row)) == target.key) then
          mark('fokus ztracen po přeskládání')
          ok = focus_message(target.key)
        end
      end
      mark(ok and 'fokus' or 'fokus nepřesunut')
      if not ok then
        -- Aspoň přečíst zprávu, na kterou se fokus nedostal.
        local info = parse(target.row)
        sf.speak(info and speech(info) or 'Fokus se nepodařilo přesunout', { interrupt = true })
      end
      return
    end
    if attempt == 5 then
      break
    end
    seen = {}
    local before = {}
    for _, entry in ipairs(rows) do
      seen[entry.key] = true
      before[#before + 1] = entry.key
    end
    sf.log('Posouvám konverzaci ' .. (forward and 'k novějším' or 'ke starším'))
    local edge = index and edge_of(rows[index], forward)
    local shift
    list, shift = scroll(list, forward)
    if list == nil then
      break
    end
    if edge and shift then
      expected = forward and (edge - shift) or (edge + shift)
    end
    -- Konec nebo začátek jen tehdy, když se po posunutí nic nezměnilo.
    local after = {}
    for _, entry in ipairs(rows_with_messages(list)) do
      after[#after + 1] = entry.key
    end
    if table.concat(after, ';') == table.concat(before, ';') then
      if partly then
        focus_message(partly)
      else
        sf.speak(forward and 'Konec konverzace' or 'Začátek konverzace', { interrupt = true })
      end
      return
    end
    ::continue::
  end
  sf.log('Navazující zprávu se nepodařilo najít')
  sf.speak('Navazující zprávu se nepodařilo najít', { interrupt = true })
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
  move(list, key_of(current and parse(current)), forward)
end)

-- Švihnutí na předchozí nebo další položku: SandFly je nechá být, jen na první zprávě na obrazovce
-- (předchozí by byla tlačítka nahoře) a na poslední, pod kterou jsou novější zprávy, konverzaci
-- posune, místo aby fokus utekl z konverzace.

-- Pod poslední zprávou na obrazovce jsou ještě novější: Messenger ukazuje tlačítko Přejít na
-- poslední zprávu, nebo je pod ní vidět datum další zprávy (zpráva sama už je mimo obrazovku).
-- Na skutečném konci konverzace nic z toho není a švihnutí jde na pole pro psaní.
local function more_below(kids, index, list)
  if sf.screen.find({ contentDescription = 'Přejít na poslední zprávu' }) ~= nil then
    return true
  end
  -- Poslední zpráva sahá až k dolnímu okraji (je uříznutá): pod ní je ještě něco. Na skutečném
  -- konci konverzace zůstává pod poslední zprávou volné místo.
  local bubble = bubble_of(kids[index])
  local b, lb = bubble and bubble.bounds, list.bounds
  if b and lb and b.bottom >= lb.bottom - 30 then
    return true
  end
  for k = index + 1, #kids do
    local text = kids[k]:find({ textContains = ':' })
    if text and is_time(label_of(text)) then
      return true
    end
  end
  return false
end

local function edge_swipe(event, forward)
  if sf.settings.get('autoScroll') == false then
    return false
  end
  -- Švihnutí během posouvání se nepouští přes sebe: dvě posouvání by si přetahovala fokus.
  if busy_since and sf.clock() - busy_since < 5000 then
    return
  end
  timing_start = sf.clock()
  timing = sf.settings.get('debugTiming') and {} or nil
  local node = event.node or sf.screen.focused()
  if node == nil or not is_bubble(node) then
    return false
  end
  -- Kraj obrazovky se pozná jen podle řádků seznamu, bez čtení textu zpráv, aby to bylo rychlé.
  local row = row_of(node)
  local list = row and row:parent()
  if list == nil then
    return false
  end
  local kids = list:children() or {}
  local index
  for i, child in ipairs(kids) do
    if child == row then
      index = i
    end
  end
  if index == nil then
    return false
  end
  local step = forward and 1 or -1
  local j = index + step
  while kids[j] ~= nil and bubble_of(kids[j]) == nil do
    j = j + step
  end
  local neighbour = kids[j]
  if neighbour ~= nil then
    local b = bubble_of(neighbour).bounds
    if b ~= nil and b.bottom - b.top >= 60 then
      return false
    end
  elseif forward and not more_below(kids, index, list) then
    return false
  end
  mark('kraj poznán')
  if timing and not logged_actions then
    logged_actions = true
    local names = {}
    for _, action in ipairs(list.actions or {}) do
      names[#names + 1] = tostring(action.id) .. ':' .. tostring(action.label)
    end
    local parent = list:parent()
    for _, action in ipairs(parent and parent.actions or {}) do
      names[#names + 1] = 'rodič ' .. tostring(action.id) .. ':' .. tostring(action.label)
    end
    sf.log.error('MSGTIME akce seznamu: ' .. table.concat(names, ', '))
  end
  -- Sousední zpráva je vidět jen kouskem: ať ji Messenger ukáže celou sám (posune seznam
  -- o kousek), bez tažení prstem. Tažení zůstává, když to nejde nebo sousední zpráva není.
  if neighbour ~= nil then
    local bubble = bubble_of(neighbour)
    local target_key = key_of(parse(neighbour))
    busy_since = sf.clock()
    local ok, done = pcall(bubble.perform, bubble, 'showOnScreen')
    mark('zobrazit na obrazovce ' .. tostring(ok and done))
    if ok and done and target_key then
      sf.sleep(120)
      bubble:focus()
      sf.sleep(80)
      if sf.screen.focused() == bubble then
        mark('fokus')
      elseif focus_message(target_key) then
        mark('fokus napodruhé')
      else
        mark('fokus nepřesunut')
      end
      busy_since = nil
      if timing then
        sf.log.error('MSGTIME ' .. (forward and 'novější' or 'starší') .. ': ' .. table.concat(timing, ', '))
        timing = nil
      end
      return
    end
    busy_since = nil
  end
  feedback()
  local key = key_of(parse(row))
  mark('zpráva přečtena')
  if key == nil then
    return
  end
  local started = sf.clock()
  busy_since = started
  -- Chyba při posouvání se řekne nahlas a zapíše do Logu skriptu, skript kvůli ní nespadne.
  local ok, err = pcall(move, list, key, forward)
  -- Uvolnit jen vlastní posouvání; mezitím mohlo začít další.
  if busy_since == started then
    busy_since = nil
  end
  if not ok then
    sf.log.error('Chyba při posouvání: ' .. tostring(err))
    sf.speak('Chyba skriptu při posouvání: ' .. tostring(err), { interrupt = true })
  end
  if timing then
    sf.log.error('MSGTIME ' .. (forward and 'novější' or 'starší') .. ': ' .. table.concat(timing, ', '))
    timing = nil
  end
end

sf.onCommand('olderSwipe', function(event)
  return edge_swipe(event, false)
end)

sf.onCommand('newerSwipe', function(event)
  return edge_swipe(event, true)
end)

sf.onCommand('compose', function()
  local field = sf.screen.find({ className = 'EditText' })
  if field then
    field:focus()
  else
    sf.speak('Pole pro psaní tu není', { interrupt = true })
  end
end)
