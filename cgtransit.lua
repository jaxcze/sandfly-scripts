local manifest = {
  id = 'cgtransit',
  name = 'CG Transit: spojení a seznamy tras',
  version = '0.0.8',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Detail spojení: každý úsek cesty se přečte jako věta (spoj, odjezd, mezizastávky, příjezd, směr) bez znaků z ikonového písma; mezizastávky se rozbalí poklepáním na úsek; tarifní pásma a dopravce jde zapnout v nastavení. Výpis spojení: každé spojení je jedna položka se spoji a časy, bez „mezerník“ a bez ohlašování odpočtu. Mapa je skrytá. Hlavní obrazovka: Odkud, Přes a Kam místo „null:“, tlačítko Vyhledat spojení má název, záložky Rychlá volba, Historie a Oblíbené říkají, která je vybraná, a seznam tras se při vstupu ohlásí jménem záložky. Trasa je jedna položka; Přidat do oblíbených, Odebrat z oblíbených a Upravit jsou v nabídce Akce.',
  apps = { 'com.circlegate.tt.transit.android' },
  permissions = { 'screen', 'speech', 'input', 'actions' },
  settings = {
    { key = 'readStops', type = 'switch', title = 'Číst mezizastávky', default = true },
    { key = 'readZones', type = 'switch', title = 'Číst tarifní pásma', default = false },
    { key = 'readAgency', type = 'switch', title = 'Číst dopravce', default = false },
  },
  rules = {
    { id = 'btn_find_journeys', label = 'Vyhledat spojení' },
    -- Rozbalení mezizastávek: poklepání na úsek; samostatné tlačítko jen překáží.
    { id = 'icon_expand', hide = true },
    -- Hvězdička a Upravit u trasy v seznamu: v nabídce Akce trasy.
    { id = 'btn_star', hide = true },
    { id = 'btn_fill', hide = true },
    -- Spojení ve výsledcích hledání je jedna položka s popisem od aplikace. Texty uvnitř mají
    -- popis jen z pevné mezery, SandFly by je četl jako „mezerník“.
    { match = { inside = { id = 'fj_result_journey' } }, hide = true },
    -- Prázdné záhlaví nad úseky v detailu spojení.
    { id = 'dummy_header', hide = true },
    -- Mapa pod detailem spojení a hlavní obrazovkou: Mapa Google, zastávky na ní, Moje poloha.
    -- Mapa kreslí své položky (zastávky) sama, pravidlo na obal na ně nedosáhne, proto i zvlášť.
    { id = 'map_wrapper_layout', hide = 'all' },
    { id = 'map_touch_delegate_view', hide = true },
    { match = { inside = { id = 'map_view' } }, hide = true },
    { match = { contentDescription = 'Mapa Google' }, hide = true },
    { match = { contentDescription = 'Moje poloha' }, hide = true },
    -- „před 15 s“ v záhlaví spojení se mění každou vteřinu; neohlašovat.
    { id = 'fj_result_journey', silence = 'all' },
  },
}

local NBSP = '\u{00A0}'
-- Znaky ikonového písma, které aplikace dává do textu.
local ICONS = {
  ['\u{F048}'] = 'bezbariérový',
  ['\u{F05A}'] = 'ikona telefonu',
  ['\u{F044}'] = 'na znamení',
}
-- Dny v poznámkách („jede v ⑥,⑦“): kroužkované číslice 1 až 7 jsou dny od pondělí do neděle,
-- kladívka pracovní dny, křížek neděle a svátky. Vkládají se bez čárky před sebou.
local DAYS = {
  ['\u{F031}'] = 'pondělí',
  ['\u{F032}'] = 'úterý',
  ['\u{F033}'] = 'středu',
  ['\u{F034}'] = 'čtvrtek',
  ['\u{F035}'] = 'pátek',
  ['\u{F036}'] = 'sobotu',
  ['\u{F037}'] = 'neděli',
  ['\u{F058}'] = 'pracovní dny',
  ['\u{F02B}'] = 'neděli a ve svátky',
}
local TABS = { ['RYCHLÁ VOLBA'] = 'Rychlá volba', ['HISTORIE'] = 'Historie', ['OBLÍBENÉ'] = 'Oblíbené' }
local TAB_ORDER = { 'RYCHLÁ VOLBA', 'HISTORIE', 'OBLÍBENÉ' }

