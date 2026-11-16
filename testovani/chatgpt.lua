local manifest = {
  id = 'chatgpt',
  name = 'ChatGPT: celá odpověď',
  version = '0.0.1',
  author = 'Jan Balák',
  homepage = 'https://github.com/jaxcze/sandfly-scripts',
  minApiVersion = 2,
  testedApiVersion = 5,
  description = 'Dlouhá odpověď ChatGPT jde celá přečíst, i když je na obrazovce vidět jen její část. V nabídce Akce na textu zprávy je Zobrazit celou zprávu (okno, ve kterém jde text číst po řádcích, slovech i znacích a označit) a Přečíst celou zprávu. Příkaz Zobrazit poslední zprávu otevře poslední zprávu konverzace odkudkoli v aplikaci. Testovací verze.',
  apps = { 'com.openai.chatgpt' },
  permissions = { 'screen', 'speech', 'input', 'dialogs' },
  commands = {
    { id = 'last', title = 'Zobrazit poslední zprávu', menu = true },
  },
}

local MAX_ITEMS = 200
local TITLE = 'Zpráva ChatGPT'

local function present(text)
  if text ~= nil and text ~= '' then
    return text
  end
end

local function trim(text)
  return ((text or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function short_class(item)
  return (item.className or ''):match('[^.]*$')
end

-- Zpráva je položka přímo v posouvatelném seznamu konverzace. Hledá se od zaměřené položky nahoru.
local function message_of(item)
  local current = item
  for _ = 1, 40 do
    local parent = current:parent()
    if parent == nil then
      return nil
    end
    if parent.scrollable then
      return current
    end
    current = parent
  end
end

-- Text zprávy: odstavce a body seznamů v pořadí. Tlačítka (zdroje, kopírovat, líbí se) se vynechají.
local function text_of(message)
  local parts = {}
  local bullets = 0
  local in_list = false
  local items = message:findAll({}, MAX_ITEMS)
  for _, item in ipairs(items) do
    local class = short_class(item)
    if class == 'ListView' then
      bullets = item.childCount or 0
      in_list = false
    elseif class == 'TextView' then
      local text = trim(present(item.text) or item.contentDescription)
      if text ~= '' then
        if bullets > 0 then
          -- Body jednoho seznamu jsou pod sebou bez prázdného řádku.
          if in_list then
            parts[#parts] = parts[#parts] .. '\n• ' .. text
          else
            parts[#parts + 1] = '• ' .. text
          end
          in_list = true
          bullets = bullets - 1
        else
          parts[#parts + 1] = text
          in_list = false
        end
      end
    end
  end
  if #items >= MAX_ITEMS then
    sf.log.warn('Zpráva má víc než ' .. MAX_ITEMS .. ' položek, konec může chybět.')
  end
  return table.concat(parts, '\n\n')
end

local function show(item)
  local message = message_of(item)
  local text = message and text_of(message) or ''
  if text == '' then
    sf.speak('Tady není text zprávy', { interrupt = true })
    return
  end
  sf.ui.text(TITLE, text)
end

local function read(item)
  local message = message_of(item)
  local text = message and text_of(message) or ''
  if text == '' then
    sf.speak('Tady není text zprávy', { interrupt = true })
    return
  end
  sf.speak(text, { interrupt = true })
end

-- Akce jen na textu, ne na tlačítkách a poli pro psaní.
sf.onActions(function(item)
  local class = short_class(item)
  if item.editable or item.clickable or class == 'Button' or class == 'EditText' then
    return
  end
  return {
    { title = 'Zobrazit celou zprávu', first = true, run = show },
    { title = 'Přečíst celou zprávu', run = read },
  }
end)

-- Poslední zpráva v seznamu konverzace, která má text.
sf.onCommand('last', function()
  local list = sf.screen.find({ role = 'list', scrollable = true })
  if list == nil then
    sf.speak('Konverzace tu není', { interrupt = true })
    return
  end
  local rows = list:children()
  for i = #rows, 1, -1 do
    local text = text_of(rows[i])
    if text ~= '' then
      sf.ui.text(TITLE, text)
      return
    end
  end
  sf.speak('Konverzace je prázdná', { interrupt = true })
end)
