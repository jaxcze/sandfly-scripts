local manifest = {
  id = 'ticho-klavesnice',
  name = 'Ticho při mluvící klávesnici',
  version = '0.0.2',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Dokud je na obrazovce klávesnice nebo aplikace, která mluví sama, například Corvus, SandFly mlčí. Když se klávesnice zavře nebo aplikace odejde z popředí, SandFly mluví zase normálně. Pozná se podle části názvu balíčku v nastavení skriptu (výchozí corvus); hlídá klávesnici, aplikaci v popředí i okna, která aplikace kreslí přes obrazovku. Tlačítko Zjistit okna řekne, co bylo naposledy na obrazovce.',
  permissions = { 'screen', 'speech' },
  settings = {
    { key = 'match', type = 'text', title = 'Část názvu balíčku', summary = 'Například corvus. Víc aplikací oddělte čárkou.', default = 'corvus' },
    { key = 'notifications', type = 'switch', title = 'Číst notifikace, i když SandFly mlčí', default = false },
    { key = 'debug', type = 'switch', title = 'Ladicí záznam', summary = 'Zapisuje do logu Androidu, kdy SandFly mlčí a proč', default = false },
    { key = 'detect', type = 'button', title = 'Zjistit okna', summary = 'Řekne, které klávesnice a aplikace byly naposledy na obrazovce' },
  },
}

local muted = false
local timer = nil
local pass_until = 0

local function patterns()
  local list = {}
  for part in (sf.settings.get('match') or ''):gmatch('[^,]+') do
    part = part:gsub('^%s+', ''):gsub('%s+$', ''):lower()
    if part ~= '' then
      list[#list + 1] = part
    end
  end
  return list
end

local function matches(pkg)
  if not pkg then
    return false
  end
  pkg = pkg:lower()
  for _, p in ipairs(patterns()) do
    if pkg:find(p, 1, true) then
      return true
    end
  end
  return false
end

local function debug(text)
  if sf.settings.get('debug') then
    sf.log.error('TICHO ' .. text)
  end
end

local KINDS = { inputMethod = 'klávesnice', application = 'aplikace', accessibilityOverlay = 'okno přes obrazovku', system = 'systémové okno' }

-- Okna na obrazovce jako text, a které z nich patří aplikaci z nastavení.
local function scan()
  local ok, windows = pcall(sf.screen.windows)
  if not ok or not windows then
    return nil
  end
  local seen, hit = {}, nil
  for _, w in ipairs(windows) do
    local pkg = w.root and w.root.packageName
    if pkg then
      local kind = KINDS[w.type] or tostring(w.type)
      seen[#seen + 1] = kind .. ' ' .. pkg
      if not hit and matches(pkg) and w.type ~= 'system' then
        hit = kind .. ' ' .. pkg
      end
    end
  end
  return seen, hit
end

-- Posledních pět různých sestav oken, pro tlačítko Zjistit okna.
local function remember(text)
  if text == '' then
    return
  end
  local history = sf.storage.get('windows', {})
  if history[1] == text then
    return
  end
  for i = #history, 1, -1 do
    if history[i] == text then
      table.remove(history, i)
    end
  end
  table.insert(history, 1, text)
  while #history > 5 do
    table.remove(history)
  end
  sf.storage.set('windows', history)
end

local check

local function schedule()
  if timer then
    sf.clearTimer(timer)
  end
  -- Když SandFly mlčí, hlídat často, aby po zavření hned mluvil.
  timer = sf.setTimeout(check, muted and 400 or 2000)
end

check = function()
  local seen, hit = scan()
  if seen then
    remember(table.concat(seen, ', '))
    local now = hit ~= nil
    if now ~= muted then
      debug(now and ('SandFly mlčí: ' .. hit) or 'SandFly mluví')
    end
    muted = now
  end
  schedule()
end

sf.onWindowChange(check)
sf.onInputFocus(check)
sf.onAppEnter(check)

sf.onNotification(function()
  if muted and sf.settings.get('notifications') then
    pass_until = sf.clock() + 500
  end
end)

sf.onSpeech(function(text)
  if not muted then
    return
  end
  if sf.clock() < pass_until then
    return
  end
  return false
end)

local function tell(text)
  sf.settings.setSummary('detect', text)
  sf.message(text)
end

sf.onButton(function(key)
  if key ~= 'detect' then
    return
  end
  local history = sf.storage.get('windows', {})
  if #history > 0 then
    tell('Okna na obrazovce, od nejnovějších: ' .. table.concat(history, '; ') .. '.')
  else
    tell('Zatím jsem žádná okna neviděl.')
  end
end)

sf.onSettingChange(check)

check()
