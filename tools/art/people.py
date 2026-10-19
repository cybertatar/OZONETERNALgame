"""Враги-люди 32×32, смотрят вправо, кадры как у носков:
idle0, idle1, hop0 (шаг), hop1 (шаг), windup, attack, hurt.
Улица — бомжи, Вьетнам — вьетконговцы. Строка 0 — ближний бой, 1 — дальний."""

from px import Canvas

OUT = "#1b1420"
FRAMES = ["idle0", "idle1", "hop0", "hop1", "windup", "attack", "hurt"]


def person(name, look):
    """look: словарь цветов и предметов (см. BUM_*, VC_*)."""
    c = Canvas(32, 32)
    dy = 1 if name in ("idle1", "hop1") else 0
    lean = {"windup": -1, "attack": 2}.get(name, 0)
    step = {"hop0": 2, "hop1": -2}.get(name, 0)
    # ноги
    for (x0, s, col) in ((13, -step, look["pants_d"]), (16, step, look["pants"])):
        c.rect(x0 + s, 22, x0 + 3 + s, 28, col)
        c.rect(x0 + s, 29, x0 + 4 + s, 30, look["shoes"])
    bx = 12 + lean
    if look.get("basket"):  # плетёная корзина за спиной (вьетконговец-метатель)
        c.rect(bx - 5, 11 + dy, bx, 21 + dy, "#a8884a")
        for y in range(12 + dy, 21 + dy, 2):
            c.rect(bx - 5, y, bx, y, "#8a6a32")
        c.rect(bx - 5, 11 + dy, bx, 11 + dy, "#c8a860")
        c.rect(bx - 4, 9 + dy, bx - 3, 10 + dy, "#6a3a1c")  # таракан лезет из корзины
        c.put(bx - 2, 9 + dy, "#2a1608")
    # туловище
    c.rect(bx, 13 + dy, bx + 8, 23, look["coat"])
    c.rect(bx, 13 + dy, bx + 1, 23, look["coat_d"])
    if look.get("long_coat"):
        c.rect(bx - 1, 20, bx + 9, 25, look["coat"])  # полы пальто
        c.rect(bx - 1, 25, bx + 9, 25, look["coat_d"])
    if look.get("scarf"):
        c.rect(bx + 2, 13 + dy, bx + 7, 14 + dy, look["scarf"])
    if look.get("belt"):
        c.rect(bx, 20, bx + 8, 20, look["belt"])
    # голова
    hx, hy = 11 + lean, 3 + dy + (1 if name == "hurt" else 0)
    c.rect(hx + 1, hy + 2, hx + 9, hy + 10, look["skin"])
    c.rect(hx + 8, hy + 5, hx + 9, hy + 9, look["skin_d"])
    c.rect(hx + 10, hy + 6, hx + 10, hy + 7, look["skin"])  # нос
    if name == "hurt":
        c.rect(hx + 6, hy + 6, hx + 8, hy + 6, OUT)
    else:
        c.rect(hx + 7, hy + 5, hx + 7, hy + 6, OUT)
        c.rect(hx + 6, hy + 4, hx + 8, hy + 4, look.get("brow", OUT))
    if look.get("stubble"):
        c.rect(hx + 4, hy + 8, hx + 9, hy + 10, look["stubble"])
    c.rect(hx + 7, hy + 9, hx + 9, hy + 9, "#6b2a2a" if name in ("windup", "attack") else look["skin_d"])
    # головной убор
    hat = look["hat"]
    if hat == "beanie":
        c.rect(hx, hy, hx + 9, hy + 3, look["hat_col"])
        c.rect(hx, hy + 3, hx + 9, hy + 3, look["hat_d"])
        c.rect(hx + 1, hy - 1, hx + 8, hy - 1, look["hat_col"])
        c.rect(hx, hy + 4, hx + 2, hy + 7, look["hair"])  # патлы из-под шапки
    elif hat == "hood":  # капюшон: накрывает макушку и затылок, лицо открыто
        c.rect(hx, hy - 2, hx + 8, hy + 2, look["hat_col"])
        c.rect(hx + 1, hy - 3, hx + 7, hy - 3, look["hat_col"])
        c.rect(hx - 1, hy, hx + 3, hy + 12, look["hat_col"])
        c.rect(hx - 1, hy + 3, hx + 1, hy + 12, look["hat_d"])
        c.rect(hx + 9, hy, hx + 9, hy + 3, look["hat_d"])  # край у лица
    elif hat == "boonie":  # мягкая панама с полями
        c.rect(hx + 1, hy - 1, hx + 8, hy + 2, look["hat_col"])
        c.rect(hx - 1, hy + 2, hx + 11, hy + 3, look["hat_d"])
        c.rect(hx + 1, hy + 4, hx + 2, hy + 6, look["hair"])
    elif hat == "nonla":
        for i in range(6):  # конусная шляпа
            c.rect(hx + 5 - i - 1, hy - 3 + i, hx + 5 + i + 1, hy - 3 + i, look["hat_col"] if i % 2 else look["hat_d"])
        c.rect(hx - 2, hy + 2, hx + 12, hy + 2, look["hat_d"])
        c.rect(hx + 1, hy + 3, hx + 2, hy + 6, look["hair"])
    # руки и предмет
    item = look["item"]
    if name == "windup":
        c.rect(bx - 3, 9, bx - 1, 15, look["coat"])  # рука занесена назад
        c.rect(bx - 4, 7, bx - 2, 9, look["skin"])
        _item(c, item, bx - 6 if item not in ("poop", "roach") else bx - 5, 2 if item not in ("poop", "roach") else 4, up=True)
    elif name == "attack":
        c.rect(bx + 8, 15, bx + 13, 17, look["coat"])  # рука вперёд
        c.rect(bx + 14, 15, bx + 15, 17, look["skin"])
        if look.get("thrower"):
            pass  # бросил — рука пустая
        else:
            _item(c, item, bx + 15, 12, up=False)
    else:
        sw = {"hop0": 1, "hop1": -1}.get(name, 0)
        c.rect(bx + 3 + sw, 15 + dy, bx + 5 + sw, 21 + dy, look["coat_d"])
        c.rect(bx + 3 + sw, 21 + dy, bx + 5 + sw, 22 + dy, look["skin"])
        _item(c, item, bx + 4 + sw, 19 + dy, up=False, hang=True)
    c.outline(OUT)
    if look.get("flies"):
        f = FRAMES.index(name) % 2
        for (x, y) in ((hx + 12 + f, hy + 1 - f), (hx + 14 - f, hy + 4 + f), (hx - 4 + f, hy + 2)):
            c.put(x, y, "#1b1420")
            c.put(x + 1, y - 1, (220, 230, 240, 200))
    return c


