"""Тайлы, мебель квартиры, ловушки, лужи и иконки."""

import random

from px import Canvas

OUT = "#1b1420"


# --- тайлы ------------------------------------------------------------------
def floor_wood():
    """Ламинат: 32×16, повторяется."""
    c = Canvas(32, 16)
    rnd = random.Random(3)
    tones = ["#8a5a3c", "#93623f", "#835437"]
    for row in range(4):
        y0 = row * 4
        shift = (row * 13) % 32
        for x in range(32):
            seam = (x - shift) % 32 in (0, 16 + (row % 2) * 4)
            col = "#5e3a26" if seam else tones[(row + (x - shift) // 16) % 3]
            for y in range(y0, y0 + 4):
                c.put(x, y, col)
        c.rect(0, y0 + 3, 31, y0 + 3, "#6e4530")
        for _ in range(3):
            x = rnd.randrange(32)
            c.put(x, y0 + 1, "#9c6c48")
    return c


def floor_concrete():
    """Плитка подвала: 32×32, четыре плитки с щербинами."""
    c = Canvas(32, 32)
    rnd = random.Random(7)
    for ty in range(2):
        for tx in range(2):
            base = ["#5a5f6b", "#555a66", "#5e636e", "#535864"][ty * 2 + tx]
            c.rect(tx * 16, ty * 16, tx * 16 + 15, ty * 16 + 15, base)
            c.rect(tx * 16, ty * 16, tx * 16 + 15, ty * 16, "#666b77")
            c.rect(tx * 16, ty * 16, tx * 16, ty * 16 + 15, "#666b77")
            c.rect(tx * 16 + 15, ty * 16, tx * 16 + 15, ty * 16 + 15, "#43474f")
            c.rect(tx * 16, ty * 16 + 15, tx * 16 + 15, ty * 16 + 15, "#43474f")
            for _ in range(4):
                c.put(tx * 16 + rnd.randrange(2, 14), ty * 16 + rnd.randrange(2, 14), "#4c505b")
    c.line(19, 4, 23, 9, "#43474f")  # трещина
    c.line(23, 9, 22, 12, "#43474f")
    return c


def wall_wallpaper():
    """Обои над плинтусом: 32×40 (видимая высота стены)."""
    c = Canvas(32, 40)
    c.rect(0, 0, 31, 39, "#b9b48f")
    for y in range(4, 34, 8):
        for x in range(0, 32, 8):
            ox = 4 if (y // 8) % 2 else 0
            c.put((x + ox) % 32, y, "#a39e78")
            c.put((x + ox + 1) % 32, y + 1, "#a39e78")
            c.put((x + ox) % 32, y + 2, "#a39e78")
    c.rect(0, 0, 31, 1, "#8f8a68")
    c.rect(0, 34, 31, 39, "#6e4a33")  # плинтус
    c.rect(0, 34, 31, 34, "#8a6145")
    c.rect(0, 39, 31, 39, "#4d3222")
    return c


def wall_brick():
    c = Canvas(32, 40)
    c.rect(0, 0, 31, 39, "#4a3f3d")
    for row in range(8):
        y = row * 5
        off = 0 if row % 2 else 8
        for bx in range(-16, 32, 16):
            x0 = bx + off
            c.rect(x0 + 1, y + 1, x0 + 14, y + 4, ["#6b4b42", "#734f45", "#654640"][(row + bx // 16) % 3])
            c.rect(x0 + 1, y + 1, x0 + 14, y + 1, "#82594d")
    c.rect(0, 36, 31, 39, "#2f2828")
    return c


# --- мебель квартиры --------------------------------------------------------
def desk():
    """Стол с компьютером, 56×36, вид 3/4."""
    c = Canvas(56, 36)
    # монитор
    c.rect(18, 1, 41, 15, "#26232a")
    c.rect(20, 3, 39, 13, "#3d6fa8")
    c.rect(20, 3, 39, 4, "#6a9bd0")
    c.rect(22, 7, 31, 7, "#a9d2ff")  # строчки «Тихого Дена»
    c.rect(22, 9, 35, 9, "#a9d2ff")
    c.rect(22, 11, 29, 11, "#a9d2ff")
    c.rect(28, 16, 31, 18, "#26232a")
    c.rect(25, 18, 34, 18, "#26232a")
    # микрофон на стойке
    c.line(45, 4, 48, 14, "#3a363e")
    c.rect(43, 1, 46, 6, "#55505a")
    c.rect(43, 1, 46, 1, "#77707e")
    # столешница
    c.rect(2, 19, 53, 25, "#6e4a33")
    c.rect(2, 19, 53, 19, "#8a6145")
    c.rect(2, 26, 53, 27, "#4d3222")
    c.rect(20, 21, 37, 23, "#2c2a31")  # клавиатура
    c.rect(21, 21, 36, 21, "#45424c")
    c.rect(40, 21, 44, 23, "#2c2a31")  # мышь
    c.rect(4, 28, 7, 35, "#4d3222")  # ножки
    c.rect(48, 28, 51, 35, "#4d3222")
    c.outline(OUT)
    return c


def chair():
    c = Canvas(20, 26)
    c.rect(3, 0, 16, 13, "#2e2b33")
    c.rect(5, 2, 14, 11, "#b8433a")
    c.rect(2, 13, 17, 17, "#2e2b33")
    c.rect(9, 18, 10, 22, "#26232a")
    c.rect(4, 23, 15, 24, "#26232a")
    c.outline(OUT)
    return c


def poster():
    """Плакат с ковбоем на закате, 24×32."""
    c = Canvas(24, 32)
    c.rect(0, 0, 23, 31, "#d8c39a")
    c.rect(2, 2, 21, 25, "#c4552e")
    c.rect(2, 14, 21, 25, "#8f3122")
    c.ellipse(12, 14, 5, 5, "#f0b04a")
    c.rect(2, 19, 21, 25, "#3a1d1a")  # силуэт
    c.rect(8, 9, 15, 10, "#1e1210")  # шляпа
    c.rect(10, 6, 13, 9, "#1e1210")
    c.rect(10, 11, 13, 14, "#1e1210")  # голова
    c.rect(7, 15, 16, 24, "#1e1210")  # плечи
    c.rect(3, 27, 20, 28, "#3a1d1a")  # «название»
    c.rect(6, 30, 17, 30, "#7a5a40")
    c.outline(OUT)
    return c


def fan():
    """Восточный складной веер, 40×22: складки-лучи от оси внизу, зубчатый край,
    деревянные пластины у оси, ветка сливы."""
    import math
    c = Canvas(40, 22)
    cx, cy = 20, 21
    pleats = 14
    for y in range(22):
        for x in range(40):
            dx, dy = x + 0.5 - cx, cy - (y + 0.5)
            if dy < 0:
                continue
            r = math.hypot(dx, dy)
            ang = math.atan2(dy, dx)  # 0..pi
            k = int(ang / math.pi * pleats)
            edge = 19.5 if k % 2 == 0 else 18.5  # зубчатый край складок
            if r > edge or r < 2:
                continue
            if r < 7.5:
                col = "#7a4a26" if k % 2 == 0 else "#5e3a1e"  # пластины
            elif r > edge - 1.2:
                col = "#e8c35a"  # золотой кант
            else:
                col = "#d04a3c" if k % 2 == 0 else "#932c26"
            c.put(x, y, col)
    # ветка сливы
    c.line(9, 12, 16, 8, "#4a2a1e")
    c.line(16, 8, 22, 7, "#4a2a1e")
    c.line(14, 9, 15, 5, "#4a2a1e")
    for (x, y) in ((15, 4), (22, 6), (11, 10), (19, 7), (25, 8)):
        c.rect(x, y, x + 1, y + 1, "#f6d0d8")
        c.put(x, y, "#fff2f4")
    c.rect(19, 19, 21, 21, "#e8c35a")  # ось
    c.outline(OUT)
    return c


def tv(broken):
    c = Canvas(34, 26)
    c.rect(1, 0, 32, 20, "#25222a")
    c.rect(3, 2, 30, 18, "#2f4a5c" if not broken else "#1a1a20")
    if not broken:
        c.rect(3, 2, 30, 3, "#4d7186")
        c.rect(5, 5, 9, 6, "#4d7186")
    else:
        for (a, b) in (((16, 9), (4, 3)), ((16, 9), (29, 4)), ((16, 9), (8, 17)), ((16, 9), (27, 17)), ((16, 9), (30, 11))):
            c.line(*a, *b, "#b9c3cc")
        c.rect(15, 8, 17, 10, "#e8eef2")
    c.rect(14, 21, 19, 22, "#25222a")
    c.rect(4, 23, 29, 25, "#4d3222")  # тумба
    c.rect(4, 23, 29, 23, "#6e4a33")
    c.outline(OUT)
    return c


def window():
    c = Canvas(40, 34)
    c.rect(2, 2, 37, 31, "#d8dce0")
    c.rect(4, 4, 35, 29, "#8fb6d6")
    c.rect(19, 4, 20, 29, "#d8dce0")
    # занавеска почти закрыта
    for x in range(2, 38):
        if x < 17 or x > 22:
            shade = "#7d6a8f" if (x // 3) % 2 else "#8e7aa1"
            c.rect(x, 0, x, 33, shade)
    c.rect(0, 0, 39, 1, "#4d3222")
    c.outline(OUT)
    return c


def bed():
    """Односпальная кровать вдоль нижней стены, 64×32."""
    c = Canvas(64, 32)
    c.rect(0, 4, 63, 27, "#6e4a33")  # рама
    c.rect(2, 2, 61, 21, "#c9c6d6")  # простыня
    c.rect(2, 8, 47, 21, "#5c7aa8")  # одеяло
    c.rect(2, 8, 47, 9, "#7b98c4")
    c.rect(2, 20, 47, 21, "#45608a")
    c.rect(50, 4, 60, 14, "#ecebf2")  # подушка
    c.rect(50, 13, 60, 14, "#c9c6d6")
    c.rect(0, 22, 63, 27, "#5a3c28")
    c.rect(0, 22, 63, 22, "#7a5238")
    c.rect(1, 28, 4, 31, "#4d3222")
    c.rect(59, 28, 62, 31, "#4d3222")
    c.outline(OUT)
    return c


def door(open_):
    c = Canvas(28, 40)
    c.rect(0, 0, 27, 39, "#4d3222")
    if open_:
        c.rect(3, 3, 24, 39, "#120e14")
        c.rect(3, 3, 24, 5, "#231b26")
    else:
        c.rect(3, 3, 24, 39, "#8a6145")
        c.rect(5, 5, 22, 18, "#7a5238")
        c.rect(5, 21, 22, 36, "#7a5238")
        c.rect(20, 20, 22, 21, "#d9c070")
    c.outline(OUT)
    return c


def trophy_frame(kind):
    """Трофей на стену, 26×28: голова поверженного босса на деревянном щите,
    как охотничий трофей."""
    c = Canvas(26, 28)
    # щит: дерево с золотой кромкой
    c.ellipse(13, 17, 11.5, 10, "#b08a3a")
    c.ellipse(13, 17, 10, 8.5, "#6e4a33")
    c.ellipse(11, 15, 6, 4, "#7d5539")
    c.rect(11, 25, 15, 26, "#b08a3a")  # табличка
    if kind == "mazokha":
        SK, SKD, HAIR, HS = "#f0c4a8", "#d29e82", "#3b2f2a", "#7a6155"
        c.ellipse(13, 12, 8, 8, SK)  # круглая голова
        c.ellipse(16, 13, 4.5, 6, SKD)
        for x in range(26):  # ёжик
            for y in range(3, 8):
                if c.get(x, y) in (hexc_(SK), hexc_(SKD)):
                    c.put(x, y, HAIR if (x + y) % 3 else HS)
        c.rect(4, 11, 4, 13, SKD)  # уши
        c.rect(21, 11, 21, 13, SKD)
        c.rect(8, 10, 10, 10, "#1b1420")  # прищур
        c.rect(15, 10, 17, 10, "#1b1420")
        c.rect(8, 14, 17, 16, "#6b2a2a")  # улыбка
        c.rect(8, 14, 17, 14, "#f7f4ec")
        c.rect(11, 17, 15, 19, HAIR)  # бородка
        c.rect(12, 20, 14, 20, HAIR)
        c.rect(9, 20, 17, 22, "#252a40")  # воротник футболки
    c.outline(OUT)
    return c


def hexc_(h):
    from px import hexc
    return hexc(h)


def note_paper():
    """Записка, приколотая к стене, 14×16: тетрадный листок в клетку, красная кнопка."""
    c = Canvas(14, 16)
    c.rect(1, 2, 12, 15, "#f4efe2")
    for x in range(2, 12, 3):
        c.rect(x, 3, x, 14, "#dfe6ee")
    for y in range(4, 15, 3):
        c.rect(1, y, 12, y, "#dfe6ee")
    for y in (5, 8, 11):
        c.rect(3, y, 10, y, "#5b5b7a")
    c.rect(3, 13, 7, 13, "#5b5b7a")
    c.rect(12, 14, 12, 15, "#cfc8b5")  # загнутый уголок
    c.outline(OUT)
    c.rect(6, 0, 7, 2, "#d8434f")  # кнопка
    c.put(6, 0, "#f08a8f")
    return c


def beer_can():
    c = Canvas(8, 12)
    c.rect(1, 1, 6, 10, "#c79a2c")
    c.rect(1, 3, 6, 6, "#7a2420")  # этикетка «Бояринъ»
    c.rect(2, 4, 5, 4, "#e8c35a")
    c.rect(1, 0, 6, 0, "#b9b2a3")
    c.rect(5, 1, 6, 10, "#9c7820")
    c.outline(OUT)
    return c


def vodka():
    c = Canvas(8, 18)
    c.rect(3, 0, 4, 1, "#b8433a")
    c.rect(3, 2, 4, 5, "#d6e4ea")
    c.rect(1, 6, 6, 16, "#d6e4ea")
    c.rect(1, 9, 6, 13, "#f4efe2")
    c.rect(2, 10, 5, 10, "#b8433a")
    c.rect(5, 6, 6, 16, "#aebfc8")
    c.outline(OUT)
    return c


# --- бой ------------------------------------------------------------------
def spikes(state):
    """Колья, 16×16: 0 — отверстия, 1 — предупреждение, 2 — подняты."""
    c = Canvas(16, 16)
    c.rect(1, 1, 14, 14, "#43474f")
    c.rect(1, 1, 14, 1, "#3a3d45")
    for (x, y) in ((4, 4), (10, 4), (4, 10), (10, 10)):
        c.rect(x, y, x + 1, y + 1, "#1e2026")
        if state == 1:
            c.put(x, y, "#9aa1ad")
        if state == 2:
            c.rect(x, y - 4, x + 1, y + 1, "#b9c0cc")
            c.put(x, y - 4, "#e8ecf2")
            c.rect(x + 1, y - 3, x + 1, y + 1, "#8a919c")
    return c


def poison(frame):
    c = Canvas(16, 16)
    c.ellipse(8, 8.5, 7.2, 6.2, "#4e7a2e")
    c.ellipse(8, 8.5, 5.5, 4.5, "#6aa23a")
    bubbles = [((5, 6), (10, 9)), ((9, 5), (6, 10))][frame]
    for (x, y) in bubbles:
        c.rect(x, y, x + 1, y + 1, "#a8d86a")
    return c


def puddle(frame):
    """Лужа блевоты от «Бояринъ», 64×40 (вчетверо больше Озона по площади следа),
    кадры: растекается (0, 1), булькает (2, 3)."""
    import math
    c = Canvas(64, 40)
    r = [0.5, 0.82, 1.0, 1.0][frame]
    rnd = random.Random(11)
    # неровный край: эллипс с волнистым радиусом
    for y in range(40):
        for x in range(64):
            dx, dy = (x + 0.5 - 32) / 30.0, (y + 0.5 - 20) / 18.0
            ang = math.atan2(dy, dx)
            wob = 1.0 + 0.08 * math.sin(ang * 5 + 1) + 0.05 * math.sin(ang * 9)
            d = math.hypot(dx, dy) / (r * wob)
            if d <= 1.0:
                c.put(x, y, "#8f9a2a" if d > 0.86 else ("#b5c23a" if d > 0.35 or (x + y) % 7 else "#c5d24a"))
    # брызги вокруг
    for (x, y) in ((4, 9), (59, 30), (12, 35), (54, 6), (2, 24), (61, 17)):
        if r > 0.8:
            c.rect(x, y, x + 1, y + 1, "#8f9a2a")
    # куски и пузыри
    if frame >= 2:
        for _ in range(9):
            x, y = rnd.randrange(14, 50), rnd.randrange(10, 30)
            c.rect(x, y, x + 1, y, "#d6a84a")  # кусочки
        bubbles = [(20, 15), (40, 23), (31, 12), (25, 27)] if frame == 2 else [(23, 21), (43, 14), (34, 26), (16, 18)]
        for (x, y) in bubbles:
            c.rect(x, y, x + 2, y + 1, "#d6e05a")
            c.put(x + 1, y - 1, "#e8f07a")
            c.put(x + 3, y + 1, "#7f8a22")
    return c


def crate():
    c = Canvas(20, 22)
    c.rect(1, 0, 18, 7, "#c49a5c")  # крышка, вид сверху
    c.rect(1, 7, 18, 20, "#a37a42")
    c.rect(9, 0, 10, 7, "#d9b878")  # скотч
    c.rect(9, 8, 10, 13, "#d9b878")
    c.rect(1, 7, 18, 7, "#8a6334")
    c.rect(3, 15, 7, 16, "#6b4a24")  # надпись маркером
    c.outline(OUT)
    return c


def basket():
    """Корзина для белья: гнездо носков, 22×22."""
    c = Canvas(22, 22)
    c.rect(1, 3, 20, 21, "#9a8a6a")
    c.rect(1, 3, 20, 5, "#7a6c50")
    for x in range(2, 20, 3):
        c.rect(x, 7, x, 20, "#86765a")
    c.rect(4, 0, 9, 4, "#ddd5c0")
    c.rect(4, 1, 9, 1, "#b8433a")
    c.rect(12, 1, 17, 4, "#ddd5c0")
    c.rect(12, 2, 17, 2, "#5d8a3a")
    c.outline(OUT)
    return c


def shadow(w, h):
    c = Canvas(w, h)
    c.ellipse(w / 2, h / 2, w / 2, h / 2, (20, 14, 24, 90))
    return c


# --- иконки -----------------------------------------------------------------
def icon_beer():
    c = Canvas(16, 16)
    c.rect(4, 2, 11, 14, "#c79a2c")
    c.rect(4, 5, 11, 9, "#7a2420")
    c.rect(5, 6, 10, 6, "#e8c35a")
    c.rect(4, 1, 11, 1, "#b9b2a3")
    c.rect(10, 2, 11, 14, "#9c7820")
    c.outline(OUT)
    return c


def icon_vodka():
    c = Canvas(16, 16)
    c.rect(7, 0, 8, 1, "#b8433a")
    c.rect(7, 2, 8, 4, "#d6e4ea")
    c.rect(4, 5, 11, 15, "#d6e4ea")
    c.rect(4, 8, 11, 12, "#f4efe2")
    c.rect(5, 9, 10, 9, "#b8433a")
    c.rect(10, 5, 11, 15, "#aebfc8")
    c.outline(OUT)
    return c


def icon_heart():
    c = Canvas(9, 8)
    rows = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == "1":
                c.put(x + 1, y + 1, "#d8434f")
    c.put(2, 2, "#f08a8f")
    c.outline(OUT)
    return c


def icon_life():
    """Вторая жизнь: банка с крылышками."""
    c = Canvas(12, 10)
    c.rect(4, 1, 7, 8, "#e8c35a")
    c.rect(4, 3, 7, 5, "#b8433a")
    c.rect(0, 2, 3, 4, "#f4efe2")
    c.rect(8, 2, 11, 4, "#f4efe2")
    c.rect(1, 5, 3, 5, "#f4efe2")
    c.rect(8, 5, 10, 5, "#f4efe2")
    c.outline(OUT)
    return c


def panel(dark):
    """9-slice панель с пиксельными углами, 12×12 (поля 4)."""
    c = Canvas(12, 12)
    fill = "#231d29" if dark else "#efe4c8"
    edge = "#463a52" if dark else "#c9b88f"
    c.rect(2, 0, 9, 11, fill)
    c.rect(0, 2, 11, 9, fill)
    c.rect(1, 1, 10, 10, fill)
    c.rect(2, 0, 9, 0, edge)
    c.rect(2, 11, 9, 11, edge)
    c.rect(0, 2, 0, 9, edge)
    c.rect(11, 2, 11, 9, edge)
    for (x, y) in ((1, 1), (10, 1), (1, 10), (10, 10)):
        c.put(x, y, edge)
    return c


def panel_focus():
    """Рамка выделения 12×12: золотой край в 2 px с пиксельными углами, внутри пусто."""
    c = Canvas(12, 12)
    g = "#e8c35a"
    c.rect(2, 0, 9, 1, g)
    c.rect(2, 10, 9, 11, g)
    c.rect(0, 2, 1, 9, g)
    c.rect(10, 2, 11, 9, g)
    for (x, y) in ((1, 1), (10, 1), (1, 10), (10, 10)):
        c.put(x, y, g)
    return c


def book_page():
    c = Canvas(14, 16)
    c.rect(1, 0, 12, 15, "#efe4c8")
    c.rect(11, 0, 12, 15, "#d4c7a5")
    for y in (3, 6, 9, 12):
        c.rect(3, y, 9, y, "#8a7a5a")
    c.outline(OUT)
    return c


# --- картинки алертов доната, 40×40, по два кадра ------------------------------
def alert_heal(frame):
    """Шаурма: лаваш с полосками от гриля, сверху начинка, низ в бумажке, пар."""
    c = Canvas(40, 40)
    LAV, LAV_D, LAV_L, GRILL = "#e2c27f", "#c9a25e", "#f0d9a4", "#9a6326"
    c.rect(12, 9, 27, 26, LAV)  # лаваш
    c.rect(12, 9, 13, 26, LAV_L)
    c.rect(25, 9, 27, 26, LAV_D)
    for (x, y) in ((15, 13), (20, 12), (16, 19), (22, 17), (18, 24), (23, 22)):
        c.line(x, y, x + 3, y - 2, GRILL)  # следы гриля
    c.ellipse(20, 9, 8.5, 3.6, LAV_L)  # край лаваша
    c.ellipse(20, 9, 6.8, 2.6, "#7a3f22")  # начинка
    c.rect(15, 8, 17, 9, "#a8582e")  # мясо
    c.rect(21, 7, 23, 8, "#a8582e")
    c.rect(18, 7, 19, 8, "#d8433a")  # помидор
    c.rect(24, 9, 25, 9, "#d8433a")
    c.rect(19, 10, 21, 10, "#6fae3e")  # огурец
    c.rect(14, 10, 15, 10, "#f4f1e6")  # капуста
    c.rect(22, 10, 23, 10, "#f4f1e6")
    c.rect(11, 25, 28, 34, "#f4efe2")  # бумажка
    c.rect(12, 35, 27, 36, "#f4efe2")
    c.rect(11, 28, 28, 29, "#c23b33")
    c.rect(25, 25, 28, 36, "#d9d2c0")
    c.line(11, 25, 16, 27, "#d9d2c0")
    c.outline(OUT)
    # пар без обводки
    for (x, h) in ((16, 0), (23, 1)):
        o = (frame + h) % 2
        for (dx, y) in ((o, 4), (1 - o, 2), (o, 0)):
            c.put(x + dx, y, (233, 228, 220, 170))
    return c


def alert_life(frame):
    """Банка с крылышками и нимбом."""
    c = Canvas(40, 40)
    y = -2 if frame else 0
    c.rect(14, 4 + y, 25, 5 + y, "#e8c35a")  # нимб
    c.rect(13, 3 + y, 13, 3 + y, "#e8c35a")
    c.rect(26, 3 + y, 26, 3 + y, "#e8c35a")
    c.rect(15, 10 + y, 24, 31 + y, "#c79a2c")
    c.rect(15, 15 + y, 24, 22 + y, "#7a2420")
    c.rect(17, 17 + y, 22, 17 + y, "#e8c35a")
    c.rect(22, 10 + y, 24, 31 + y, "#9c7820")
    c.rect(15, 9 + y, 24, 9 + y, "#b9b2a3")
    wing = 3 if frame else 0
    for (x0, d) in ((14, -1), (25, 1)):
        for i in range(9):
            xx = x0 + d * i
            c.rect(xx, 14 + y - (wing if i > 4 else 0) + i // 3, xx, 20 + y - i // 2, "#f4efe2")
    c.outline(OUT)
    return c


def alert_rage(frame):
    """Кулак 👊 на комиксной вспышке."""
    import math
    c = Canvas(40, 40)
    # вспышка: звезда с лучами, лучи меняются между кадрами
    pts = []
    n = 12
    for i in range(n * 2):
        r = (19 if (i // 2 + frame) % 2 == 0 else 15) if i % 2 == 0 else 10
        a = math.pi * i / n + (0.13 if frame else 0)
        pts.append((20 + r * math.cos(a), 19 + r * math.sin(a)))
    for y in range(40):
        for x in range(40):
            inside = False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > y + 0.5) != (yj > y + 0.5) and x + 0.5 < (xj - xi) * (y + 0.5 - yi) / (yj - yi) + xi:
                    inside = not inside
                j = i
            if inside:
                c.put(x, y, "#e8873a")
    c.ellipse(20, 19, 10, 10, "#f2c94c")
    SK, SK_D, SK_L = "#e8b796", "#c98e6f", "#f5d2b8"
    ox, oy = 9, 8
    for i in range(4):  # костяшки
        x0 = ox + 1 + i * 5
        c.rect(x0, oy, x0 + 4, oy + 9, SK)
        c.clear(x0, oy) if False else None
        c.rect(x0 + 1, oy + 1, x0 + 2, oy + 1, SK_L)
        c.rect(x0 + 4, oy + 2, x0 + 4, oy + 9, SK_D)
    c.rect(ox + 1, oy + 10, ox + 20, oy + 15, SK)  # кисть
    c.rect(ox + 18, oy + 10, ox + 20, oy + 15, SK_D)
    c.rect(ox, oy + 8, ox + 12, oy + 12, SK)  # большой палец поперёк
    c.rect(ox, oy + 7, ox + 12, oy + 7, SK_D)
    c.rect(ox + 10, oy + 9, ox + 11, oy + 10, SK_L)  # ноготь
    c.rect(ox + 13, oy + 8, ox + 13, oy + 12, SK_D)
    c.rect(ox, oy + 13, ox + 12, oy + 13, SK_D)
    c.rect(ox + 4, oy + 16, ox + 17, oy + 21, "#56657f")  # рукав
    c.rect(ox + 4, oy + 16, ox + 17, oy + 16, "#6c7d9a")
    c.outline(OUT)
    return c


# --- иконка приложения и фон окна установщика ----------------------------------
def app_icon(ozon_frame):
    """64×64: плашка с пиксельными углами в рамке, на ней Озон по пояс (кадр ×2).
    Поля 6 px со всех сторон — как у иконок macOS (824 из 1024)."""
    from PIL import Image
    c = Canvas(64, 64)
    x0, y0, x1, y1 = 6, 6, 57, 57
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            dx, dy = min(x - x0, x1 - x), min(y - y0, y1 - y)
            if dx + dy < 4 or (dx < 2 and dy < 2):
                continue
            t = (y - y0) / (y1 - y0)
            col = (int(58 - 26 * t), int(44 - 18 * t), int(70 - 30 * t), 255)
            c.put(x, y, col)
    for (x, y) in ((14, 14), (48, 12), (52, 24), (11, 30)):
        c.put(x, y, "#e8c35a")  # звёзды
    # кромка
    edge = (232, 195, 90, 255)
    for y in range(64):
        for x in range(64):
            if c.get(x, y)[3] == 0:
                for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if c.get(x + ddx, y + ddy)[3] and c.get(x + ddx, y + ddy) != edge:
                        c.put(x, y, edge)
                        break
    # Озон по пояс: верх кадра 32×32, увеличенный вдвое
    bust = ozon_frame.img.crop((6, 0, 26, 22)).resize((40, 44), Image.NEAREST)
    mask = Image.new("L", (64, 64), 0)
    body = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    body.paste(bust, (12, 14))
    # обрезаем по плашке, чтобы плечи не вылезали за рамку
    for y in range(64):
        for x in range(64):
            if y <= y1 - 2 and c.get(x, y)[3] and c.get(x, y) != edge:
                mask.putpixel((x, y), 255)
    c.img.paste(body, (0, 0), Image.composite(body, Image.new("RGBA", (64, 64)), mask))
    c.px = c.img.load()
    return c


def dmg_background(font_path):
    """Фон окна .dmg, 300×200 (в окне ×2 = 600×400). Иконки встают в (75, 95)
    и (225, 95) — между ними пиксельная стрелка, снизу подпись."""
    from PIL import Image, ImageDraw, ImageFont
    c = Canvas(300, 200)
    for y in range(200):
        t = y / 199
        c.rect(0, y, 299, y, (int(42 - 14 * t), int(33 - 10 * t), int(52 - 18 * t), 255))
    rnd = random.Random(5)
    for _ in range(40):
        x, y = rnd.randrange(300), rnd.randrange(150)
        c.put(x, y, (232, 195, 90, rnd.choice((90, 140, 200))))
    # пол-доска внизу
    for y in range(168, 200):
        for x in range(300):
            seam = (x + (y // 4) * 13) % 32 == 0
            c.put(x, y, "#5e3a26" if seam or y % 4 == 3 else ("#8a5a3c" if (y // 4) % 2 else "#835437"))
    c.rect(0, 166, 299, 167, "#4d3222")
    # стрелка
    ay = 95
    c.rect(118, ay - 3, 170, ay + 2, "#e8c35a")
    for i in range(10):
        c.rect(171 + i, ay - 9 + i, 171 + i, ay + 8 - i, "#e8c35a")
    for x in range(118, 171, 6):
        c.rect(x, ay - 3, x + 2, ay + 2, "#f2d37a")
    c.outline(OUT)
    img = c.img
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    font = ImageFont.truetype(font_path, 8)
    for text, y, col in (("Перетащи Озона в «Программы»", 146, (244, 239, 226)),
                         ("а Меддисон пусть пока подождёт", 158, (168, 159, 179))):
        w = d.textlength(text, font=font)
        x = int((300 - w) / 2)
        for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            d.text((x + ox, y + oy), text, font=font, fill=(27, 20, 32))
        d.text((x, y), text, font=font, fill=col)
    big = ImageFont.truetype(font_path, 16)
    title = "OZON ETERNAL"
    w = d.textlength(title, font=big)
    x = int((300 - w) / 2)
    for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1)):
        d.text((x + ox, 14 + oy), title, font=big, fill=(27, 20, 32))
    d.text((x, 14), title, font=big, fill=(232, 195, 90))
    return img


def icon_dash():
    """Рывок: кроссовок с полосками скорости, 16×16."""
    c = Canvas(16, 16)
    c.rect(6, 6, 11, 10, "#e8e2d4")  # верх кроссовка
    c.rect(5, 9, 14, 11, "#e8e2d4")  # носок
    c.rect(5, 12, 14, 12, "#b8433a")  # подошва
    c.rect(7, 7, 10, 7, "#56657f")  # шнурки
    c.rect(8, 9, 11, 9, "#56657f")
    c.rect(13, 10, 14, 11, "#c9c2b2")
    c.outline(OUT)
    for (y, x0, x1) in ((5, 0, 3), (8, 1, 3), (11, 0, 2)):
        c.rect(x0, y, x1, y, "#8fd0ff")  # полоски скорости
    return c
