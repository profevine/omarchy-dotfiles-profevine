-- Configurações só desta máquina (ch3n, desktop).
-- Atalhos, apps e ajustes que não servem para o notebook ficam aqui.

-- Elite Dangerous: jogo no ultrawide (DP-1, em cima), ferramentas na LG (HDMI-A-1, embaixo).
-- Todas as janelas do jogo no Proton têm a classe steam_app_359320 (launcher e cliente).
o.window("^steam_app_359320$", { monitor = "DP-1" })
-- O Wine abre o launcher flutuando na posição que pede (fora dos monitores); centraliza no DP-1.
o.window({ class = "^steam_app_359320$", float = true }, { center = true })
-- O cliente nasce sem o título final, então é reconhecido por não flutuar (o launcher flutua).
o.window({ class = "^steam_app_359320$", float = false }, {
  fullscreen = true,
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "fullscreen",
})
-- EDMarketConnector (Tk) e o planejador de rotas do Spansh (app web) na LG.
o.window("(?i)^edmarketconnector$", { monitor = "HDMI-A-1" })
o.window("^chrome-spansh\\.co\\.uk.*", { monitor = "HDMI-A-1" })
o.window("^chrome-inara\\.cz.*", { monitor = "HDMI-A-1" })  -- rotas de comércio (elite-comercio)