def _item(c, item, x, y, up, hang=False):
    if item == "poop":
        yy = y + (4 if hang else 0)
        c.rect(x - 1, yy + 2, x + 3, yy + 3, "#6b4423")
        c.rect(x, yy + 1, x + 2, yy + 1, "#7a5030")
        c.put(x + 1, yy, "#8a5a36")
        return
    if item == "roach":
        yy = y + (5 if hang else 0)
        c.rect(x - 1, yy, x + 3, yy + 1, "#6a3a1c")
        c.put(x + 4, yy, "#2a1608")
        c.put(x - 1, yy - 1, "#2a1608")
        return
    if item == "bottle":
        if hang:
            c.rect(x, y + 3, x + 2, y + 8, "#3f7a4a")
            c.rect(x + 1, y + 1, x + 1, y + 2, "#3f7a4a")
            c.put(x, y + 4, "#7ad08a")
        else:
            c.rect(x, y, x + 2, y + 5, "#3f7a4a")
            c.rect(x + 1, y + 6, x + 1, y + 7, "#3f7a4a")
            c.put(x, y + 1, "#7ad08a")
    elif item == "stick":
        if hang:
            c.line(x + 1, y - 4, x + 1, y + 8, "#b8a050")
        elif up:
            c.line(x + 2, y + 10, x + 7, y - 2, "#b8a050")
        else:
            c.line(x, y + 4, x + 10, y + 2, "#b8a050")
            c.put(x + 10, y + 2, "#e8d890")
    elif item == "blowpipe":
        if hang:
            c.line(x + 1, y - 2, x + 1, y + 7, "#8a7a3a")
        elif up:
            c.line(x + 3, y + 8, x + 5, y, "#8a7a3a")
        else:
            c.line(x - 4, y + 3, x + 6, y + 3, "#8a7a3a")


