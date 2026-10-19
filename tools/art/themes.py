"""Оформление уровней 2 и 3: улица (вечер, панельки) и Вьетнам (терракота, бамбук, фонари).
Уровень 1 (подвал) — в world.py."""

import random

from px import Canvas

OUT = "#1b1420"


# --- улица ------------------------------------------------------------------
def floor_asphalt():
    c = Canvas(32, 32)
    rnd = random.Random(21)
    c.rect(0, 0, 31, 31, "#3d3f46")
    for _ in range(70):
        c.put(rnd.randrange(32), rnd.randrange(32), rnd.choice(["#45474f", "#35373d", "#4b4d55"]))
    c.line(3, 20, 9, 17, "#2c2d32")  # трещина
    c.line(9, 17, 12, 19, "#2c2d32")
    c.put(24, 6, "#5a5c63")
    c.put(25, 6, "#5a5c63")
    return c


def wall_panel():
    """Фасад панельки 32×40: серые плиты со швами, окно с рамой, внизу цоколь."""
    c = Canvas(32, 40)
    c.rect(0, 0, 31, 39, "#a9a59a")
    c.rect(0, 0, 31, 0, "#8d897f")
    c.rect(0, 15, 31, 15, "#8d897f")  # горизонтальный шов
    c.rect(15, 0, 15, 31, "#8d897f")  # вертикальный шов
    c.rect(31, 0, 31, 31, "#97938a")
    # окна: одно светится, другое тёмное
    for (x0, lit) in ((3, True), (19, False)):
        c.rect(x0, 3, x0 + 9, 12, "#e8e4da")
        c.rect(x0 + 1, 4, x0 + 8, 11, "#f2c86a" if lit else "#2e3a52")
        c.rect(x0 + 1, 4, x0 + 8, 5, "#ffe39a" if lit else "#3d4d6a")
        c.rect(x0 + 4, 4, x0 + 5, 11, "#e8e4da")
        c.rect(x0 + 1, 7, x0 + 8, 7, "#e8e4da")
    for (x0) in (3, 19):  # окна второго ряда — тёмные
        c.rect(x0, 18, x0 + 9, 27, "#e8e4da")
        c.rect(x0 + 1, 19, x0 + 8, 26, "#2e3a52")
        c.rect(x0 + 4, 19, x0 + 5, 26, "#e8e4da")
    c.rect(0, 32, 31, 39, "#6b6a66")  # цоколь
    c.rect(0, 32, 31, 32, "#7e7d78")
    c.rect(0, 39, 31, 39, "#4a4946")
    return c


def trash_bin():
    """Зелёный мусорный бак 24×24, крышка приоткрыта, торчит пакет."""
    c = Canvas(24, 24)
    c.rect(2, 7, 21, 22, "#3f6b45")
    c.rect(2, 7, 21, 8, "#4f8256")
    c.rect(18, 7, 21, 22, "#2f5034")
    c.rect(1, 4, 22, 6, "#2f5034")  # крышка
    c.rect(1, 4, 22, 4, "#4f8256")
    c.rect(5, 1, 10, 4, "#2b2b30")  # пакет
    c.rect(6, 0, 8, 1, "#2b2b30")
    c.rect(5, 12, 9, 14, "#d8d2c0")  # наклейка
    c.rect(3, 22, 5, 23, "#222222")
    c.rect(18, 22, 20, 23, "#222222")
    c.outline(OUT)
    return c


def bench():
    """Лавочка 32×22 со свежей краской и табличкой «ОКРАШЕНО»."""
    c = Canvas(32, 22)
    for y in (6, 9, 12):
        c.rect(1, y, 30, y + 1, "#3f8a4a")  # доски сиденья
        c.rect(1, y, 30, y, "#5fb36a")
    c.rect(1, 2, 30, 3, "#3f8a4a")  # спинка
    c.rect(1, 2, 30, 2, "#5fb36a")
    for x in (3, 27):
        c.rect(x, 2, x + 1, 19, "#2b2b30")  # ножки
    c.rect(9, 15, 22, 20, "#f4efe2")  # табличка
    c.rect(10, 17, 21, 17, "#b8433a")
    c.rect(10, 19, 18, 19, "#b8433a")
    c.rect(15, 13, 16, 15, "#7a5a3a")
    c.outline(OUT)
    return c


