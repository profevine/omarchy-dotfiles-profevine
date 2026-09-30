-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- Atalho de emergência para forçar encerramento de janela travada (killactive)
o.bind("SUPER + SHIFT + W", "Force kill window", hl.dsp.window.kill())


-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")


-- Logitech G600: os 12 botoes laterais emitem teclas do teclado numerico
-- (KP1..KP0), nao a fileira de numeros de cima. Como o Omarchy amarra os
-- atalhos numericos por keycode (code:10..19 = teclas "1".."0" de cima), nada
-- casava quando o numero vinha do mouse. Aqui espelhamos os mesmos atalhos nos
-- keycodes do numpad, entao SUPER + 5 no mouse faz o mesmo que SUPER + 5 no
-- teclado. Os botoes continuam digitando numeros normalmente.
--
-- Isso vale para qualquer numpad, inclusive o de um teclado fisico.
local numpad_code = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 } -- KP1..KP9, KP0

for workspace = 1, 10 do
  local key = "code:" .. tostring(numpad_code[workspace])

  -- Espelha default/hypr/bindings/tiling.lua (workspaces)
  o.bind("SUPER + " .. key, nil, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, nil, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + ALT + " .. key, nil, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))

  -- Espelha default/hypr/bindings/tiling.lua (janelas agrupadas, 1-5)
  if workspace <= 5 then
    o.bind("SUPER + ALT + " .. key, nil, hl.dsp.group.active({ index = workspace }))
  end

  -- Espelha default/hypr/bindings/utilities.lua (paineis da barra, 1-9)
  if workspace <= 9 then
    o.bind("SUPER + CTRL + " .. key, nil, "omarchy-shell -q shell togglePanelAt right " .. workspace)
  end
end

-- Webcam flutuando sobre as janelas, para tutoriais e lives (SUPER+ALT+[ / ] mudam o tamanho)
o.bind("SUPER + ALT + W", "Webcam overlay", "webcam-overlay")
