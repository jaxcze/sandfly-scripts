local manifest = {
  id = 'x-feed',
  name = 'X: příspěvky jako jedna položka',
  version = '0.1',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Ve feedu X (Twitter) je každý příspěvek jedna položka. Přečte se jméno a text, případně obrázky a čas. Tlačítka uvnitř příspěvku se při švihání přeskakují; Odpovědět, Znovu publikovat, Lajknout, Záložka, Sdílet a další jsou v nabídce Akce. Obrázky příspěvku jsou v nabídce Akce také.',
  apps = { 'com.twitter.android' },
  permissions = { 'screen', 'speech', 'input', 'actions' },
  settings = {
    { key = 'readHandle', type = 'switch', title = 'Číst uživatelské jméno se zavináčem', default = false },
    { key = 'readTime', type = 'switch', title = 'Číst čas příspěvku', default = true },
    { key = 'readStats', type = 'switch', title = 'Číst počty odpovědí, repostů, lajků a zobrazení', default = false },
  },
  rules = {
    -- Příspěvek je klikací položka, ve které je tlačítko Odpovědět. Čte se jako jedna položka.
    { match = { clickable = true, has = { contentDescription = 'Odpovědět' } }, group = true },
    { match = { clickable = true, has = { contentDescription = 'Reply' } }, group = true },
    -- Všechno klikací uvnitř příspěvku (tlačítka, obrázky, karta reklamy) se při švihání přeskakuje.
    -- Akce příspěvku jsou v nabídce Akce, obrázky přidává tento skript.
    {
      match = { clickable = true, inside = { clickable = true, has = { contentDescription = 'Odpovědět' } } },
      hide = 'all',
    },
    {
      match = { clickable = true, inside = { clickable = true, has = { contentDescription = 'Reply' } } },
      hide = 'all',
    },
  },
}

-- Akce, podle kterých se pozná příspěvek. X je dává přímo příspěvku.
local POST_ACTIONS = {
  ['Zobrazit celou konverzaci'] = true,
  ['Odpovědět'] = true,
  ['View conversation'] = true,
  ['Reply'] = true,
}

local VERIFIED = {
  ['Ověřený'] = true, ['Ověřená'] = true, ['Ověřená organizace'] = true, ['Verified'] = true,
}

local AD = { ['Propagováno'] = true, ['Promoted'] = true, ['Ad'] = true, ['Reklama'] = true }

local MEDIA = {
  ['Obrázek'] = 'image', ['Image'] = 'image',
  ['Video'] = 'video',
  ['GIF'] = 'gif',
}

-- Konec popisku jsou počty: "Odpovědi: 22", "1 repost", "Uživatel 2 repostuje", "Lajky: 41",
-- "Ověřená zobrazení: 10287". Odebírají se odzadu, dokud segment vypadá jako počet.
local STAT_PATTERNS = {
  '^Odpověd', '^Odpověď', '^%d[%d%s,%.]*%s*odpov',
  '^Lajk', '^%d[%d%s,%.]*%s*lajk',
  '^%d[%d%s,%.]*%s*repost', '^Repost', '^Uživatel.-repost',
  '^Citac', '^%d[%d%s,%.]*%s*citac',
  '^Záložk', '^%d[%d%s,%.]*%s*záložk',
  '^Ověřená zobrazení', '^Zobrazení', '^%d[%d%s,%.]*%s*zobrazení',
  '^Repl', '^%d[%d%s,%.]*%s*repl', '^Like', '^%d[%d%s,%.]*%s*like',
  '^View', '^%d[%d%s,%.]*%s*view', '^Bookmark', '^Quote',
}

local function present(text)
  if text ~= nil and text ~= '' then
    return text
  end
end

local function trim(text)
  return (text or ''):match('^%s*(.-)%s*$')
end

local function is_stat(segment)
  for _, pattern in ipairs(STAT_PATTERNS) do
    if segment:find(pattern) then
      return true
    end
  end
  -- "Něco: 123" nebo "Něco: 1,3 tis."
  return #segment < 40 and segment:find('^[^%d:]+: [%d][%d%s,%.]*%S*$') ~= nil
end

-- Čas bývá "09 říj", "PŘED 20 HODINAMI", "3 h", "Teď".
local function is_time(segment)
  if #segment > 30 then
    return false
  end
  return segment:find('%d') ~= nil
    or segment:find('^PŘED') ~= nil or segment:find('^Před') ~= nil
    or segment:find('^TEĎ') ~= nil or segment:find('^Teď') ~= nil
    or segment:find('^Now') ~= nil or segment:find('ago$') ~= nil
end

-- Velká písmena na malá, včetně českých. "PŘED 20 HODINAMI" se pak nečte jako zkratka.
local CZECH_LOWER = {
  ['Á'] = 'á', ['Č'] = 'č', ['Ď'] = 'ď', ['É'] = 'é', ['Ě'] = 'ě', ['Í'] = 'í', ['Ň'] = 'ň',
  ['Ó'] = 'ó', ['Ř'] = 'ř', ['Š'] = 'š', ['Ť'] = 'ť', ['Ú'] = 'ú', ['Ů'] = 'ů', ['Ý'] = 'ý', ['Ž'] = 'ž',
}
local function lower_czech(text)
  -- Jen A až Z: string.lower podle nastavení systému mění i bajty znaků UTF-8.
  local result = text:gsub('[A-Z]', function(c) return string.char(c:byte() + 32) end)
  for upper, lower in pairs(CZECH_LOWER) do
    result = result:gsub(upper, lower)
  end
  return result
