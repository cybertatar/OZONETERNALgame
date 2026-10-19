"""Грязные носки (24×24), чеснок (8×8) и Мазоха (64×64). Все смотрят вправо."""

from px import Canvas, Scaled, hexc

OUT = "#1b1420"
SOCK = "#ddd5c0"
SOCK_D = "#b3a98f"
SOCK_DD = "#8f846b"
STAIN = "#8a6b3a"
STAIN_D = "#6b4f28"
RED = "#b8433a"
GREEN = "#5d8a3a"
EYE = "#1b1420"
EYE_W = "#f4efe2"

SOCK_FRAMES = ["idle0", "idle1", "hop0", "hop1", "windup", "attack", "hurt"]


def sock(name, stripe):
    c = Canvas(24, 24)
    # смещения: подскок вверх, наклон, сплющивание
    up = {"hop0": 1, "hop1": 2}.get(name, 0)  # сам прыжок даёт код
    squash = 1 if name in ("idle1", "windup") else 0
    lean = {"windup": -1, "attack": 2}.get(name, 0)
    top = 3 + squash - up
    bottom = 20 - up
    x0 = 6
    # голенище
    for y in range(top, bottom - 3):
        sh = lean if y < (top + bottom) // 2 else 0
        c.rect(x0 + sh, y, x0 + 9 + sh, y, SOCK)
        c.rect(x0 + sh, y, x0 + 1 + sh, y, SOCK_D)
    # стопа
    c.rect(x0, bottom - 5, x0 + 13, bottom - 1, SOCK)
    c.rect(x0 + 13, bottom - 4, x0 + 14, bottom - 1, SOCK)
    c.rect(x0, bottom - 1, x0 + 14, bottom - 1, SOCK_D)
    c.rect(x0, bottom - 5, x0 + 1, bottom - 1, SOCK_D)
    c.rect(x0 + 11, bottom - 4, x0 + 14, bottom - 1, STAIN)  # носок пальцев
    c.rect(x0 + 12, bottom - 1, x0 + 14, bottom - 1, STAIN_D)
    c.rect(x0, bottom - 3, x0 + 2, bottom - 1, STAIN)  # пятка
    # резинка с полосками
    c.rect(x0 + lean, top, x0 + 9 + lean, top + 3, SOCK)
    c.rect(x0 + lean, top + 1, x0 + 9 + lean, top + 1, stripe)
    c.rect(x0 + lean, top + 3, x0 + 9 + lean, top + 3, stripe)
    c.rect(x0 + lean, top, x0 + 9 + lean, top, SOCK_DD)
    # пятна
    c.put(x0 + 3, top + 9, STAIN)
    c.put(x0 + 4, top + 9, STAIN)
    c.put(x0 + 8, top + 11, STAIN)
    c.put(x0 + 7, bottom - 4, STAIN)
    # лицо
    ey = top + 5
    ex = x0 + 3 + (lean if lean > 0 else 0)
    if name == "hurt":
        c.rect(ex, ey + 1, ex + 1, ey + 1, EYE)
        c.rect(ex + 4, ey + 1, ex + 5, ey + 1, EYE)
    else:
        c.rect(ex, ey, ex + 1, ey + 1, EYE_W)
        c.rect(ex + 4, ey, ex + 5, ey + 1, EYE_W)
        c.put(ex + 1, ey + 1, EYE)
        c.put(ex + 5, ey + 1, EYE)
        c.line(ex - 1, ey - 1, ex + 1, ey, EYE)  # злые брови
        c.line(ex + 6, ey - 1, ex + 4, ey, EYE)
    if name in ("attack", "windup"):
        c.rect(ex + 2, ey + 3, ex + 4, ey + 4, "#5a2a2a")
    c.outline(OUT)
    return c


def garlic(frame):
    c = Canvas(8, 8)
    c.ellipse(4, 4.5, 3, 3, "#f1ece0")
    c.rect(3, 1, 4, 2, "#f1ece0")
    c.put(4, 0, "#cfc8b5")
    c.put(2 + frame, 4, "#a58bb8")
    c.put(5 - frame, 5, "#a58bb8")
    c.rect(2, 6, 5, 6, "#d6cfbd")
    c.outline(OUT)
    return c


