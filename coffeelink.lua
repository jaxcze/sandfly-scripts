local manifest = {
  id = 'coffeelink',
  name = "De'Longhi Coffee Link: přístupnost",
  version = '0.0.7',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = "Opravy přístupnosti aplikace De'Longhi Coffee Link. Posuvníky parametrů nápoje mají název a ohlašují skutečnou hodnotu (160 ml, Silná) místo procent; hodnotu skript přečte rozpoznáním textu na obrazovce. V nabídce Akce posuvníku je Vybrat hodnotu ze seznamu. Parametry nápoje se otevřou akcí Upravit parametry, bez tažení. Oblíbené nápoje nahoře říkají, že se poklepáním rovnou připraví, karty v seznamu otevřou detail. Průběh přípravy se ohlašuje podle nastavení. Průvodce Vytvořit říká číslo kroku, vybranou velikost a pořadí obrázku. Průvodce Bean Adapt říká číslo kroku, stav voleb směsi a pražení a úroveň mletí na kolečku mlýnku (v nabídce Akce je Vybrat úroveň mletí ze seznamu); tlačítko OK v kroku Příprava upozorní, že spustí přípravu espressa. Výběr profilu říká, který profil je vybraný. Tlačítka bez názvu mají popisky, srdíčka a tlačítka Příprava říkají, ke kterému nápoji patří, nadpisy jsou označené a zdvojené texty skryté.",
  apps = { 'it.delonghi' },
  permissions = { 'screen', 'speech', 'input', 'actions', 'dialogs' },
  settings = {
    { key = 'readPercent', type = 'switch', title = 'U posuvníků hlásit i procenta', default = false },
    {
      key = 'brewNotify', type = 'list', title = 'Průběh přípravy nápoje', default = 'phase',
      options = {
        { value = 'none', label = 'Nehlásit' },
        { value = 'sound', label = 'Jen krátký zvuk při změně fáze' },
        { value = 'phase', label = 'Hlásit fáze (Dodání, hotovo)' },
        { value = 'percent', label = 'Hlásit fáze a procenta po čtvrtinách' },
      },
    },
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
    { id = 'password_value_modify_tv', label = 'Upravit heslo' },
    -- Nastavení kávovaru: nadpisy podstránek, řádky statistiky jako jedna položka.
    { id = 'water_hardness_title_tv', heading = true },
    { id = 'aut_off_title_tv', heading = true },
    { id = 'aut_on_title_tv', heading = true },
    { id = 'statistic_title_tv', heading = true },
    { match = { parentId = 'statisticsRw' }, group = true },
    { id = 'info_icon', hide = true },
    { id = 'information_text_tv', heading = true },
    { id = 'password_text_tv', heading = true },
    { id = 'select_color_text', heading = true },
    { id = 'title', heading = true },

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

    -- Vytvořit nápoj: průvodce o třech krocích. Ukazatel kroků je obrázek, krok se řekne u nadpisu.
    { id = 'statusViewScroller', hide = 'all' },
    { id = 'customFontTextView8', heading = true },
    { id = 'radioSelection', hide = true },
    { id = 'nextButton', label = 'Další krok' },
    { id = 'backButton', label = 'Předchozí krok' },
    { id = 'ingredientParamsList', group = true },
    { id = 'infoIcon', hide = true },

    -- Bean Adapt: průvodce o pěti krocích (Směs, Pražení, Mletí, Příprava, Chuť).
    { id = 'titleTv', heading = true },
    { id = 'beanAdaptTitle', heading = true },
    { id = 'selectionButton', hide = true },
    { id = 'beanAdaptInfoButton', label = 'Informace' },
    { id = 'tv_grinderValue', hide = true },
    { id = 'tv_1', hide = true }, { id = 'tv_2', hide = true }, { id = 'tv_3', hide = true },
    { id = 'tv_4', hide = true }, { id = 'tv_5', hide = true }, { id = 'tv_6', hide = true },
    { id = 'tv_7', hide = true },
    -- Vodní filtr: příručka v okně prohlížeče.
    { id = 'webViewBackBtn', label = 'Zpět' },

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

-- Pořadí položky mezi položkami se stejným id, např. 2. barva. Každá bývá ve vlastním obalu,
-- proto se hledá v nejbližším předkovi, který jich obsahuje víc.
local function index_among(item)
  local node = item
  for _ = 1, 4 do
    node = node:parent()
    if node == nil then
      return nil
    end
    local same = node:findAll({ id = short_id(item) }, 20)
    if #same > 1 then
      for i, other in ipairs(same) do
        if other == item then
          return i
        end
      end
      return nil
    end
  end
end

-- Posuvníky parametrů ---------------------------------------------------------------------------

local seek -- zaměřený posuvník parametru
local token = 0

local function param_name(item)
  local parent = item:parent()
  local name = parent and parent:find({ id = 'param_text' })
  if name then
    return text_of(name)
  end
  -- Tvrdost vody v nastavení kávovaru: posuvník bez názvu, název je nadpis obrazovky.
  return text_of(sf.screen.find({ id = 'water_hardness_title_tv' }))
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

-- Položky, jejichž řeč skript skládá sám ----------------------------------------------------------

local function speak_unique(item, text)
  if present(text) then
    sf.speak(text, { interrupt = true })
  end
end

-- Aktivní profil aplikace ukazuje jen jako popisek spodní položky Účet.
local function active_profile()
  local account = sf.screen.find({ id = 'navigation_account' })
  local name = account and trim(account.contentDescription)
  if name == '' or name == 'Účet' then
    return nil
  end
  return name
end

local STEPS = { ['Velikost'] = 1, ['Přísady'] = 2, ['Název'] = 3, ['Název a obrázek'] = 3 }
-- Bean Adapt: nadpis kroku → číslo kroku a název v ukazateli kroků (ukazatel je jen obrázek).
local BEAN_STEPS = {
  ['Kávová směs'] = { 1, 'Směs' },
  ['Úroveň pražení'] = { 2, 'Pražení' },
  ['Úroveň mletí'] = { 3, 'Mletí' },
  ['Příprava espressa'] = { 4, 'Příprava' },
}
-- Kolečko mlýnku: přepínače bez názvu, pořadí ve stromu neodpovídá hodnotám.
local GRIND = { '1', '1_5', '2', '2_5', '3', '3_5', '4', '4_5', '5', '5_5', '6', '6_5', '7' }

local function in_bean_adapt()
  return ((sf.app() or {}).activity or ''):find('BeanAdapt') ~= nil
end

local function grind_label(value)
  return (value:gsub('_', ','))
end

local function choose_grind()
  local names, current = {}, nil
  for i, value in ipairs(GRIND) do
    local radio = sf.screen.find({ id = 'rb_' .. value })
    names[i] = 'Úroveň ' .. grind_label(value) .. ((radio and radio.checked) and ', vybráno' or '')
  end
  -- sf.ui.choose vrací text vybrané položky.
  local chosen = sf.ui.choose('Úroveň mletí', names)
  for i, name in ipairs(names) do
    if name == chosen then
      local radio = sf.screen.find({ id = 'rb_' .. GRIND[i] })
      if radio then
        radio:click()
        sf.speak('Úroveň mletí ' .. grind_label(GRIND[i]), { interrupt = true })
      end
    end
  end
end

local function bean_step(item, text)
  local title = trim(text_of(item))
  local step = in_bean_adapt() and BEAN_STEPS[title]
  if step then
    return 'Krok ' .. step[1] .. ' z 5, ' .. step[2] .. ': ' .. title .. ', nadpis'
  end
  return text
end

-- Změnit ikonku: ikony a barvy jsou jen obrázky, pořadí podle obrazovky z listopadu 2026.
ICONS = { 'Ikona 1: postava s krátkými vlasy', 'Ikona 2: postava s delšími vlasy', 'Ikona 3: postava s krátkými vlasy, jiný účes' }
COLORS = { 'Modrá', 'Zelená', 'Oranžová', 'Růžová' }

local SPECIAL = {
  -- Výběr profilu na obrazovce Účet.
  profile_container = function(item, text)
    local name = text_of(item:find({ id = 'account_name_tv' }))
    if name == '' then
      return text
    end
    if name == active_profile() then
      return name .. ', vybraný profil'
    end
    return name .. ', přepnout na tento profil'
  end,
  -- Spodní navigace: Účet má jako popisek jméno profilu.
  navigation_account = function(item, text)
    local name = active_profile()
    if name then
      return (text or ''):gsub('^' .. name:gsub('%p', '%%%0'), 'Účet, profil ' .. name, 1)
    end
    return text
  end,
  -- Oblíbené nápoje v řádku nahoře: poklepání nápoj rovnou připraví.
  favorite_recipe_item_layout = function(item, text)
    local name = text_of(item:find({ id = 'recipe_title_textview' }))
    if name == '' then
      return text
    end
    return name .. ', poklepáním se rovnou připraví'
  end,
  -- Karta nápoje v seznamu otevře detail s parametry.
  cardContainer = function(item, text)
    local name = text_of(item:find({ id = 'beverage_name_textview' }))
    if name == '' then
      return text
    end
    return name .. ', detail a parametry nápoje'
  end,
  -- Průvodce Vytvořit: nadpis kroku řekne i číslo kroku.
  customFontTextView8 = function(item, text)
    local title = text_of(item)
    local step = STEPS[title]
    if step then
      return 'Krok ' .. step .. ' ze 3: ' .. title .. ', nadpis'
    end
    return text
  end,
  -- Karta velikosti s přepínačem: stav přepínače k názvu.
  itemCard = function(item, text)
    local radio = item:find({ id = 'radioSelection' })
    local name = text_of(item:find({ id = 'nameSelection' }))
    local size = text_of(item:find({ id = 'subNameSelection' }))
    local said = name .. (size ~= '' and (', ' .. size) or '')
    if name == '' then
      -- Krok Název a obrázek: obrázky nápoje nemají název.
      said = 'Obrázek ' .. (index_among(item) or '')
    end
    if radio and radio.checked then
      said = said .. ', vybráno'
    end
    return said
  end,
  -- Bean Adapt: nadpis kroku řekne číslo kroku.
  beanAdaptTitle = bean_step,
  title = bean_step,
  -- Bean Adapt, krok Příprava: OK spustí přípravu zkušebního espressa.
  nextButtonText = function(item, text)
    if in_bean_adapt() and text_of(item) == 'OK' then
      return 'OK, spustí přípravu zkušebního espressa, tlačítko'
    end
    return text
  end,
  -- Přísady: Upravit a Odebrat u karty přísady.
  ingredientParamEdit = function(item)
    local parent = item:parent()
    local name = text_of(parent and parent:find({ id = 'ingredientName' }))
    return 'Upravit přísadu ' .. name .. ', tlačítko'
  end,
  ingredientParamDelete = function(item)
    local parent = item:parent()
    local name = text_of(parent and parent:find({ id = 'ingredientName' }))
    return 'Odebrat přísadu ' .. name .. ', tlačítko'
  end,
}

-- Průběh přípravy: aplikace fázi ani procenta neohlašuje.
local last_phase, last_quarter

sf.onContentChange(function(event)
  local mode = sf.settings.get('brewNotify') or 'phase'
  local activity = (sf.app() or {}).activity or ''
  if mode == 'none' or not activity:find('BrewBeverages') then
    last_phase, last_quarter = nil, nil
    return
  end
  local phase = sf.screen.find({ id = 'phaseBrewBeverage' })
  local header = sf.screen.find({ id = 'common_header_title' })
  local header_text = text_of(header)
  if phase == nil and header_text ~= 'Nápoj je připraven' then
    last_phase, last_quarter = nil, nil
    return
  end
  local now = phase and text_of(phase) or header_text
  if now ~= '' and now ~= last_phase then
    last_phase = now
    if mode == 'sound' then
      sf.playSound('end')
    else
      sf.speak(now, { interrupt = false })
    end
  end
  if mode == 'percent' then
    local progress = sf.screen.find({ id = 'progressPercentageBrewBeverage' })
    local value = tonumber(text_of(progress):match('(%d+)'))
    if value then
      local quarter = value // 25
      if last_quarter ~= nil and quarter > last_quarter and quarter < 4 then
        sf.speak(quarter * 25 .. ' %', { interrupt = false })
      end
      last_quarter = quarter
    end
  end
end)

-- Oblasti se seznamy nápojů: při vstupu do oblasti se nejdřív řekne její název, jako legenda
-- skupiny formuláře. Uvnitř oblasti už ne, dokud fokus neodejde jinam.
local REGIONS = {
  favoriteBeverages = 'Oblíbené nápoje, rychlá příprava',
  hot_beverages_list = 'Horké nápoje',
  iced_beverages_list = 'Studené nápoje',
  beverages_rv = 'Oblíbené nápoje',
}
local IN_REGION = {
  favorite_recipe_item_layout = true, cardContainer = true, prefIconButton = true, beverageBrewButton = true,
}
local current_region

local function region_of(item)
  local node = item
  for _ = 1, 6 do
    node = node:parent()
    if node == nil then
      return nil
    end
    local id = short_id(node)
    if REGIONS[id] then
      return id
    end
  end
end

local function with_region(item, text)
  local region = region_of(item)
  if region == nil then
    current_region = nil
    return text
  end
  if region ~= current_region then
    current_region = region
    local list = sf.screen.find({ id = region })
    local count = list and list.collection and list.collection.rows
    local legend = REGIONS[region]
    if count and count > 0 then
      legend = legend .. ', ' .. count .. (count == 1 and ' nápoj' or (count < 5 and ' nápoje' or ' nápojů'))
    end
    return legend .. '. ' .. (text or '')
  end
  return text
end

-- Hooky ----------------------------------------------------------------------------------------

sf.onFocus(function(item, text)
  local id = short_id(item)
  if not IN_REGION[id] then
    current_region = nil
  end
  if id == 'param_seekbar' then
    seek = item
    sf.setTimeout(say_seek, 0, item, text)
    return false
  end
  seek = nil
  -- Bean Adapt, kolečko mlýnku: přepínač rb_4_5 je úroveň 4,5.
  local grind = id:match('^rb_([%d_]+)$')
  if grind then
    return 'Úroveň mletí ' .. grind_label(grind) .. (item.checked and ', vybráno' or '') .. ', přepínač'
  end
  -- Bean Adapt, směs a pražení: karta s textem, přepínač v ní je skrytý.
  if (item.className or ''):find('CardView$') and item:find({ id = 'selectionText' }) then
    local radio = item:find({ id = 'selectionButton' })
    return text_of(item:find({ id = 'selectionText' })) .. ((radio and radio.checked) and ', vybráno' or '')
      .. ', přepínač'
  end
  if id == 'prefIconButton' or id == 'beverageBrewButton' then
    sf.setTimeout(function()
      local name = drink_name(item)
      local label = id == 'prefIconButton' and 'Oblíbené' or 'Příprava'
      local said = text or label
      if present(name) and text then
        said = text:gsub('^' .. label, label .. ': ' .. name, 1)
      end
      sf.speak(with_region(item, said), { interrupt = true })
    end, 0)
    return false
  end
  local special = SPECIAL[id]
  if special then
    sf.setTimeout(function()
      local said = special(item, text) or text
      if IN_REGION[id] then
        said = with_region(item, said)
      end
      speak_unique(item, said)
    end, 0)
    return false
  end
  -- Záložky Nápoje a Recepty v Oblíbených: vybraná záložka je ta, na kterou nejde klepnout.
  if (item.className or ''):find('LinearLayout$') and present(item.contentDescription) then
    sf.setTimeout(function()
      local parent = item:parent()
      local grand = parent and parent:parent()
      if short_id(parent or item) == 'tab_layout' or (grand and short_id(grand) == 'tab_layout') then
        sf.speak(item.contentDescription .. ', karta' .. (item.clickable and '' or ', vybráno'), { interrupt = true })
      else
        sf.speak(text or item.contentDescription, { interrupt = true })
      end
    end, 0)
    return false
  end
  if id == 'circle_image_view' or id == 'profile_image_view' then
    sf.setTimeout(function()
      local n = index_among(item)
      local names = id == 'circle_image_view' and COLORS or ICONS
      local label = n and names[n] or ((id == 'circle_image_view' and 'Barva ' or 'Ikona ') .. (n or ''))
      sf.speak(label .. (item.selected and ', vybráno' or '') .. ', tlačítko', { interrupt = true })
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
  if id:find('^rb_[%d_]+$') then
    return { { title = 'Vybrat úroveň mletí ze seznamu', first = true, run = choose_grind } }
  end
  if id == 'beverageParamsList' or id == 'beverageName' or id == 'button_brew_1' then
    return { { title = 'Upravit parametry', first = true, run = open_params } }
  end
end)

sf.onCommand('params', function()
  open_params()
end)