BUM_MELEE = {
    "skin": "#d8a888", "skin_d": "#b8866a", "stubble": "#8a6a5a", "hair": "#6a5a4a",
    "coat": "#6a5038", "coat_d": "#4e3a28", "long_coat": True,
    "pants": "#3a3a44", "pants_d": "#2c2c34", "shoes": "#2a2420",
    "hat": "beanie", "hat_col": "#8a3a32", "hat_d": "#6a2a24", "item": "bottle",
}
BUM_RANGED = dict(BUM_MELEE, coat="#5a6a4a", coat_d="#44523a", long_coat=False,
                  hat="hood", hat_col="#7a7a84", hat_d="#5a5a64", thrower=True, item="poop", flies=True)

VC_MELEE = {
    "skin": "#d8b088", "skin_d": "#b8906a", "hair": "#1e1a18",
    "coat": "#24242a", "coat_d": "#18181e", "scarf": "#c23b33", "belt": "#6a5a3a",
    "pants": "#24242a", "pants_d": "#18181e", "shoes": "#5a4a3a",
    "hat": "nonla", "hat_col": "#e8d48a", "hat_d": "#c8b46a", "item": "stick",
}
VC_RANGED = dict(VC_MELEE, coat="#4a5a3a", coat_d="#3a4a2c", pants="#4a5a3a", pants_d="#3a4a2c",
                 scarf=None, hat="boonie", hat_col="#5a6a42", hat_d="#46552f",
                 item="roach", thrower=True, basket=True)


def sheet_rows(melee, ranged):
    return [[person(n, melee) for n in FRAMES], [person(n, ranged) for n in FRAMES]]


def poop_shot(frame):
    """Летящее говно 8×8: коричневая закорючка, над ней муха."""
    c = Canvas(10, 10)
    c.rect(2, 7, 7, 8, "#6b4423")
    c.rect(3, 5, 6, 6, "#7a5030")
    c.rect(4, 3, 5, 4, "#8a5a36")
    c.put(5, 2, "#8a5a36")
    c.put(3, 7, "#9a6a42")
    c.put(4, 5, "#9a6a42")
    c.outline(OUT)
    c.put(8 - frame * 6, 1, "#1b1420")  # муха
    c.put(9 - frame * 6, 0, (220, 230, 240, 200))
    return c


def roach(frame):
    """Таракан 14×12, ползёт вправо: рыжая спинка с линией крыльев, шесть лапок
    в стороны (шевелятся между кадрами) и длинные усы."""
    c = Canvas(14, 12)
    for (y, x0, x1) in ((4, 4, 9), (5, 2, 10), (6, 1, 10), (7, 2, 10), (8, 4, 9)):
        c.rect(x0, y, x1, y, "#6a3a1c")  # овальное тельце
    c.rect(2, 6, 9, 6, "#3a2010")  # шов между крыльями
    c.rect(4, 5, 7, 5, "#9a5a32")  # блик
    c.rect(11, 5, 12, 7, "#3a2010")  # голова
    for i, x in enumerate((4, 7, 10)):
        off = 1 if (i + frame) % 2 else -1
        c.line(x, 3, x - 1 + off, 1, "#2a1608")  # лапки сверху
        c.line(x, 9, x - 1 - off, 11, "#2a1608")  # лапки снизу
    c.line(12, 5, 13, 1, "#2a1608")  # усы
    c.line(12, 7, 13, 11, "#2a1608")
    return c
