-- Messenger Navigace Zpráv CZ (com.facebook.orca) - Verze 4.0 + skrytí avatarů
-- 100% původní logika navigace z verze 4.0 (vidět jsou všechny zprávy, bez přeskakování),
-- doplněná pouze o pravidla skrytí mini-avatarů ("Otevřít profil...") a oddílu "Právě aktivní".

local manifest = {
  id = 'messenger-fix-cz',
  name = 'Messenger Navigace Zpráv (CZ)',
  version = '4.0-rules-cz',
  author = 'Tomáš Hromádka (úprava skriptu SandFly Custom)',
  description = 'Nativní rychlost pohybu ve zprávách s automatickým odrolováním na okraji obrazovky bez útěku na tlačítka hovoru a bez avatarů.',
  minApiVersion = 2,
  testedApiVersion = 3,
  apps = { 'com.facebook.orca' },
  permissions = { 'screen', 'actions', 'input', 'speech' },
  commands = {
    { id = 'msg_prev', title = 'Předchozí zpráva (vlevo)', gesture = 'swipeLeft' },
    { id = 'msg_next', title = 'Další zpráva (vpravo)', gesture = 'swipeRight' },
    { id = 'jump_bottom', title = 'Skočit do pole pro psaní', gesture = { 'twoFingerSwipeRight', 'threeFingerSwipeRight' }, keys = 'sf+j' },
  },
  rules = {
    -- Skrytí mini-avatarů odesílatele v konverzaci
    { match = { contentDescription = 'Otevřít profil*' }, hide = true },
    { match = { contentDescription = 'Open profile*' }, hide = true },
    -- Skrytí oddílu "Právě aktivní" na seznamu chatů
    { match = { text = 'Právě aktivní' }, hide = true },
    { match = { contentDescription = 'Právě aktivní' }, hide = true },
    { match = { text = 'Active now' }, hide = true },
    { match = { contentDescription = 'Active now' }, hide = true },
  },
}

-- ---------------------------------------------------------------------------
-- Pomocné funkce (100% původní verze 4.0)
-- ---------------------------------------------------------------------------

local function nodeLabel(node)
  if node == nil then return '' end
  local d = node.contentDescription
  if d ~= nil and d ~= '' then return d end
  local t = node.text
  if t ~= nil and t ~= '' then return t end
  return ''
end

local function quickSig(node)
  local l = nodeLabel(node)
  if l ~= '' then return l end
  local kids = node:children()
  if kids ~= nil then
    for i = 1, #kids do
      local kl = nodeLabel(kids[i])
      if kl ~= '' then return kl end
    end
  end
  return ''
end

-- Určí horní a dolní hranici samotných zpráv (pod jménem v záhlaví a nad lištou psaní)
local function getChatZone()
  local inputBox = sf.screen.find({ className = 'EditText' })
  if inputBox == nil or not inputBox.visible then
    return nil
  end

  local root = sf.screen.root()
  local screenH = (root and root.bounds and root.bounds.bottom) or 2200
  local screenW = (root and root.bounds and root.bounds.right) or 1080

  -- Horní lišta v Messengeru zabírá cca 12-14 % výšky (včetně podnadpisu Právě aktivní pod jménem)
  local topY = math.floor(screenH * 0.14)
  local topBtn = sf.screen.find({ contentDescription = 'Videohovor' })
    or sf.screen.find({ contentDescription = 'Audiohovor' })
    or sf.screen.find({ contentDescription = 'Hovor' })
    or sf.screen.find({ contentDescription = 'Zpět' })

  if topBtn ~= nil and topBtn.bounds ~= nil and topBtn.bounds.bottom ~= nil then
    if topBtn.bounds.bottom > 40 and topBtn.bounds.bottom < screenH * 0.25 then
      topY = topBtn.bounds.bottom + 12
    end
  end

  -- Spodní hranice nad lištou s tlačítky (Další možnosti / Fotoaparát / EditText)
  local bottomY = (inputBox.bounds and inputBox.bounds.top) and (inputBox.bounds.top - 12) or math.floor(screenH * 0.88)

  return {
    topY = topY,
    bottomY = bottomY,
    screenW = screenW,
    screenH = screenH,
    inputBox = inputBox,
  }
end

