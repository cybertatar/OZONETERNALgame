"""Озон, 32×32, ноги на нижней строке. Лист: строки — вниз, вверх, вбок (вправо),
столбцы — FRAMES ниже. Влево — тот же «вбок», отражённый в игре."""

from px import Canvas

OUT = "#1b1420"
SKIN = "#e8b796"
SKIN_D = "#c98e6f"
STUBBLE = "#b98a72"
HAIR = "#3a2a22"
HAIR_L = "#563f33"
SHIRT = "#56657f"
SHIRT_D = "#3f4b60"
SHIRT_L = "#6c7d9a"
PANTS = "#2e3550"
PANTS_D = "#232842"
SHOE = "#2b2626"
SHOE_L = "#4a4141"
EYE = "#1b1420"
PUKE = "#b5c23a"
PUKE_D = "#7f8a22"

FRAMES = [
    "idle0", "idle1", "walk0", "walk1", "walk2", "walk3",
    "punchA", "punchB", "heavy0", "heavy1", "vomit", "hurt", "drink",
]
CAN = "#c79a2c"
CAN_D = "#9c7820"
CAN_LBL = "#7a2420"


def legs_front(c, lift_l, lift_r, back=False):
    # левая нога x11..14, правая x17..20; подъём укорачивает ногу снизу
    for (x0, x1, lift) in ((11, 14, lift_l), (17, 20, lift_r)):
        bottom = 30 - lift
        c.rect(x0, 22, x1, bottom - 2, PANTS)
        c.rect(x1, 22, x1, bottom - 2, PANTS_D)
        c.rect(x0, bottom - 1, x1, bottom, SHOE)
        if not back:
            c.rect(x0, bottom - 1, x0 + 1, bottom - 1, SHOE_L)
    c.rect(11, 22, 20, 23, PANTS)
    c.rect(11, 23, 20, 23, PANTS_D)


def torso_front(c, dy, back=False):
    c.rect(10, 13 + dy, 21, 21 + dy, SHIRT)
    c.rect(20, 14 + dy, 21, 21 + dy, SHIRT_D)
    c.rect(10, 21 + dy, 21, 21 + dy, SHIRT_D)
    c.rect(11, 14 + dy, 11, 18 + dy, SHIRT_L)
    if not back:
        c.rect(14, 13 + dy, 17, 13 + dy, SKIN_D)  # ворот
        c.rect(15, 14 + dy, 16, 14 + dy, SKIN_D)


def arm_front(c, side, dy, swing=0):
    """side: -1 левая (x8..9), 1 правая (x22..23). swing сдвигает кисть."""
    x0 = 8 if side < 0 else 22
    c.rect(x0, 13 + dy, x0 + 1, 16 + dy, SHIRT if side < 0 else SHIRT_D)
    c.rect(x0, 17 + dy, x0 + 1, 19 + dy + swing, SKIN)
    c.rect(x0, 20 + dy + swing, x0 + 1, 20 + dy + swing, SKIN_D)


def head_front(c, dy, eyes="open"):
    y = 2 + dy
    c.rect(11, y + 3, 20, y + 10, SKIN)  # лицо
    c.rect(11, y + 1, 20, y + 4, HAIR)  # волосы
    c.rect(12, y, 19, y, HAIR)
    c.rect(11, y + 5, 11, y + 6, HAIR)
    c.rect(20, y + 5, 20, y + 6, HAIR)
    c.rect(13, y + 1, 16, y + 1, HAIR_L)
    c.rect(10, y + 6, 10, y + 7, SKIN_D)  # уши
    c.rect(21, y + 6, 21, y + 7, SKIN_D)
    c.rect(20, y + 5, 20, y + 10, SKIN_D)  # тень справа
    c.rect(20, y + 5, 20, y + 6, HAIR)
    c.rect(13, y + 5, 14, y + 5, HAIR)  # брови
    c.rect(17, y + 5, 18, y + 5, HAIR)
    if eyes == "open":
        c.rect(13, y + 6, 13, y + 7, EYE)
        c.rect(18, y + 6, 18, y + 7, EYE)
    elif eyes == "shut":
        c.rect(12, y + 7, 14, y + 7, EYE)
        c.rect(17, y + 7, 19, y + 7, EYE)
    c.rect(12, y + 9, 19, y + 10, STUBBLE)  # щетина
    c.rect(11, y + 8, 11, y + 9, STUBBLE)
    c.rect(20, y + 8, 20, y + 9, STUBBLE)
    c.rect(15, y + 8, 16, y + 8, SKIN_D)  # нос
    c.rect(14, y + 9, 17, y + 9, "#8d5a4a")  # рот