# --- Мазоха -----------------------------------------------------------------
# Короткий ёжик, круглое лицо, широкая улыбка, бородка на подбородке,
# тёмно-синяя футболка с белой надписью.
M_SKIN = "#f0c4a8"
M_SKIN_D = "#d29e82"
M_HAIR = "#3b2f2a"
M_HAIR_SKIN = "#7a6155"  # кожа сквозь ёжик
M_SHIRT = "#252a40"
M_SHIRT_D = "#1a1e30"
M_SHIRT_L = "#323853"
M_PRINT = "#e4e0d6"
M_PANTS = "#2b2b38"
M_PANTS_D = "#1f1f29"
M_SHOE = "#3a3640"
TEETH = "#f7f4ec"
MOUTH = "#6b2a2a"

BOSS_FRAMES = ["idle0", "idle1", "walk0", "walk1", "slam0", "slam1", "charge", "summon", "hurt"]


BOSS_SCALE = 1.5  # втрое выше Озона: 96 px


def mazokha(name):
    c = Scaled(64, 64, BOSS_SCALE)
    dy = 1 if name in ("idle1", "walk1") else 0
    lean = {"charge": 4, "slam1": 2}.get(name, 0)
    step = {"walk0": 2, "walk1": -2, "charge": 3}.get(name, 0)
    for (lx, s) in ((18, -step), (35, step)):
        c.rect(lx + s, 46, lx + 10 + s, 58, M_PANTS)
        c.rect(lx + 9 + s, 46, lx + 10 + s, 58, M_PANTS_D)
        c.rect(lx - 1 + s, 58, lx + 11 + s, 61, M_SHOE)
    # туловище: плечи уже, ниже огромное круглое пузо в обтянутой футболке,
    # которая не дотягивает — снизу торчит живот с пупком
    bx = 13 + lean
    cx = bx + 18.5
    c.rect(bx, 25 + dy, bx + 37, 32, M_SHIRT)  # покатые плечи — уже пуза
    c.rect(bx + 3, 23 + dy, bx + 34, 24 + dy, M_SHIRT)
    c.ellipse(cx, 39 + dy * 0.5, 27, 13.5, M_SHIRT)  # пузо — шире плеч
    c.ellipse(cx + 1, 47.5, 19, 5, M_SKIN)  # голый живот из-под футболки
    # тень по правому боку и под футболкой — по настоящим пикселям холста
    S = c.s
    shirt, shirt_d, skin, skin_d = hexc(M_SHIRT), hexc(M_SHIRT_D), hexc(M_SKIN), hexc(M_SKIN_D)
    for y in range(c.h):
        for x in range(c.w):
            col = Canvas.get(c, x, y)
            if col == skin and y < 46 * S and y > 38 * S:
                Canvas._px(c, x, y, shirt)  # футболка поверх верха живота
                col = shirt
            if col == shirt and x > (cx + 15) * S:
                Canvas._px(c, x, y, shirt_d)
            elif col == skin and x > (cx + 10) * S:
                Canvas._px(c, x, y, skin_d)
    c.rect(int(cx) - 1, 48, int(cx), 48, M_SKIN_D)  # пупок
    c.ellipse(cx - 9, 36, 6, 4, M_SHIRT_L)  # блик на обтянутом пузе
    c.ellipse(cx - 9, 36, 3.5, 2, M_SHIRT)
    c.rect(bx + 6, 25 + dy, bx + 7, 31, M_SHIRT_L)
    c.rect(bx + 14, 23 + dy, bx + 23, 24 + dy, M_SKIN_D)  # ворот
    # надпись растянута на пузе
    py = 33 + dy
    for i, w_ in enumerate((3, 2, 3, 3, 2, 3, 3)):
        x = bx + 7 + i * 3
        c.rect(x, py, x + w_ - 2 if w_ > 2 else x, py + 3, M_PRINT)
    c.rect(bx + 8, py - 3, bx + 27, py - 3, M_PRINT)
    c.rect(bx + 9, py + 6, bx + 26, py + 6, "#9a96a0")
    # голова — круглая
    hx, hy = 32 + lean, 13 + dy + (2 if name == "slam1" else 0)
    c.ellipse(hx, hy, 12, 12, M_SKIN)
    c.ellipse(hx + 4, hy + 1, 8, 9, M_SKIN)
    c.ellipse(hx - 4, hy + 1, 8, 9, M_SKIN)
    for x in range(hx - 12, hx + 13):  # тень справа
        for y in range(hy - 12, hy + 13):
            if c.get(x, y) == hexc(M_SKIN) and x > hx + 8:
                c.put(x, y, M_SKIN_D)
    # ёжик: верх головы
    for x in range(hx - 12, hx + 13):
        for y in range(hy - 13, hy - 5):
            if c.get(x, y)[3]:
                c.put(x, y, M_HAIR if (x + y) % 3 else M_HAIR_SKIN)
    c.rect(hx - 9, hy - 5, hx - 8, hy - 3, M_HAIR)  # виски
    c.rect(hx + 8, hy - 5, hx + 9, hy - 3, M_HAIR)
    c.rect(hx - 13, hy - 1, hx - 12, hy + 2, M_SKIN_D)  # уши
    c.rect(hx + 12, hy - 1, hx + 13, hy + 2, M_SKIN_D)
    # брови и глаза — прищур от смеха
    c.rect(hx - 7, hy - 3, hx - 3, hy - 3, M_HAIR)
    c.rect(hx + 3, hy - 3, hx + 7, hy - 3, M_HAIR)
    if name == "hurt":
        c.line(hx - 7, hy - 1, hx - 4, hy + 1, "#1b1420")
        c.line(hx + 4, hy + 1, hx + 7, hy - 1, "#1b1420")
    else:
        c.rect(hx - 6, hy, hx - 4, hy, "#1b1420")
        c.put(hx - 7, hy + 1, "#1b1420")
        c.rect(hx + 4, hy, hx + 6, hy, "#1b1420")
        c.put(hx + 7, hy + 1, "#1b1420")
    c.rect(hx - 1, hy + 1, hx + 1, hy + 3, M_SKIN_D)  # нос
    # усики и бородка на подбородке
    c.rect(hx - 4, hy + 5, hx + 4, hy + 5, M_HAIR_SKIN)
    if name == "hurt":
        c.rect(hx - 3, hy + 7, hx + 3, hy + 7, MOUTH)
    else:
        big = name in ("slam0", "charge", "summon")
        c.rect(hx - 5, hy + 6, hx + 5, hy + (9 if big else 8), MOUTH)  # улыбка
        c.rect(hx - 5, hy + 6, hx + 5, hy + 6, TEETH)
        c.rect(hx - 4, hy + 7, hx + 4, hy + 7, TEETH)
        c.put(hx - 6, hy + 5, MOUTH)
        c.put(hx + 6, hy + 5, MOUTH)
    c.rect(hx - 3, hy + 10, hx + 3, hy + 13, M_HAIR)
    c.rect(hx - 2, hy + 14, hx + 2, hy + 14, M_HAIR)

    def arm(x, y0, y1, fist_y, dark):
        c.rect(x, y0, x + 6, min(y0 + 6, y1), M_SHIRT_D if dark else M_SHIRT)
        c.rect(x + 1, y0 + 7, x + 5, y1, M_SKIN_D if dark else M_SKIN)
        c.rect(x, fist_y, x + 6, fist_y + 5, M_SKIN_D if dark else M_SKIN)
    if name == "slam0":
        c.rect(12, 6, 18, 26, M_SKIN)
        c.rect(46, 6, 52, 26, M_SKIN_D)
        c.rect(11, 22, 18, 28, M_SHIRT)
        c.rect(46, 22, 53, 28, M_SHIRT_D)
        c.rect(14, 0, 50, 5, M_SKIN)
        c.rect(14, 5, 50, 5, M_SKIN_D)
    elif name == "slam1":
        arm(4 + lean, 25, 40, 41, False)
        arm(53 + lean, 25, 40, 41, True)
        c.rect(0 + lean, 44, 10 + lean, 50, M_SKIN)
        c.rect(53 + lean, 44, 63, 50, M_SKIN_D)
    elif name == "summon":
        c.rect(2, 24, 14, 29, M_SKIN)
        c.rect(50, 24, 62, 29, M_SKIN_D)
        c.rect(8, 23, 14, 30, M_SHIRT)
        c.rect(50, 23, 56, 30, M_SHIRT_D)
        c.rect(0, 20, 4, 27, M_SKIN)
        c.rect(59, 20, 63, 27, M_SKIN_D)
    elif name == "charge":
        arm(52, 25, 34, 35, True)
        c.rect(52, 31, 60, 39, M_SKIN_D)
    else:
        sw = {"walk0": 2, "walk1": -2}.get(name, 0)
        arm(7 + lean, 25 + dy, 37 + dy + sw, 38 + dy + sw, False)
        arm(50 + lean, 25 + dy, 37 + dy - sw, 38 + dy - sw, True)
    c.outline(OUT)
    return c


def sock_frames():
    return [[sock(n, RED) for n in SOCK_FRAMES], [sock(n, GREEN) for n in SOCK_FRAMES]]


def boss_frames():
    return [mazokha(n) for n in BOSS_FRAMES]