-- Najde krajní (nejvyšší a nejnižší) viditelný prvek se zprávou v chatovací zóně
local function getEdgeMessages(zone)
  local all = sf.screen.findAll({ focusable = true }, 100) or {}
  local topNode, topY = nil, 999999
  local botNode, botY = nil, -1
  local list = {}

  for i = 1, #all do
    local item = all[i]
    if item.visible and item.bounds ~= nil then
      local t = item.bounds.top or 0
      local b = item.bounds.bottom or 0
      local mid = (t + b) * 0.5
      if mid > zone.topY and mid < zone.bottomY and (b - t) > 15 then
        local sig = quickSig(item)
        if sig ~= '' then
          list[#list + 1] = { node = item, top = t, bottom = b, sig = sig }
          if t < topY then
            topY = t
            topNode = item
          end
          if b > botY then
            botY = b
            botNode = item
          end
        end
      end
    end
  end

  table.sort(list, function(a, b) return a.top < b.top end)
  return topNode, botNode, list
end

local function scrollZone(zone, older)
  -- Zkusíme nejprve nativní scrollBackward / scrollForward na posuvném kontejneru
  local scrollables = sf.screen.findAll({ scrollable = true }, 10) or {}
  for i = 1, #scrollables do
    local s = scrollables[i]
    if s.visible and s.bounds ~= nil then
      local h = (s.bounds.bottom or 0) - (s.bounds.top or 0)
      local w = (s.bounds.right or 0) - (s.bounds.left or 0)
      if h > 300 and w > 300 then
        local ok, res = pcall(function()
          return older and s:scrollBackward() or s:scrollForward()
        end)
        if ok and res then
          sf.sleep(220)
          return true
        end
      end
    end
  end

  -- Záložní tah prstem uprostřed zóny zpráv
  local cx = math.floor(zone.screenW * 0.5)
  local yUpper = math.floor(zone.screenH * 0.35)
  local yLower = math.floor(zone.screenH * 0.72)

  if older then
    pcall(function() return sf.touch.swipe(cx, yUpper, cx, yLower, 180) end)
  else
    pcall(function() return sf.touch.swipe(cx, yLower, cx, yUpper, 180) end)
  end
  sf.sleep(240)
  return true
end

-- ---------------------------------------------------------------------------
-- Ovládání šviháním: nativní pohyb uprostřed, odrolování na okrajích (100% v4.0)
-- ---------------------------------------------------------------------------

-- Švihnutí vlevo (k předchozí/starší zprávě)
sf.onCommand('msg_prev', function(event)
  local node = event.node or sf.screen.focused()
  if node == nil or node.bounds == nil then return false end

  local zone = getChatZone()
  if zone == nil then return false end

  local midY = ((node.bounds.top or 0) + (node.bounds.bottom or 0)) * 0.5

  -- Jsme mimo zónu zpráv (např. nahoře na liště nebo dole v poli psaní) -> necháme nativní pohyb
  if midY <= zone.topY or midY >= zone.bottomY then
    return false
  end

  local topNode, _, list = getEdgeMessages(zone)
  if topNode == nil or #list == 0 then
    return false
  end

  -- Pokud NEJSME na nejvyšší viditelné zprávě, vrátíme false -> SandFly udělá bleskový nativní krok nahoru!
  local isAtTop = (node == topNode) or ((node.bounds.top or 0) <= (topNode.bounds.top or 0) + 12)
  if not isAtTop then
    return false
  end

  -- JSME NA HORNÍM OKRAJI ZPRÁV -> zablokujeme útěk na tlačítka hovoru a odrolujeme ke starším zprávám!
  local seen = {}
  for i = 1, #list do
    seen[list[i].sig] = true
  end

  scrollZone(zone, true)

  local _, _, newList = getEdgeMessages(zone)
  if #newList > 0 then
    -- Vybereme nejnižší nově načtenou zprávu, aby navazovala bez opakování
    for i = #newList, 1, -1 do
      if not seen[newList[i].sig] then
        newList[i].node:focus()
        return true
      end
    end
    newList[1].node:focus()
  end

  return true
end)

-- Švihnutí vpravo (k další/novější zprávě)
sf.onCommand('msg_next', function(event)
  local node = event.node or sf.screen.focused()
  if node == nil or node.bounds == nil then return false end

  local zone = getChatZone()
  if zone == nil then return false end

  local midY = ((node.bounds.top or 0) + (node.bounds.bottom or 0)) * 0.5

  -- Mimo zónu zpráv necháme nativní pohyb
  if midY <= zone.topY or midY >= zone.bottomY then
    return false
  end

  local _, botNode, list = getEdgeMessages(zone)
  if botNode == nil or #list == 0 then
    return false
  end

  -- Pokud NEJSME na nejnižší viditelné zprávě, vrátíme false -> SandFly udělá bleskový nativní krok dolů!
  local isAtBottom = (node == botNode) or ((node.bounds.bottom or 0) >= (botNode.bounds.bottom or 0) - 12)
  if not isAtBottom then
    return false
  end

  -- JSME NA SPODNÍM OKRAJI ZPRÁV -> zkusíme odrolovat dolů k novějším zprávám
  local seen = {}
  for i = 1, #list do
    seen[list[i].sig] = true
  end

  scrollZone(zone, false)

  local _, _, newList = getEdgeMessages(zone)
  for i = 1, #newList do
    if not seen[newList[i].sig] then
      newList[i].node:focus()
      return true
    end
  end

  -- Žádné novější zprávy už dole nejsou -> pustíme nativní švihnutí dál do lišty psaní
  return false
end)

-- Rychlý skok dolů do pole pro psaní zprávy
sf.onCommand('jump_bottom', function()
  local zone = getChatZone()
  if zone ~= nil and zone.inputBox ~= nil and zone.inputBox.visible then
    zone.inputBox:focus()
    sf.speak('Pole pro zprávu')
    return true
  end
  return false
end)