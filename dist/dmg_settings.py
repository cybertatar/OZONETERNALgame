# Настройки dmgbuild: окно 600×400, слева игра, справа ярлык «Программы»,
# между ними стрелка на фоне (dist/dmg-background*.png, рисует tools/art/build.py).
# Запуск (на маке): dmgbuild -s dist/dmg_settings.py -D app="путь/OZON ETERNAL.app" "OZON ETERNAL" out.dmg

import os

app = defines["app"]  # noqa: F821
app_name = os.path.basename(app)

format = "UDZO"
size = None
files = [app]
symlinks = {"Applications": "/Applications"}
icon = os.path.join(app, "Contents", "Resources", "icon.icns")
hide_extensions = [app_name]
icon_locations = {app_name: (150, 190), "Applications": (450, 190)}

background = defines.get("background", "dist/dmg-background.tiff")  # noqa: F821
window_rect = ((200, 120), (600, 400))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 128
text_size = 13
arrange_by = None