def glass(state):
    """Битое стекло на асфальте — ловушка улицы. 0 — спокойно, 1 — блестит, 2 — режет."""
    c = Canvas(16, 16)
    shards = [(3, 4), (9, 3), (6, 9), (11, 10), (4, 12)]
    for i, (x, y) in enumerate(shards):
        h = 1 if state == 0 else (2 if state == 1 else 5)
        col = "#7fb0a8" if state < 2 else "#c8f0e8"
        c.rect(x, y - h + 1, x + 1, y, col)
        if state >= 1:
            c.put(x, y - h + 1, "#ffffff")
        if state == 2:
            c.put(x + 1, y - h + 2, "#9ad8ce")
    return c


def fuel(frame):
    """Лужа бензина с радужными разводами — яд улицы."""
    c = Canvas(16, 16)
    c.ellipse(8, 8.5, 7.2, 6.2, "#25262e")
    c.ellipse(8, 8.5, 5.5, 4.5, "#30323c")
    rainbow = ["#b05ac8", "#4fb0d8", "#7ad86a", "#e8c35a"]
    for i, col in enumerate(rainbow):
        x = 4 + i * 2 + frame
        c.rect(x, 7 + (i % 2), x + 1, 7 + (i % 2), col)
    c.put(10 - frame, 11, "#4fb0d8")
    return c


def decor_street(kind):
    c = Canvas(16, 16)
    if kind == "manhole":
        c.ellipse(8, 8, 6.5, 5, "#2a2b30")
        c.ellipse(8, 8, 5.5, 4, "#4a4b52")
        for x in range(4, 13, 2):
            c.rect(x, 6, x, 10, "#3a3b42")
    elif kind == "butts":
        for (x, y) in ((3, 5), (9, 8), (6, 12), (12, 4)):
            c.rect(x, y, x + 2, y, "#e8e2d4")
            c.put(x, y, "#c8873a")
    elif kind == "crack":
        c.line(1, 3, 6, 8, "#2a2b30")
        c.line(6, 8, 5, 13, "#2a2b30")
        c.line(6, 8, 12, 10, "#2a2b30")
    elif kind == "leaf":
        for (x, y, col) in ((4, 5, "#c8873a"), (10, 9, "#b8433a"), (6, 11, "#d8a83a")):
            c.rect(x, y, x + 2, y + 1, col)
            c.put(x + 3, y + 1, col)
    return c


def decor_zebra():
    """Кусок пешеходной зебры 32×16."""
    c = Canvas(32, 16)
    for x in range(1, 32, 8):
        c.rect(x, 1, x + 4, 14, (220, 216, 205, 200))
        c.rect(x, 14, x + 4, 14, (200, 196, 185, 160))
    return c


# --- Вьетнам ----------------------------------------------------------------
def floor_terracotta():
    """Терракотовая плитка 32×32 со швами и мхом."""
    c = Canvas(32, 32)
    rnd = random.Random(33)
    tones = ["#b0603e", "#a85a3a", "#b86a46", "#a3553a"]
    for ty in range(2):
        for tx in range(2):
            x0, y0 = tx * 16, ty * 16
            c.rect(x0, y0, x0 + 15, y0 + 15, tones[ty * 2 + tx])
            c.rect(x0, y0, x0 + 15, y0, "#c47a52")
            c.rect(x0, y0 + 15, x0 + 15, y0 + 15, "#7e4128")
            c.rect(x0 + 15, y0, x0 + 15, y0 + 15, "#7e4128")
            for _ in range(5):
                c.put(x0 + rnd.randrange(2, 14), y0 + rnd.randrange(2, 14), "#98502f")
    for (x, y) in ((15, 14), (16, 15), (14, 15), (31, 30), (0, 31), (15, 31)):
        c.put(x, y, "#5d7a3a")  # мох в швах
    return c