end

local function split_segments(text)
  local segments = {}
  local start = 1
  while true do
    local s, e = text:find('%. ', start)
    if not s then
      local last = trim(text:sub(start)):gsub('%.$', '')
      if last ~= '' then
        segments[#segments + 1] = last
      end
      break
    end
    local segment = trim(text:sub(start, s - 1))
    if segment ~= '' then
      segments[#segments + 1] = segment
    end
    start = e + 1
  end
  return segments
end

-- 1 obrázek, 2 obrázky, 5 obrázků.
local function plural(count, one, few, many)
  if count == 1 then
    return '1 ' .. one
  elseif count >= 2 and count <= 4 then
    return count .. ' ' .. few
  end
  return count .. ' ' .. many
end

local MEDIA_WORDS = {
  image = { 'obrázek', 'obrázky', 'obrázků' },
  video = { 'video', 'videa', 'videí' },
  gif = { 'GIF', 'GIFy', 'GIFů' },
}

-- Rozloží popisek příspěvku na části: kontext (např. kdo repostoval), jméno, @jméno, reklama,
-- text, média, čas a počty.
local function parse(description)
  local segments = split_segments(description)
  local post = { context = {}, body = {}, media = {}, stats = {}, ad = false }

  local handle_at
  for i, segment in ipairs(segments) do
    if segment:find('^@[%w_]+$') then
      handle_at = i
      break
    end
  end
  if not handle_at or handle_at < 2 then
    return nil
  end
  for i = 1, handle_at - 2 do
    post.context[#post.context + 1] = segments[i]
  end
  post.name = segments[handle_at - 1]
  post.handle = segments[handle_at]

  local first, last = handle_at + 1, #segments
  while first <= last and VERIFIED[segments[first]] do
    first = first + 1
  end

  local stats = {}
  while last >= first and is_stat(segments[last]) do
    table.insert(stats, 1, segments[last])
    last = last - 1
  end
  post.stats = stats

  if last >= first and is_time(segments[last]) then
    post.time = lower_czech(segments[last])
    last = last - 1
  end

  local counts = {}
  while last >= first and MEDIA[segments[last]] do
    local kind = MEDIA[segments[last]]
    counts[kind] = (counts[kind] or 0) + 1
    last = last - 1
  end
  for _, kind in ipairs({ 'image', 'video', 'gif' }) do
    if counts[kind] then
      local words = MEDIA_WORDS[kind]
      post.media[#post.media + 1] = plural(counts[kind], words[1], words[2], words[3])
    end
  end

  for i = first, last do
    local segment = segments[i]
    if AD[segment] then
      post.ad = true
    else
      post.body[#post.body + 1] = segment
    end
  end
  return post
end

local settings = {
  readHandle = sf.settings.get('readHandle') == true,
  readTime = sf.settings.get('readTime') ~= false,
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
    if present(text) then
      parts[#parts + 1] = text
    end
  end
  add(table.concat(post.context, ', '))
  add(post.name)
  if settings.readHandle then
    add(post.handle)
  end
  if post.ad then
    add('reklama')
  end
  -- Zkrácené odkazy t.co se nečtou znak po znaku.
  add((table.concat(post.body, '. '):gsub('https?://%S+', 'odkaz')))
  add(table.concat(post.media, ', '))
  if settings.readTime then
    add(post.time)
  end
  if settings.readStats then
    add(table.concat(post.stats, ', '))
  end
  return table.concat(parts, '. ')
end

local function is_post(item)
  for _, action in ipairs(item.actions or {}) do
    if POST_ACTIONS[action.label] then
      return true
    end
  end
  return false
end

-- Popisek příspěvku je u prvního potomka, který obsahuje "@jméno".
local function description_of(item)
  for _, child in ipairs(item:children()) do
    local text = child.contentDescription
    if present(text) and text:find('%. @[%w_]+%. ') then
      return text
    end
  end
end

-- Každé zaměření se počítá, aby se nepřečetl příspěvek, ze kterého už fokus odešel.
local focus_count = 0

local function say_post(item, fallback, count)
  local description = description_of(item)
  local post = description and parse(description)
  local text = post and describe(post) or fallback
  if count == focus_count and present(text) then
    sf.speak(text, { interrupt = true })
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

-- Obrázky příspěvku, které pravidla skryla, jsou v nabídce Akce.
local MAX_IMAGES = 10
sf.onActions(function(item)
  if not is_post(item) then
    return
  end
  local images = item:findAll({ className = 'ImageView', clickable = true }, MAX_IMAGES)
  local actions = {}
  for i, image in ipairs(images) do
    local label = present(image.contentDescription) or 'Obrázek'
    actions[#actions + 1] = {
      title = #images > 1 and ('Zobrazit ' .. lower_czech(label) .. ' ' .. i) or ('Zobrazit ' .. lower_czech(label)),
      run = function()
        if not image:click() then
          image:tap()
        end
      end,
    }
  end
  return actions
end)
