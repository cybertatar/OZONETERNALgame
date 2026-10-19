"""Собирает все спрайты в assets/sprites. Запуск: python3 tools/art/build.py"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import enemies  # noqa: E402
import ozon  # noqa: E402
import px  # noqa: E402
import themes as th  # noqa: E402
import people  # noqa: E402
import world as w  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")


def save(name, img):
    img = img.img if hasattr(img, "img") else img
    img.save(os.path.join(OUT, name + ".png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    save("ozon", px.sheet(ozon.frames()))
    save("socks", px.sheet(enemies.sock_frames()))
    save("garlic", px.sheet([enemies.garlic(0), enemies.garlic(1)]))
    save("mazokha", px.sheet(enemies.boss_frames()))
    for name, fn in [
        ("floor_wood", w.floor_wood), ("floor_concrete", w.floor_concrete),
        ("wall_wallpaper", w.wall_wallpaper), ("wall_brick", w.wall_brick),
        ("desk", w.desk), ("chair", w.chair), ("poster", w.poster), ("fan", w.fan),
        ("window", w.window), ("bed", w.bed), ("beer_can", w.beer_can), ("vodka", w.vodka),
        ("crate", w.crate), ("basket", w.basket), ("icon_beer", w.icon_beer),
        ("icon_vodka", w.icon_vodka), ("icon_dash", w.icon_dash), ("icon_heart", w.icon_heart), ("icon_life", w.icon_life),
        ("book_page", w.book_page),
    ]:
        save(name, fn())
    save("tv", px.sheet([w.tv(False), w.tv(True)]))
    save("door", px.sheet([w.door(False), w.door(True)]))
    save("trophy_mazokha", w.trophy_frame("mazokha"))
    save("note_paper", w.note_paper())
    save("spikes", px.sheet([w.spikes(i) for i in range(3)]))
    save("poison", px.sheet([w.poison(i) for i in range(2)]))
    save("puddle", px.sheet([w.puddle(i) for i in range(4)]))
    save("shadow_s", w.shadow(14, 5))
    save("shadow_m", w.shadow(20, 7))
    save("shadow_l", w.shadow(40, 12))
    for name in ("heal", "life", "rage"):
        fn = getattr(w, "alert_" + name)
        save("alert_" + name, px.sheet([fn(0), fn(1)]))
    # уровни 2 (улица) и 3 (Вьетнам)
    for name, fn in [
        ("floor_asphalt", th.floor_asphalt), ("wall_panel", th.wall_panel),
        ("trash_bin", th.trash_bin), ("bench", th.bench), ("decor_zebra", th.decor_zebra),
        ("floor_terracotta", th.floor_terracotta), ("wall_bamboo", th.wall_bamboo),
        ("jar", th.jar), ("rice_sack", th.rice_sack),
        ("floor_checker", th.floor_checker), ("wall_kitchen", th.wall_kitchen), ("washer", th.washer),
    ]:
        save(name, fn())
    save("glass", px.sheet([th.glass(i) for i in range(3)]))
    save("fuel", px.sheet([th.fuel(i) for i in range(2)]))
    save("punji", px.sheet([th.punji(i) for i in range(3)]))
    save("paddy", px.sheet([th.paddy(i) for i in range(2)]))
    for k in ("manhole", "butts", "crack", "leaf"):
        save("decor_" + k, th.decor_street(k))
    for k in ("lotus", "stones", "sprout", "petals"):
        save("decor_" + k, th.decor_viet(k))
    for k in ("cans", "crumbs", "sock", "spill"):
        save("decor_" + k, th.decor_kitchen(k))
    # враги-люди: бомжи (улица) и вьетконговцы (Вьетнам)
    save("bums", px.sheet(people.sheet_rows(people.BUM_MELEE, people.BUM_RANGED)))
    save("vc", px.sheet(people.sheet_rows(people.VC_MELEE, people.VC_RANGED)))
    save("poop_shot", px.sheet([people.poop_shot(0), people.poop_shot(1)]))
    save("roach", px.sheet([people.roach(0), people.roach(1)]))
    save("panel_dark", w.panel(True))
    save("panel_light", w.panel(False))
    save("panel_focus", w.panel_focus())

    # иконка приложения 1024 и фон окна установщика (600×400 и 1200×800 для Retina)
    from PIL import Image
    root = os.path.join(os.path.dirname(__file__), "..", "..")
    icon = w.app_icon(ozon.frames()[0][0]).img
    icon.resize((1024, 1024), Image.NEAREST).save(os.path.join(root, "assets", "icon.png"))
    bg = w.dmg_background(os.path.join(root, "assets", "fonts", "Tiny5.ttf"))
    os.makedirs(os.path.join(root, "dist"), exist_ok=True)
    bg.resize((600, 400), Image.NEAREST).save(os.path.join(root, "dist", "dmg-background.png"))
    bg.resize((1200, 800), Image.NEAREST).save(os.path.join(root, "dist", "dmg-background@2x.png"))


if __name__ == "__main__":
    main()
