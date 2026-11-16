local manifest = {
  id = 'coffeelink',
  name = "De'Longhi Coffee Link: přístupnost",
  version = '0.0.1',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = "Opravy přístupnosti aplikace De'Longhi Coffee Link. Posuvníky parametrů nápoje mají název a ohlašují skutečnou hodnotu (160 ml, Silná) místo procent; hodnotu skript přečte rozpoznáním textu na obrazovce. V nabídce Akce posuvníku je Vybrat hodnotu ze seznamu. Parametry nápoje se otevřou akcí Upravit parametry, bez tažení. Tlačítka bez názvu mají popisky, srdíčka a tlačítka Příprava říkají, ke kterému nápoji patří, nadpisy jsou označené a zdvojené texty skryté. Testovací verze.",
  apps = { 'it.delonghi' },
  permissions = { 'screen', 'speech', 'input', 'actions', 'dialogs' },
  settings = {
    { key = 'readPercent', type = 'switch', title = 'U posuvníků hlásit i procenta', default = false },
  },
  commands = {
    { id = 'params', title = 'Upravit parametry nápoje', menu = true },
  },
  rules = {
    -- Nadpisy obrazovek a sekcí.
    { id = 'title_textview', heading = true },
    { id = 'common_header_title', heading = true },
    { id = 'account_det_title_tv', heading = true },
    { id = 'account_title_tv', heading = true },
    { id = 'beverageName', heading = true },
    { id = 'beverageNameBottomSheet', heading = true },
    { id = 'favorite_title', heading = true },
    { id = 'hot_label', heading = true },
    { id = 'iced_label', heading = true },
    { id = 'filterGroupTitle', heading = true },
    { id = 'recipesFiltersTitle', heading = true },
    { id = 'dialogTitle', heading = true },
    { id = 'dialog_title', heading = true },
    { id = 'coffee_machine_text_tv', heading = true },
    { id = 'settings_text_tv', heading = true },
    { id = 'account_text_tv', heading = true },
    { id = 'analytics_consent_title_tv', heading = true },
    { id = 'status_label', heading = true },
    { id = 'nameBrewBeverage', heading = true },

    -- Ikonová tlačítka bez názvu. Text pod ikonou je skrytý, aby se nečetl dvakrát.
    { id = 'create_imageview', label = 'Vytvořit nápoj' },
    { id = 'create_textview', hide = true },
    { id = 'beanadapt_imageview', label = 'Bean Adapt' },
    { id = 'beanadapt_textview', hide = true },
    { id = 'add_imageview', label = 'Přidat kávovar' },
    { id = 'add_textview', hide = true },
    { id = 'close_imageview', label = 'Zavřít banner' },
    { id = 'filter_button_layout', label = 'Filtrovat nápoje' },
    { id = 'filterIconButton', label = 'Filtrovat nápoje' },
    { id = 'text_input_start_icon', hide = true },
    { id = 'edit_text_search', hint = 'Hledat nápoj' },
    { id = 'close_btn', label = 'Zavřít' },
    { id = 'closeButton', label = 'Zavřít' },
    { id = 'btn_back', label = 'Zpět' },
    { id = 'back_btn', label = 'Zpět' },
    { match = { className = 'TextView', text = 'Zpět', clickable = false }, hide = true },
    { id = 'prefIconButton', label = 'Oblíbené' },
    { id = 'touch_outside', hide = true },

    -- Účet a profily.
    { id = 'add_profile_iw', label = 'Přidat profil' },
    { match = { className = 'TextView', text = 'Add', clickable = false }, hide = true },
    { id = 'btn_delete_account', label = 'Smazat profil' },
    { id = 'profile_logo', label = 'Ikona profilu' },
    { id = 'btn_fav_iw', hide = true },
    { id = 'btn_edit_profile_iw', hide = true },
    { id = 'btn_go_to_settings', hide = true },
    { id = 'btn_go_to_manuals', hide = true },

    -- Nastavení kávovaru: přepínače mají název, text vedle nich se neopakuje.
    { id = 'energy_saving_toggle', label = 'Úspora energie' },
    { id = 'energy_saving_tv', hide = true },
    { id = 'energy_saving_value', hide = true },
    { id = 'beep_function_toggle', label = 'Funkce zvukového signálu' },
    { id = 'beep_function_tv', hide = true },
    { id = 'beep_function_value', hide = true },

    -- Recepty: nálady jsou ikony s textem pod sebou.
    { id = 'mood_healthy_imageview', label = 'Nezvyklý' },
    { id = 'mood_energy_imageview', label = 'Energie' },
    { id = 'mood_yummy_imageview', label = 'Výborný' },
    { id = 'mood_relax_imageview', label = 'Relaxační' },
    { id = 'mood_joy_imageview', label = 'Radost' },
    { id = 'mood_healthy_textview', hide = true },
    { id = 'mood_energy_textview', hide = true },
    { id = 'mood_yummy_textview', hide = true },
    { id = 'mood_relax_textview', hide = true },
    { id = 'mood_joy_textview', hide = true },

    -- Detail nápoje: parametry dole jsou jedna položka, např. „Množství kávy 160.0 ml, Intenzita Jemná“.
    { id = 'beverageParamsList', group = true },
    { id = 'param_text', hide = true },
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

local function short_id(item)
  return ((item.id or ''):match('[^/]*$'))
end

local function text_of(item)
  return item and trim(present(item.text) or item.contentDescription) or ''
end

-- Název nápoje, ke kterému patří srdíčko nebo tlačítko Příprava: na kartě, nebo v detailu nápoje.
local function drink_name(item)
  local node = item
  for _ = 1, 3 do
    node = node:parent()
    if node == nil then
      break
    end
    local name = node:find({ id = 'beverage_name_textview' }) or node:find({ id = 'recipe_title_textview' })
    if name then
      return text_of(name)
    end
  end
  return text_of(sf.screen.find({ id = 'beverageName' }))
end

-- Pořadí položky mezi sourozenci se stejným id, např. 2. barva.
local function index_among(item)
  local parent = item:parent()
  local count = 0
  for _, child in ipairs(parent and parent:children() or {}) do
    if child.id == item.id then
      count = count + 1
      if child == item then
        return count
      end
    end
  end
end

-- Posuvníky parametrů ---------------------------------------------------------------------------

local seek -- zaměřený posuvník parametru
local token = 0

local function param_name(item)
  local parent = item:parent()
  local name = parent and parent:find({ id = 'param_text' })
  return text_of(name)
end

-- Hodnotu (160.0 ml, Jemná) aplikace jen kreslí pod jezdec, do přístupnosti ji nedává.
-- Leží v ploše posuvníku, takže ji přečte rozpoznání textu.
local function read_value(item)
  local fresh = item:refresh() or item
  local ok, result = pcall(fresh.recognizeText, fresh)
  if not ok or result == nil then
    return nil
  end
  local text = trim((result.text or ''):gsub('%s+', ' '))
  return present(text)
end

local function percent(item)
  local fresh = item:refresh() or item
  if fresh.range and fresh.range.current then
    return fresh.range.current
  end
  return tonumber((fresh.stateDescription or fresh.text or ''):match('(%d+)'))
end

local function announce_value(item, delay, interrupt)
  if interrupt == nil then
    interrupt = true
  end
  token = token + 1
  local mine = token
  sf.run(function()
    sf.sleep(delay)
    if mine ~= token then
      return
    end
    local value = read_value(item)
    if mine ~= token then
      return
    end
    sf.speak(value or 'Hodnotu se nepodařilo přečíst', { interrupt = interrupt })
  end)
end

local function say_seek(item, fallback)
  local name = param_name(item)
  local text = fallback
  if present(name) then
    text = name .. ', ' .. (fallback or '')
  end
  sf.speak(text, { interrupt = true })
  announce_value(item, 100, false)
end

-- Seznam hodnot: posuvník se projede od začátku do konce a u každého kroku se přečte hodnota.
-- Pak se nastaví ta vybraná. Uložit musí uživatel tlačítkem Uložit.
local function choose_value(item)
  sf.speak('Zjišťuji hodnoty, chvíli to potrvá', { interrupt = true })
  local start = percent(item)
  for _ = 1, 100 do
    local before = percent(item)
    item:scrollBackward()
    sf.sleep(80)
    if percent(item) == before then
      break
    end
  end
  local values, steps = {}, {}
  local step = 0
  for _ = 1, 100 do
    sf.sleep(250)
    local value = read_value(item)
    if value and not steps[value] then
      steps[value] = step
      values[#values + 1] = value
    end
    local before = percent(item)
    item:scrollForward()
    sf.sleep(80)
    if percent(item) == before then
      break
    end
    step = step + 1
  end
  if #values == 0 then
    sf.speak('Hodnoty se nepodařilo přečíst', { interrupt = true })
    return
  end
  local chosen = sf.ui.choose(param_name(item) ~= '' and param_name(item) or 'Hodnota', values)
  local target = chosen and steps[chosen]
  if target == nil then
    -- Zrušeno: posuvník zpět na původní místo.
    target = nil
  end
  for _ = 1, 100 do
    local before = percent(item)
    item:scrollBackward()
    sf.sleep(80)
    if percent(item) == before then
      break
    end
  end
  if target == nil then
    for _ = 1, 100 do
      if start == nil or (percent(item) or 0) >= start then
        break
      end
      local before = percent(item)
      item:scrollForward()
      sf.sleep(80)
      if percent(item) == before then
        break
      end
    end
    item:focus()
    return
  end
  for _ = 1, target do
    item:scrollForward()
    sf.sleep(80)
  end
  item:focus()
  sf.sleep(250)
  sf.speak((read_value(item) or chosen) .. '. Nezapomeňte uložit.', { interrupt = true })
end

-- Otevření parametrů nápoje: aplikace to umí jen tažením spodního panelu nahoru.
local function open_params()
  local peek = sf.screen.find({ id = 'beverageParamsList' })
  if sf.screen.find({ id = 'param_seekbar' }) then
    local first = sf.screen.find({ id = 'param_seekbar' })
    first:focus()
    return
  end
  if peek == nil or peek.bounds == nil then
    sf.speak('Tady parametry nápoje nejsou', { interrupt = true })
    return
  end
  local b = peek.bounds
  local x = (b.left + b.right) // 2
  local y = b.top + 20
  sf.touch.swipe(x, y, x, 300, 500)
  local first = sf.screen.waitFor({ id = 'param_seekbar' }, 3000)
  if first then
    first:focus()
  else
    sf.speak('Parametry se nepodařilo otevřít', { interrupt = true })
  end
end

-- Hooky ----------------------------------------------------------------------------------------

sf.onFocus(function(item, text)
  local id = short_id(item)
  if id == 'param_seekbar' then
    seek = item
    sf.setTimeout(say_seek, 0, item, text)
    return false
  end
  seek = nil
  if id == 'prefIconButton' or id == 'beverageBrewButton' then
    sf.setTimeout(function()
      local name = drink_name(item)
      local label = id == 'prefIconButton' and 'Oblíbené' or 'Příprava'
      if present(name) and text then
        local said = text:gsub('^' .. label, label .. ': ' .. name, 1)
        sf.speak(said, { interrupt = true })
      else
        sf.speak(text or label, { interrupt = true })
      end
    end, 0)
    return false
  end
  if id == 'circle_image_view' or id == 'profile_image_view' then
    sf.setTimeout(function()
      local n = index_among(item) or ''
      local label = id == 'circle_image_view' and 'Barva ' or 'Ikona '
      sf.speak(label .. n .. (item.selected and ', vybráno' or '') .. ', tlačítko', { interrupt = true })
    end, 0)
    return false
  end
end)

-- Změna posuvníku: SandFly hlásí procenta, místo nich se řekne skutečná hodnota.
sf.onSpeech(function(text)
  if seek ~= nil and text ~= nil and #text < 30
    and (text:find('^%s*%d+%s*%%') or text:find('^%s*%d+%s*procent')) then
    if sf.settings.get('readPercent') then
      announce_value(seek, 250, false)
      return
    end
    announce_value(seek, 250, true)
    return false
  end
end)

sf.onActions(function(item)
  local id = short_id(item)
  if id == 'param_seekbar' then
    return {
      { title = 'Vybrat hodnotu ze seznamu', first = true, run = choose_value },
      { title = 'Přečíst hodnotu', run = function(target) announce_value(target, 0) end },
    }
  end
  if id == 'beverageParamsList' or id == 'beverageName' or id == 'button_brew_1' then
    return { { title = 'Upravit parametry', first = true, run = open_params } }
  end
end)

sf.onCommand('params', function()
  open_params()
end)