local function present(text)
  if text ~= nil and text ~= '' then
    return text
  end
end

local function trim(text)
  return ((text or ''):gsub(NBSP, ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function short_id(item)
  return ((item.id or ''):match('[^/]*$'))
end

local function short_class(item)
  return (item.className or ''):match('[^.]*$')
end

-- Text s ikonami nahrazenými slovy, mezery sloučené.
local function words(text)
  local out = {}
  local plain = (text or ''):gsub(NBSP, ' ')
  for _, code in utf8.codes(plain) do
    local char = utf8.char(code)
    if DAYS[char] then
      out[#out + 1] = ' ' .. DAYS[char] .. ' '
    elseif ICONS[char] then
      out[#out + 1] = ', ' .. ICONS[char] .. ' '
    elseif code >= 0xE000 and code <= 0xF8FF then
      -- Jiná ikona, kterou neznáme: vynechat.
    else
      out[#out + 1] = char
    end
  end
  local result = table.concat(out):gsub('%s+', ' '):gsub('%s+,', ','):gsub(',%s*,', ',')
  return trim(result:gsub('^,%s*', ''):gsub(',%s*$', ''))
end

-- Písmena u zastávek („z“) vysvětluje aplikace v poznámkách pod spojením, např. „z – zastávka
-- na znamení v sobotu a v neděli“. Vysvětlivky se sbírají z obrazovky při čtení úseku.
local LETTERS = {}

local function collect_letters()
  LETTERS = {}
  for _, item in ipairs(sf.screen.findAll({ id = 'text' }, 60) or {}) do
    local line = trim(item.text)
    local letter, meaning = line:match('^(%a)%s*[%-–:=]%s*(.+)$')
    if letter == nil then
      letter, meaning = line:match('^(%a)%s+(.+)$')
    end
    if letter and #meaning > 3 then
      LETTERS[letter] = meaning
    end
  end
end

-- Poznámky u zastávky: trojmístné číslo je tarifní pásmo, krátké číslo nástupiště nebo stanoviště.
local function notes(text)
  local parts = {}
  for segment in (words(text) .. ','):gmatch('([^,]*),') do
    segment = trim(segment)
    local zone, rest = segment:match('^(%d%d%d)%s*(.*)$')
    if zone then
      if sf.settings.get('readZones') then
        parts[#parts + 1] = 'pásmo ' .. zone
      end
      segment = rest
    end
    -- Čísla jsou nástupiště, slova zůstávají pohromadě („na znamení“).
    local phrase = {}
    for piece in segment:gmatch('%S+') do
      if piece:find('^%d+$') then
        parts[#parts + 1] = 'nástupiště ' .. piece
      elseif piece:find('^%a$') and LETTERS[piece] then
        parts[#parts + 1] = LETTERS[piece]
      else
        phrase[#phrase + 1] = piece
      end
    end
    if #phrase > 0 then
      parts[#parts + 1] = table.concat(phrase, ' ')
    end
  end
  return table.concat(parts, ', ')
end

local function stop(name, time, note, name_first)
  local said = trim(time) .. ' ' .. trim(name)
  if name_first then
    said = trim(name) .. ' ' .. trim(time)
  end
  local extra = notes(note)
  if extra ~= '' then
    said = said .. ', ' .. extra
  end
  return said
end

-- Úsek spojení ---------------------------------------------------------------------------------

local function child_text(node, id)
  local found = node:find({ id = id })
  return found and trim(present(found.text) or '') or ''
end

local function describe_leg(leg)
  collect_letters()
  local parts = {}
  local left = child_text(leg, 'header_text_left')
  local right_node = leg:find({ id = 'header_text_right' })
  -- „43 min  24 km“: části oddělují pevné mezery.
  local right = right_node and trim(((right_node.text or ''):gsub(NBSP, '|'):gsub('|[|%s]*', ', '))) or ''
  if left ~= '' or right ~= '' then
    parts[#parts + 1] = 'Odjezd ' .. left .. (right ~= '' and (', celkem ' .. right) or '')
  end
  local trip = leg:find({ id = 'trip_name' })
  if trip then
    parts[#parts + 1] = words(trip.text)
  end
  parts[#parts + 1] = 'Odjezd ' .. stop(child_text(leg, 'stop_name_dep'), child_text(leg, 'stop_time_dep'),
    child_text(leg, 'stop_time_notes_dep'))
  if sf.settings.get('readStops') ~= false then
    local between = {}
    for _, row in ipairs(leg:children() or {}) do
      local name = row:find({ id = 'stop_name' })
      if name then
        between[#between + 1] = stop(name.text, child_text(row, 'stop_time'), child_text(row, 'stop_time_notes'), true)
      elseif short_id(row) == 'text' and present(row.text) then
        between[#between + 1] = trim(row.text):gsub('^%((.*)%)$', '%1')
      end
    end
    if #between > 0 then
      parts[#parts + 1] = 'Přes ' .. table.concat(between, '; ')
    end
  end
  parts[#parts + 1] = 'Příjezd ' .. stop(child_text(leg, 'stop_name_arr'), child_text(leg, 'stop_time_arr'),
    child_text(leg, 'stop_time_notes_arr'))
  local final = child_text(leg, 'stop_name_final')
  if final ~= '' then
    parts[#parts + 1] = 'Směr ' .. final
  end
  local agency = child_text(leg, 'txt_agency')
  if agency ~= '' and sf.settings.get('readAgency') then
    parts[#parts + 1] = agency
  end
  return table.concat(parts, '. ')
end

-- Úsek v detailu spojení: má odjezdovou i příjezdovou zastávku.
local function is_leg(item)
  -- Spojení ve výsledcích hledání má uvnitř stejné prvky, ale aplikace mu dává vlastní popis.
  if short_id(item) == 'fj_result_journey' then
    return false
  end
  return item:find({ id = 'stop_name_dep' }) ~= nil and item:find({ id = 'stop_name_arr' }) ~= nil
end

-- Hlavní obrazovka ------------------------------------------------------------------------------

local function is_tab(item)
  return short_class(item) == 'LinearLayout' and TABS[item.contentDescription or ''] ~= nil
end

local function selected_tab()
  for _, key in ipairs(TAB_ORDER) do
    local tab = sf.screen.find({ contentDescription = key })
    if tab and tab.selected then
      return TABS[key]
    end
  end
end

local function route_row(item)
  return item:find({ id = 'btn_star' }) ~= nil and item:find({ id = 'text' }) ~= nil
end

local current_list

local function describe_route(row)
  local places = {}
  for _, child in ipairs(row:findAll({ id = 'text' }, 5) or {}) do
    if present(child.text) then
      places[#places + 1] = trim(child.text)
    end
  end
  local said = table.concat(places, ' do ')
  local star = row:find({ id = 'btn_star' })
  if star and star.checked then
    said = said .. ', oblíbená'
  end
  -- Při vstupu do seznamu se řekne, která záložka to je.
  local tab = selected_tab()
  if tab and current_list ~= tab then
    current_list = tab
    said = tab .. ', seznam tras. ' .. said
  end
  return said
end

local function place_label(item, text)
  -- První pole s místem je Odkud, poslední Kam, mezi nimi Přes.
  local index = 1
  local places = sf.screen.findAll({ textContains = 'null: ' }, 6) or {}
  for i, place in ipairs(places) do
    if place == item then
      index = i
    end
  end
  local label = 'Přes'
  if index == 1 then
    label = 'Odkud'
  elseif index == #places then
    label = 'Kam'
  end
  return label .. ': ' .. trim((item.text or ''):gsub('^null: ', '')) .. ', tlačítko'
end

-- Hooky ----------------------------------------------------------------------------------------

sf.onFocus(function(item, text)
  local class = short_class(item)
  -- Plovoucí tlačítko hledání nemá popis a pravidlo s label se na něj nechytá.
  if short_id(item) == 'btn_find_journeys' then
    return 'Vyhledat spojení, tlačítko'
  end
  if (item.text or ''):find('^null: ') then
    current_list = nil
    sf.setTimeout(function()
      sf.speak(place_label(item, text), { interrupt = true })
    end, 0)
    return false
  end
  if is_tab(item) then
    current_list = nil
    local key = item.contentDescription
    local position
    for i, name in ipairs(TAB_ORDER) do
      if name == key then
        position = i
      end
    end
    return TABS[key] .. ', karta ' .. position .. ' ze ' .. #TAB_ORDER .. (item.selected and ', vybráno' or '')
  end
  -- Spojení ve výsledcích, kterému aplikace ještě nedala popis: složit ho z textů uvnitř,
  -- jinak SandFly čte jen popisy z pevných mezer („Mezerník, Mezerník“).
  if short_id(item) == 'fj_result_journey' and not present(trim(item.contentDescription or '')) then
    sf.setTimeout(function()
      -- Aplikace popis často doplní za chvíli.
      for _ = 1, 4 do
        sf.sleep(150)
        local fresh = item:refresh()
        if fresh and present(trim(fresh.contentDescription or '')) then
          sf.speak(fresh.contentDescription, { interrupt = true })
          return
        end
      end
      local parts = {}
      for _, child in ipairs(item:findAll({}, 80) or {}) do
        local t = words(child.text)
        if present(t) then
          parts[#parts + 1] = t
        end
      end
      sf.speak(present(table.concat(parts, ', ')) or text, { interrupt = true })
    end, 0)
    return false
  end
  -- Jen úsek v detailu spojení a trasa v seznamu; ostatní řádky (Bez přestupů, Čas, Další
  -- parametry, spojení ve výsledcích hledání) čte SandFly sám.
  if class == 'LinearLayout' and item.clickable then
    if is_leg(item) then
      current_list = nil
      sf.setTimeout(function()
        sf.speak(describe_leg(item) or text, { interrupt = true })
      end, 0)
      return false
    end
    if route_row(item) then
      sf.setTimeout(function()
        sf.speak(describe_route(item) or text, { interrupt = true })
      end, 0)
      return false
    end
  end
  current_list = nil
  -- Jiný text se znaky ikonového písma, např. „jede v ⑥,⑦“ v detailu spoje nebo poznámky
  -- u zastávky: ikony a dny slovy.
  if text then
    for _, code in utf8.codes(text) do
      if code >= 0xE000 and code <= 0xF8FF then
        return words(text)
      end
    end
  end
end)

sf.onActions(function(item)
  if short_class(item) ~= 'LinearLayout' or not item.clickable then
    return
  end
  local star = item:find({ id = 'btn_star' })
  if star == nil then
    return
  end
  local actions = {
    {
      title = star.checked and 'Odebrat z oblíbených' or 'Přidat do oblíbených',
      first = true,
      run = function(row)
        local fresh = row:find({ id = 'btn_star' })
        if fresh then
          fresh:click()
        end
      end,
    },
  }
  if item:find({ id = 'btn_fill' }) then
    actions[#actions + 1] = {
      title = 'Upravit trasu',
      run = function(row)
        local fill = row:find({ id = 'btn_fill' })
        if fill then
          fill:click()
        end
      end,
    }
  end
  return actions
end)
