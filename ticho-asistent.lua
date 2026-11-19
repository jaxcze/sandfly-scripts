local manifest = {
  id = 'ticho-asistent',
  name = 'Ticho při hlasovém asistentovi',
  version = '0.0.1',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Dokud je na obrazovce hlasový asistent, například Gemini spuštěný podržením vypínacího tlačítka, SandFly nečte, co asistent píše a říká. Položky, na které se sami posunete, SandFly čte dál, takže odpověď jde projít i potom. Asistent se pozná podle balíčku v nastavení skriptu (výchozí aplikace Google a Gemini); tlačítko Zjistit okna řekne, které aplikace měly okna na obrazovce naposledy.',
  permissions = { 'screen', 'speech' },
  settings = {
    { key = 'packages', type = 'text', title = 'Balíčky asistenta', summary = 'Víc balíčků oddělte čárkou.', default = 'com.google.android.googlequicksearchbox, com.google.android.apps.bard' },
    { key = 'readFocus', type = 'switch', title = 'Číst položky, na které se posunu', default = true },
    { key = 'detect', type = 'button', title = 'Zjistit okna', summary = 'Řekne, které aplikace měly naposledy okna na obrazovce' },
  },
}

local muted = false
local timer = nil
local pass_until = 0

local function packages()
  local set = {}
  for part in (sf.settings.get('packages') or ''):gmatch('[^,]+') do
    part = part:gsub('^%s+', ''):gsub('%s+$', '')
    if part ~= '' then
      set[part] = true
    end
  end
  return set
end

local function window_packages()
  local ok, windows = pcall(sf.screen.windows)
  if not ok or not windows then
    return nil
  end
  local list = {}
  for _, w in ipairs(windows) do
    if w.type ~= 'inputMethod' and w.root and w.root.packageName then
      list[#list + 1] = w.root.packageName
    end
  end
  return list
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
  timer = sf.setTimeout(check, muted and 400 or 2000)
end

check = function()
  local list = window_packages()
  if list then
    local wanted = packages()
    local found = false
    for _, pkg in ipairs(list) do
      if wanted[pkg] then
        found = true
      end
    end
    muted = found
    remember(table.concat(list, ', '))
  end
  schedule()
end

sf.onWindowChange(check)
sf.onAppEnter(check)
sf.onSettingChange(check)

-- Položku, na kterou se uživatel posunul, nechat přečíst.
sf.onFocus(function()
  if muted and sf.settings.get('readFocus') then
    pass_until = sf.clock() + 300
  end
end)

-- Ozvěnu psaní taky nechat, kdyby se psalo přímo asistentovi.
sf.onTextChange(function()
  if muted then
    pass_until = sf.clock() + 300
  end
end)

sf.onSpeech(function()
  if not muted or sf.clock() < pass_until then
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

check()