def head_back(c, dy):
    y = 2 + dy
    c.rect(11, y + 1, 20, y + 10, HAIR)
    c.rect(12, y, 19, y, HAIR)
    c.rect(13, y + 1, 17, y + 2, HAIR_L)
    c.rect(10, y + 6, 10, y + 7, SKIN_D)
    c.rect(21, y + 6, 21, y + 7, SKIN_D)
    c.rect(13, y + 9, 18, y + 10, SKIN_D)  # шея из-под стрижки


def draw_down(name):
    c = Canvas(32, 32)
    dy, ll, lr, sw_l, sw_r, eyes = 0, 0, 0, 0, 0, "open"
    if name == "idle1":
        dy = 1
    if name == "walk0":
        ll, sw_l, sw_r = 1, 1, -1
    if name == "walk2":
        lr, sw_l, sw_r = 1, -1, 1
    if name in ("walk1", "walk3"):
        dy = 1
    if name == "hurt":
        eyes = "shut"
    legs_front(c, ll, lr)
    torso_front(c, dy)
    if name == "punchA":
        arm_front(c, -1, dy)
        c.rect(19, 13 + dy, 21, 16 + dy, SHIRT_D)  # рука выброшена вперёд, к камере
        c.rect(18, 17, 21, 23, SKIN)
        c.rect(17, 23, 21, 26, SKIN)
        c.rect(17, 26, 21, 26, SKIN_D)
    elif name == "punchB":
        arm_front(c, 1, dy)
        c.rect(10, 13 + dy, 12, 16 + dy, SHIRT)
        c.rect(10, 17, 13, 23, SKIN)
        c.rect(10, 23, 14, 26, SKIN)
        c.rect(10, 26, 14, 26, SKIN_D)
    elif name == "drink":
        arm_front(c, -1, dy)
        c.rect(22, 13, 23, 16, SHIRT_D)  # правая рука согнута к лицу
        c.rect(19, 12, 22, 14, SKIN)
        c.rect(17, 10, 19, 12, SKIN_D)
    elif name == "heavy0":
        # обе руки над головой, кулаки сцеплены
        c.rect(8, 5, 9, 14, SHIRT)
        c.rect(22, 5, 23, 14, SHIRT_D)
        c.rect(9, 1, 22, 4, SKIN)
        c.rect(9, 4, 22, 4, SKIN_D)
    elif name == "heavy1":
        c.rect(8, 13, 9, 16, SHIRT)
        c.rect(22, 13, 23, 16, SHIRT_D)
        for k in range(6):
            c.rect(8 + k, 17 + k, 9 + k, 17 + k, SKIN)
            c.rect(22 - k, 17 + k, 23 - k, 17 + k, SKIN_D)
        c.rect(12, 22, 19, 26, SKIN)
        c.rect(12, 26, 19, 26, SKIN_D)
        c.rect(15, 23, 16, 25, SKIN_D)
    else:
        arm_front(c, -1, dy, sw_l)
        arm_front(c, 1, dy, sw_r)
    hd = dy + (1 if name in ("vomit", "heavy1") else 0)
    head_front(c, hd, "shut" if name in ("vomit", "drink") else eyes)
    if name == "drink":
        c.rect(14, 6, 17, 12, CAN)  # банка у рта, донышком вверх
        c.rect(14, 8, 17, 9, CAN_LBL)
        c.rect(17, 6, 17, 12, CAN_D)
        c.rect(14, 5, 17, 5, "#b9b2a3")
    if name == "vomit":
        c.rect(14, 12 + hd, 17, 13 + hd, PUKE)
        c.rect(13, 14 + hd, 18, 16 + hd, PUKE)
        c.rect(14, 16 + hd, 17, 16 + hd, PUKE_D)
    c.outline(OUT)
    return c


