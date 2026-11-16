local manifest = {
  id = 'linkedin',
  name = 'LinkedIn: příspěvky jako jedna položka',
  version = '0.0.1',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Ve feedu LinkedIn je každý příspěvek jedna položka. Přečte se autor, čas, text, obrázek nebo odkazovaný článek a vaše reakce. Podpis autora a počty reakcí jde zapnout v nastavení. Tlačítka uvnitř příspěvku se při švihání přeskakují; reakce, komentáře, přesdílení a další jsou v nabídce Akce. Testovací verze.',
  apps = { 'com.linkedin.android' },
  permissions = { 'screen', 'speech' },
  settings = {
    { key = 'readHeadline', type = 'switch', title = 'Číst podpis autora', summary = 'Text pod jménem, například pracovní pozice.', default = false },
    { key = 'readTime', type = 'switch', title = 'Číst čas příspěvku', default = true },
    { key = 'fullText', type = 'switch', title = 'Číst celý text příspěvku', summary = 'Vypnuté: jen začátek, který je vidět bez rozbalení.', default = true },
    { key = 'readStats', type = 'switch', title = 'Číst počty reakcí a komentářů', default = false },
  },
  rules = {
    -- Příspěvek je klikací položka v seznamu feedu, ve které je tlačítko reakce.
    -- Samotné tlačítko reakce se nedá zaměřit, příspěvek ano.
    {
      match = { clickable = true, focusable = true, has = { textContains = 'Stav tlačítka reakce' }, inside = { id = 'sdui:lazyColumn' } },
      group = true,
    },
    -- Vše klikací a tlačítka uvnitř příspěvku se při švihání přeskakuje. Akce příspěvku jsou v nabídce
    -- Akce, kterou LinkedIn dává přímo příspěvku. Horní ani spodní lišta tím dotčené nejsou.
    { match = { clickable = true, inside = { { clickable = true, focusable = true }, { id = 'sdui:lazyColumn' } } }, hide = true },
    { match = { longClickable = true, inside = { { clickable = true, focusable = true }, { id = 'sdui:lazyColumn' } } }, hide = true },
    { match = { className = 'Button', inside = { { clickable = true, focusable = true }, { id = 'sdui:lazyColumn' } } }, hide = true },
  },
}

local function present(text)
  if text ~= nil and text ~= '' then
    return text
  end
end

