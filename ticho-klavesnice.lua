local manifest = {
  id = 'ticho-klavesnice',
  name = 'Ticho při mluvící klávesnici',
  version = '0.0.1',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Dokud je na obrazovce klávesnice, která mluví sama, například Corvus, SandFly mlčí ve všech aplikacích. Po zavření klávesnice mluví zase normálně. Klávesnice se pozná podle části názvu balíčku v nastavení skriptu (výchozí corvus); tlačítko Zjistit klávesnici řekne balíček klávesnice, která byla naposledy na obrazovce.',
  permissions = { 'screen', 'speech' },
  settings = {
    { key = 'match', type = 'text', title = 'Část názvu balíčku klávesnice', summary = 'Například corvus. Víc klávesnic oddělte čárkou.', default = 'corvus' },
    { key = 'notifications', type = 'switch', title = 'Při psaní číst notifikace', default = false },
    { key = 'detect', type = 'button', title = 'Zjistit klávesnici', summary = 'Řekne balíček klávesnice, která byla naposledy na obrazovce' },
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

local function keyboard_package()
  local ok, windows = pcall(sf.screen.windows)
  if not ok or not windows then
    return nil
  end
  for _, w in ipairs(windows) do
    if w.type == 'inputMethod' and w.root then
      return w.root.packageName
    end
  end
end

local function talking_keyboard(pkg)
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

local check

local function schedule()
  if timer then
    sf.clearTimer(timer)
  end
  -- Když SandFly mlčí, hlídat často, aby po zavření klávesnice hned mluvil.
  timer = sf.setTimeout(check, muted and 400 or 2000)
end

check = function()
  local pkg = keyboard_package()
  if pkg and pkg ~= sf.storage.get('lastKeyboard') then
    sf.storage.set('lastKeyboard', pkg)
  end
  local now = talking_keyboard(pkg)
  if now ~= muted then
    sf.log.info((now and 'SandFly mlčí, klávesnice ' or 'SandFly mluví, klávesnice ') .. tostring(pkg))
  end
  muted = now
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
  local pkg = sf.storage.get('lastKeyboard')
  if not pkg then
    tell('Zatím jsem žádnou klávesnici neviděl. Otevřete klávesnici v nějakém textovém poli a zkuste to znovu.')
  elseif talking_keyboard(pkg) then
    tell('Naposledy byla na obrazovce klávesnice ' .. pkg .. '. Odpovídá nastavení, SandFly při ní mlčí.')
  else
    tell('Naposledy byla na obrazovce klávesnice ' .. pkg .. '. Nastavení jí neodpovídá. Jestli má SandFly při ní mlčet, napište do nastavení část jejího názvu.')
  end
end)

sf.onSettingChange(check)

check()