def draw_up(name):
    c = Canvas(32, 32)
    dy, ll, lr, sw_l, sw_r = 0, 0, 0, 0, 0
    if name == "idle1":
        dy = 1
    if name == "walk0":
        ll, sw_l, sw_r = 1, -1, 1
    if name == "walk2":
        lr, sw_l, sw_r = 1, 1, -1
    if name in ("walk1", "walk3"):
        dy = 1
    legs_front(c, ll, lr, back=True)
    if name == "punchA":
        c.rect(19, 4, 22, 13, SKIN)  # рука уходит вперёд-вверх, от камеры
        c.rect(19, 3, 22, 4, SKIN_D)
    if name == "punchB":
        c.rect(9, 4, 12, 13, SKIN)
        c.rect(9, 3, 12, 4, SKIN_D)
    if name == "drink":
        c.rect(19, 6, 22, 13, SKIN)  # рука поднята к лицу
        c.rect(20, 3, 23, 7, CAN)
        c.rect(20, 3, 23, 3, "#b9b2a3")
    if name in ("heavy0", "heavy1"):
        top = 0 if name == "heavy0" else 2
        c.rect(10, top, 21, top + 3, SKIN)
        c.rect(10, top, 21, top, SKIN_D)
    torso_front(c, dy, back=True)
    if name == "drink":
        arm_front(c, -1, dy)
        c.rect(22, 13 + dy, 23, 16 + dy, SHIRT_D)
    elif name not in ("punchA", "punchB", "heavy0", "heavy1"):
        arm_front(c, -1, dy, sw_l)
        arm_front(c, 1, dy, sw_r)
    else:
        if name != "punchB":
            c.rect(8, 13 + dy, 9, 16 + dy, SHIRT)
        if name != "punchA":
            c.rect(22, 13 + dy, 23, 16 + dy, SHIRT_D)
        if name == "punchA":
            arm_front(c, -1, dy)
        if name == "punchB":
            arm_front(c, 1, dy)
    head_back(c, dy + (1 if name == "vomit" else 0))
    if name in ("heavy0",):
        c.rect(10, 0, 21, 3, SKIN)
    c.outline(OUT)
    return c