local function trim(text)
  return ((text or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function ends_with(text, tail)
  return text ~= nil and tail ~= '' and text:sub(-#tail) == tail
end

local function starts_with(text, head)
  return text ~= nil and text:sub(1, #head) == head
end

local function short_class(item)
  return (item.className or ''):match('[^.]*$')
end

-- Příspěvek poznáme podle akcí, které mu dává LinkedIn.
local function is_post(item)
  for _, action in ipairs(item.actions or {}) do
    local label = action.label or ''
    if starts_with(label, 'Reagovat na tento příspěvek') or label == 'Zobrazit komentáře'
      or starts_with(label, 'React') or label == 'View comments' then
      return true
    end
  end
  return false
end

-- Čas: "1 h.", "3 d.", "2 týd.", "5 min.", "Teď", případně s "• Upraveno".
local function is_time(text)
  if not text or #text > 40 then
    return false
  end
  return text:find('^%d+%s*[^%s%d]+%.?') ~= nil or starts_with(text, 'Teď') or starts_with(text, 'Now')
end

local function clean_time(text)
  return trim((text:gsub('%s*•.*$', '')))
end

-- Jméno z akcí, když v hlavičce není: "Zobrazit profilovou fotku uživatele Petr Novák",
-- "Zobrazit společnost: Software602".
local function name_from_actions(item)
  for _, action in ipairs(item.actions or {}) do
    local label = action.label or ''
    local name = label:match('^Zobrazit profilovou fotku uživatele (.+)$') or label:match('^Zobrazit společnost: (.+)$')
    if name then
      return name
    end
  end
end

local MAX_ITEMS = 120

-- Rozloží příspěvek na části. Položky jdou v pořadí, v jakém jsou na obrazovce.
local function parse(post)
  local items = post:findAll({}, MAX_ITEMS)
  local result = { header = {}, media = {} }

  -- Text příspěvku je první tlačítko s vlastním viditelným textem. Fotka autora a karta článku mají
  -- jen popisek. Zkrácený text končí "… více", celý je v popisku.
  local body_index
  for i, item in ipairs(items) do
    if short_class(item) == 'Button' then
      local text, description = item.text or '', item.contentDescription or ''
      if present(trim(text)) then
        body_index = i
        result.full = present(description) or text
        result.short = trim((text:gsub('…%s*více$', ''):gsub('…%s*more$', '')))
        break
      end
    end
  end

  local header_end = body_index or #items + 1
  for i = 1, header_end - 1 do
    local item = items[i]
    local class = short_class(item)
    if class == 'TextView' and present(item.text) then
      result.header[#result.header + 1] = trim(item.text)
    end
  end

  for i = (body_index or 0) + 1, #items do
    local item = items[i]
    local description = item.contentDescription or ''
    if starts_with(description, 'Stav tlačítka reakce: ') then
      result.reaction = description:sub(#'Stav tlačítka reakce: ' + 1)
    elseif description:find('^%d[%d%s]*%s+reakc') or description:find('^%d[%d%s]*%s+koment') then
      result.stats = result.stats and (result.stats .. ', ' .. description) or description
    elseif short_class(item) == 'Button' and present(description) and i > (body_index or 0) then
      if description == 'Zobrazit obrázek' then
        result.media[#result.media + 1] = 'obrázek'
      elseif not starts_with(description, 'Zobrazit společnost') and not starts_with(description, 'Zobrazit profil') then
        result.media[#result.media + 1] = 'odkaz: ' .. description
      end
    end
  end

  -- Obrázek bez textu příspěvku je před tlačítkem reakce, ne za textem.
  if not body_index then
    result.media = {}
    for _, item in ipairs(items) do
      if short_class(item) == 'Button' and item.contentDescription == 'Zobrazit obrázek' then
        result.media[#result.media + 1] = 'obrázek'
      end
    end
  end

  -- Hlavička: jméno, podpis, čas. Čas je poslední text, který vypadá jako čas.
  local header = result.header
  local time_index
  for i = #header, 1, -1 do
    if is_time(header[i]) then
      time_index = i
      break
    end
  end
  if time_index then
    result.time = clean_time(header[time_index])
  end
  result.name = header[1] or name_from_actions(post)
  local headline = {}
  for i = 2, (time_index or #header + 1) - 1 do
    -- "• 2." je stupeň kontaktu.
    if not header[i]:find('^•') then
      headline[#headline + 1] = header[i]
    end
  end
  result.headline = present(table.concat(headline, ', '))
  -- Nad jménem bývá kontext, např. "Petr Novák se líbí tohle". Bez stromu s takovým příspěvkem
  -- ho zatím nerozlišujeme.
  return result
end

local settings = {
  readHeadline = sf.settings.get('readHeadline') == true,
  readTime = sf.settings.get('readTime') ~= false,
  fullText = sf.settings.get('fullText') ~= false,
  readStats = sf.settings.get('readStats') == true,
}
sf.onSettingChange(function(key, value)
  if settings[key] ~= nil then
    settings[key] = value == true
  end
end)

local function describe(post)
  local parts = {}
  local function add(text)
    -- Prázdné řádky by dělaly zbytečné pauzy; tečka na konci by se zdvojila při spojení.
    text = trim((text or ''):gsub('%s*\n[\n%s]*', ' ')):gsub('%.+$', '')
    if present(text) then
      parts[#parts + 1] = text
    end
  end
  add(post.name)
  if settings.readHeadline then
    add(post.headline)
  end
  if settings.readTime then
    add(post.time)
  end
  add(settings.fullText and post.full or post.short)
  add(table.concat(post.media, ', '))
  if post.reaction and post.reaction ~= 'žádná reakce' then
    add('vaše reakce: ' .. post.reaction)
  end
  if settings.readStats then
    add(post.stats)
  end
  return table.concat(parts, '. ')
end

-- Každé zaměření se počítá, aby se nepřečetl příspěvek, ze kterého už fokus odešel.
local focus_count = 0

local function say_post(item, fallback, count)
  local ok, text = pcall(function()
    return describe(parse(item))
  end)
  if not ok then
    sf.log.warn('Příspěvek se nepodařilo přečíst: ' .. tostring(text))
    text = nil
  end
  if count == focus_count then
    text = present(text) or fallback
    if present(text) then
      sf.speak(text, { interrupt = true })
    end
  end
end

sf.onFocus(function(item, text)
  focus_count = focus_count + 1
  -- Tady se smí dívat jen na to, co už položka má; volání aplikace je pomalé.
  if not is_post(item) then
    return
  end
  sf.setTimeout(say_post, 0, item, text, focus_count)
  return false
end)
