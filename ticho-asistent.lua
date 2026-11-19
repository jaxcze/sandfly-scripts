local manifest = {
  id = 'ticho-asistent',
  name = 'Ticho při asistentovi Gemini',
  version = '0.0.3',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Dokud je na obrazovce asistent Gemini, například spuštěný podržením vypínacího tlačítka, SandFly nečte, co asistent píše a říká. Položky, na které se sami posunete dotykem nebo švihnutím, SandFly čte dál, takže odpověď jde projít i potom; když fokus přesune asistent sám, SandFly mlčí. Asistent se pozná podle balíčku v nastavení skriptu (výchozí aplikace Google a Gemini; jiný asistent jde doplnit); tlačítko Zjistit okna řekne, které aplikace měly okna na obrazovce naposledy.',
  permissions = { 'screen', 'speech', 'events' },
  settings = {
    { key = 'packages', type = 'text', title = 'Balíčky asistenta', summary = 'Víc balíčků oddělte čárkou.', default = 'com.google.android.googlequicksearchbox, com.google.android.apps.bard' },
    { key = 'readFocus', type = 'switch', title = 'Číst položky, na které se posunu', default = true },
    { key = 'debug', type = 'switch', title = 'Ladicí záznam', summary = 'Zapisuje do logu Androidu, kdy SandFly mlčí a co neřekl', default = false },
    { key = 'detect', type = 'button', title = 'Zjistit okna', summary = 'Řekne, které aplikace měly naposledy okna na obrazovce' },
  },
}

local muted = false

local function debug(text)
  if sf.settings.get('debug') then
    sf.log.error('TICHO ' .. text)
  end
end
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
    if found ~= muted then
      debug(found and 'asistent na obrazovce, SandFly mlčí' or 'asistent zavřený, SandFly mluví')
    end
    muted = found
    remember(table.concat(list, ', '))
  end
  schedule()
end

sf.onWindowChange(check)
sf.onAppEnter(check)
sf.onSettingChange(check)

-- Položku, na kterou se uživatel posunul dotykem nebo švihnutím, nechat
-- přečíst. Asistent přesouvá fokus na nový text i sám, tehdy dotyk neběží.
local touching = false
local touch_end = -10000

sf.onEvent(function(e)
  if e.type == 'touchInteractionStart' then
    touching = true
  elseif e.type == 'touchInteractionEnd' then
    touching = false
    touch_end = sf.clock()
  end
end)

sf.onFocus(function()
  if muted and sf.settings.get('readFocus') and (touching or sf.clock() - touch_end < 800) then
    pass_until = sf.clock() + 300
    debug('posun dotykem')
  end
end)

sf.onSpeech(function(text)
  if not muted then
    return
  end
  if sf.clock() < pass_until then
    debug('řekl: ' .. tostring(text):sub(1, 80))
    return
  end
  debug('neřekl: ' .. tostring(text):sub(1, 80))
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