def draw_side(name):
    """Смотрит вправо."""
    c = Canvas(32, 32)
    dy = 1 if name in ("idle1", "walk1", "walk3") else 0
    # ноги: передняя (ближняя) и задняя
    stride = {"walk0": 3, "walk2": -3}.get(name, 0)
    back_c, front_c = PANTS_D, PANTS
    for (xoff, col, shoe) in ((-stride, back_c, SHOE), (stride, front_c, SHOE)):
        x0 = 14 + xoff
        lift = 1 if (xoff < 0 and stride) else 0
        c.rect(x0, 22, x0 + 4, 28 - lift, col)
        c.rect(x0, 29 - lift, x0 + 5, 30 - lift, shoe)
    c.rect(13, 21, 19, 23, PANTS)
    lean = 1 if name in ("punchA", "punchB", "heavy1", "vomit") else 0
    lean -= 1 if name == "heavy0" else 0
    # торс
    c.rect(13 + lean, 13 + dy, 19 + lean, 21 + dy, SHIRT)
    c.rect(13 + lean, 14 + dy, 14 + lean, 21 + dy, SHIRT_D)
    c.rect(13 + lean, 21 + dy, 19 + lean, 21 + dy, SHIRT_D)
    if name == "heavy0":
        c.rect(6, 2, 11, 8, SKIN)
        c.rect(6, 2, 7, 4, SKIN_D)
        c.rect(10, 9, 13, 14, SKIN)
    # голова
    y = 2 + dy + (1 if name == "vomit" else 0)
    hx = 12 + lean
    c.rect(hx, y + 1, hx + 9, y + 10, SKIN)
    c.rect(hx + 1, y, hx + 8, y, HAIR)
    c.rect(hx, y + 1, hx + 9, y + 3, HAIR)
    c.rect(hx, y + 4, hx + 3, y + 8, HAIR)  # затылок
    c.rect(hx + 3, y + 1, hx + 6, y + 1, HAIR_L)
    c.rect(hx + 4, y + 5, hx + 5, y + 6, SKIN_D)  # ухо
    c.rect(hx + 10, y + 6, hx + 10, y + 7, SKIN)  # нос
    c.rect(hx + 7, y + 4, hx + 8, y + 4, HAIR)  # бровь
    if name in ("hurt", "vomit", "drink"):
        c.rect(hx + 7, y + 6, hx + 8, y + 6, EYE)
    else:
        c.rect(hx + 8, y + 5, hx + 8, y + 6, EYE)
    c.rect(hx + 4, y + 8, hx + 9, y + 10, STUBBLE)
    c.rect(hx + 8, y + 9, hx + 9, y + 9, "#8d5a4a")
    # рука
    if name == "punchA" or name == "punchB":
        c.rect(17 + lean, 14, 20 + lean, 16, SHIRT_L if name == "punchA" else SHIRT_D)
        c.rect(21 + lean, 14, 26, 16, SKIN)
        c.rect(26, 13, 29, 17, SKIN)
        c.rect(29, 13, 29, 17, SKIN_D)
    elif name == "heavy0":
        c.rect(13 + lean, 13, 15 + lean, 16, SHIRT_L)  # кулаки занесены назад-вверх
    elif name == "drink":
        c.rect(15, 13 + dy, 17, 16 + dy, SHIRT_L)
        c.rect(17, 12, 20, 15, SKIN)  # предплечье вверх к лицу
        c.rect(hx + 9, y + 5, hx + 12, y + 11, CAN)  # банка у рта
        c.rect(hx + 9, y + 7, hx + 12, y + 8, CAN_LBL)
        c.rect(hx + 12, y + 4, hx + 12, y + 5, "#b9b2a3")
    elif name == "heavy1":
        c.rect(17 + lean, 14, 20 + lean, 16, SHIRT_L)
        c.rect(21, 15, 25, 21, SKIN)
        c.rect(23, 21, 29, 26, SKIN)
        c.rect(23, 26, 29, 26, SKIN_D)
    else:
        sw = {"walk0": -2, "walk2": 2}.get(name, 0)
        c.rect(15 + lean, 13 + dy, 17 + lean, 16 + dy, SHIRT_L)
        c.rect(15 + lean + sw, 17 + dy, 17 + lean + sw, 19 + dy, SKIN)
        c.rect(15 + lean + sw, 20 + dy, 17 + lean + sw, 20 + dy, SKIN_D)
    if name == "vomit":
        c.rect(hx + 10, y + 9, hx + 13, y + 11, PUKE)
        c.rect(hx + 12, y + 12, hx + 15, y + 15, PUKE)
        c.rect(hx + 13, y + 15, hx + 15, y + 15, PUKE_D)
    c.outline(OUT)
    return c


def frames():
    return [
        [draw_down(n) for n in FRAMES],
        [draw_up(n) for n in FRAMES],
        [draw_side(n) for n in FRAMES],
    ]