def wall_bamboo():
    """Бамбуковый забор 32×40, сверху верёвка с красным фонарём."""
    c = Canvas(32, 40)
    c.rect(0, 0, 31, 39, "#2d3a24")
    for i, x in enumerate(range(0, 32, 4)):
        col = ["#9aa64a", "#8a9640", "#a6b254"][i % 3]
        c.rect(x, 2, x + 2, 37, col)
        c.rect(x + 2, 2, x + 2, 37, "#6e7a30")
        for y in (10 + (i % 2) * 3, 24 + (i % 3) * 2):
            c.rect(x, y, x + 2, y, "#5a6428")  # коленца
    c.rect(0, 6, 31, 7, "#7a5a3a")  # перекладина
    c.rect(0, 30, 31, 31, "#7a5a3a")
    # фонарь
    c.line(0, 1, 31, 3, "#2b2b30")
    c.rect(13, 3, 18, 4, "#e8c35a")
    c.rect(12, 5, 19, 14, "#d0322a")
    c.rect(11, 7, 20, 12, "#d0322a")
    c.rect(13, 6, 14, 12, "#f06a4a")  # блик
    c.rect(12, 9, 19, 9, "#a8221c")
    c.rect(13, 15, 18, 15, "#e8c35a")
    c.rect(15, 16, 16, 19, "#e8c35a")  # кисточка
    c.rect(0, 37, 31, 39, "#4a3a2a")
    return c


def jar():
    """Глиняный кувшин 20×24."""
    c = Canvas(20, 24)
    c.ellipse(10, 14, 8.5, 9, "#9a5232")
    c.ellipse(8, 12, 4, 5, "#b86a46")
    c.rect(6, 2, 13, 5, "#9a5232")
    c.rect(5, 1, 14, 2, "#b86a46")
    c.rect(4, 13, 15, 13, "#e8c35a")  # узор
    c.rect(4, 15, 15, 15, "#e8c35a")
    c.outline(OUT)
    return c


def rice_sack():
    """Мешок риса 20×20 с нон-ла сверху."""
    c = Canvas(20, 20)
    c.rect(3, 7, 16, 18, "#d8cca8")
    c.rect(2, 9, 17, 17, "#d8cca8")
    c.rect(14, 8, 17, 18, "#b8ac88")
    c.rect(6, 11, 13, 14, "#b8433a")  # печать
    # конусная шляпа нон-ла
    for i in range(7):
        c.rect(10 - i - 1, i + 1, 10 + i, i + 1, "#e8d48a" if i % 2 else "#d8c47a")
    c.outline(OUT)
    return c


def punji(state):
    """Бамбуковые колья — ловушка Вьетнама."""
    c = Canvas(16, 16)
    c.rect(1, 1, 14, 14, "#6a4a2a")
    c.rect(1, 1, 14, 1, "#5a3e22")
    for (x, y) in ((3, 5), (8, 4), (12, 6), (5, 11), (10, 12)):
        c.rect(x, y, x + 1, y + 1, "#3a2814")
        if state == 1:
            c.put(x, y, "#c8c070")
        if state == 2:
            c.rect(x, y - 5, x + 1, y + 1, "#c8c070")
            c.put(x, y - 5, "#f4efe2")
            c.rect(x + 1, y - 4, x + 1, y + 1, "#9a9450")
    return c


def paddy(frame):
    """Мутная вода рисового поля с ростками — яд Вьетнама."""
    c = Canvas(16, 16)
    c.ellipse(8, 8.5, 7.2, 6.2, "#4a5a2a")
    c.ellipse(8, 8.5, 5.5, 4.5, "#5e7034")
    for (x, y) in ((4, 6), (9, 5), (11, 10), (6, 11)):
        c.rect(x, y - 2 - (frame if x % 2 else 0), x, y, "#9ad04a")
    c.rect(5 + frame, 9, 6 + frame, 9, "#8aa858")
    return c


def decor_viet(kind):
    c = Canvas(16, 16)
    if kind == "lotus":
        c.ellipse(8, 9, 6, 4, "#3e7a3a")
        c.ellipse(7, 8, 3, 2, "#5a9a4a")
        c.rect(8, 6, 9, 8, "#f08aa8")
        c.put(8, 5, "#ffc8d8")
    elif kind == "stones":
        for (x, y, r) in ((5, 9, 2.5), (10, 7, 2), (9, 12, 1.5)):
            c.ellipse(x, y, r, r * 0.8, "#8a8478")
            c.put(int(x) - 1, int(y) - 1, "#aaa498")
    elif kind == "sprout":
        for (x, h) in ((5, 5), (8, 7), (11, 4)):
            c.rect(x, 13 - h, x, 13, "#6aa83a")
            c.put(x + 1, 13 - h, "#9ad04a")
    elif kind == "petals":
        for (x, y) in ((3, 4), (9, 7), (12, 3), (6, 12), (11, 12)):
            c.rect(x, y, x + 1, y, "#f08aa8")
    return c


# --- кухня Мазохи ------------------------------------------------------------
def floor_checker():
    """Кухонный линолеум 32×32: тёплый бежевый под паркет, рисунок еле заметен,
    чтобы пол не рябил и враги на нём хорошо читались. (Шахматку владелец забраковал.)"""
    c = Canvas(32, 32)
    rnd = random.Random(44)
    base = ["#b9a682", "#b5a27e", "#bcaa86"]
    for row in range(4):  # «доски» 32×8 со сдвигом
        y0 = row * 8
        c.rect(0, y0, 31, y0 + 7, base[row % 3])
        c.rect(0, y0 + 7, 31, y0 + 7, "#ab9874")  # шов, едва темнее
        seam = (row * 11) % 32
        c.rect(seam, y0, seam, y0 + 6, "#ab9874")
    for _ in range(14):  # потёртости
        c.put(rnd.randrange(32), rnd.randrange(32), rnd.choice(["#b09d79", "#c2b08c"]))
    return c


def wall_kitchen():
    """Стена кухни 32×40: навесной шкафчик, кафельный фартук, столешница."""
    c = Canvas(32, 40)
    c.rect(0, 0, 31, 39, "#e8e4da")
    # навесной шкафчик
    c.rect(0, 0, 31, 13, "#c49a5c")
    c.rect(1, 1, 14, 12, "#d4aa6c")
    c.rect(17, 1, 30, 12, "#d4aa6c")
    c.rect(12, 6, 13, 7, "#8a8478")
    c.rect(18, 6, 19, 7, "#8a8478")
    c.rect(0, 13, 31, 13, "#8a6334")
    # кафель
    for y in range(15, 30, 5):
        for x in range(0, 32, 5):
            c.rect(x, y, x + 3, y + 3, "#dfe8ea" if (x // 5 + y // 5) % 2 else "#cfdde0")
    c.rect(22, 21, 24, 23, "#b8a888")  # пятно жира
    # столешница и шкафы внизу
    c.rect(0, 30, 31, 31, "#6a6a72")
    c.rect(0, 32, 31, 39, "#c49a5c")
    c.rect(0, 32, 31, 32, "#d4aa6c")
    c.rect(15, 33, 16, 38, "#8a6334")
    c.rect(0, 39, 31, 39, "#6e4a2a")
    return c


def washer():
    """Стиральная машина 22×24, в окне крутятся носки."""
    c = Canvas(22, 24)
    c.rect(1, 1, 20, 22, "#e8e8ec")
    c.rect(16, 1, 20, 22, "#c8c8d0")
    c.rect(1, 1, 20, 5, "#d0d0d8")
    c.rect(3, 2, 8, 3, "#5a5a66")  # панель
    c.rect(13, 2, 14, 3, "#4fb0d8")
    c.ellipse(10, 14, 6, 6, "#5a5a66")
    c.ellipse(10, 14, 4.5, 4.5, "#4f7aa8")
    c.rect(8, 12, 10, 15, "#ddd5c0")  # носок в барабане
    c.rect(8, 12, 10, 12, "#b8433a")
    c.outline(OUT)
    return c


def decor_kitchen(kind):
    c = Canvas(16, 16)
    if kind == "cans":
        for (x, y, rot) in ((3, 6, 0), (9, 10, 1)):
            if rot:
                c.rect(x, y, x + 5, y + 2, "#c79a2c")
                c.rect(x + 2, y, x + 3, y + 2, "#7a2420")
            else:
                c.rect(x, y, x + 2, y + 4, "#c79a2c")
                c.rect(x, y + 1, x + 2, y + 2, "#7a2420")
    elif kind == "crumbs":
        for (x, y) in ((4, 5), (6, 6), (10, 9), (11, 11), (5, 12), (13, 4)):
            c.put(x, y, "#c8a060")
    elif kind == "sock":
        c.rect(4, 6, 7, 11, "#ddd5c0")
        c.rect(4, 10, 11, 12, "#ddd5c0")
        c.rect(4, 6, 7, 6, "#b8433a")
        c.rect(10, 11, 11, 12, "#8a6b3a")
    elif kind == "spill":
        c.ellipse(8, 9, 6, 3.5, (200, 170, 70, 150))
        c.ellipse(7, 8.5, 3, 1.5, (230, 200, 90, 170))
    return c
