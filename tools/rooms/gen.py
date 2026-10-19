"""Собирает карты арен в data/rooms/*.txt из фигур. Карты потом можно править руками.

Клетка 16×16. Обозначения:
  #  пустота (стена, колонна, провал)   .  пол
  ^  колья                              ~  яд
  c  коробка                            b  корзина с носками
  @  старт Озона                        D  дверь выхода (левая из двух клеток, над ней стена)
  M  Мазоха

Проверка: над каждой клеткой пола, у которой сверху пустота, пустоты должно быть
не меньше трёх клеток — туда рисуется стена высотой 40 px.
"""

import math
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "rooms")


class Map:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["#"] * w for _ in range(h)]

    def rect(self, x0, y0, x1, y1, ch="."):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = ch

    def ellipse(self, cx, cy, rx, ry, ch="."):
        for y in range(self.h):
            for x in range(self.w):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.g[y][x] = ch

    def octagon(self, x0, y0, x1, y1, cut, ch="."):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                dx = min(x - x0, x1 - x)
                dy = min(y - y0, y1 - y)
                if dx + dy >= cut:
                    self.g[y][x] = ch

    def put(self, x, y, ch):
        assert self.g[y][x] != "#", f"{ch} на пустоте {x},{y}"
        self.g[y][x] = ch

    def check(self, name):
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] != "#" and y > 0 and self.g[y - 1][x] == "#":
                    run = 0
                    while y - 1 - run >= 0 and self.g[y - 1 - run][x] == "#":
                        run += 1
                    assert run >= 3 or y - run == 0, f"{name}: над {x},{y} пустоты {run} — стена наедет на пол"
        for y in (0, self.h - 1):
            assert all(c == "#" for c in self.g[y]), f"{name}: край не пустой"

    def save(self, name):
        self.check(name)
        os.makedirs(OUT, exist_ok=True)
        with open(os.path.join(OUT, name + ".txt"), "w") as f:
            f.write("\n".join("".join(r) for r in self.g) + "\n")


def room1():
    """Крест: квадрат в центре и четыре широких рукава, колонны по углам квадрата."""
    m = Map(46, 38)
    m.rect(14, 4, 31, 35)  # вертикальный рукав
    m.rect(3, 13, 42, 27)  # горизонтальный
    m.rect(10, 10, 35, 30)  # центр
    for (x, y) in ((14, 13), (30, 13), (14, 25), (30, 25)):
        m.rect(x, y, x + 1, y + 2, "#")  # колонны 2×3
    for x in range(20, 26):
        m.put(x, 20, "^")
    m.put(21, 4, "D")
    m.put(22, 33, "@")
    m.put(6, 15, "b")
    m.put(39, 25, "c")
    m.put(40, 15, "c")
    m.put(5, 25, "c")
    return m


def room2():
    """Зигзаг: две большие площадки, соединённые широким ходом, поперёк — ядовитый ручей."""
    m = Map(54, 40)
    m.rect(3, 4, 24, 18)  # верхняя левая площадка
    m.rect(28, 20, 50, 36)  # нижняя правая
    m.rect(16, 14, 36, 25)  # ход
    m.octagon(3, 4, 24, 18, 3, "#")
    m.octagon(3, 4, 24, 18, 3, ".")
    for y in range(4, 7):  # срез верхних углов
        for x in range(3, 3 + (7 - y)):
            m.g[y][x] = "#"
    # ручей яда по диагонали хода
    for i in range(10):
        x, y = 19 + i * 2, 15 + i
        if y <= 25:
            for dx in (0, 1):
                if m.g[y][x + dx] == ".":
                    m.g[y][x + dx] = "~"
    for (x, y) in ((10, 10), (11, 10), (40, 28), (41, 28)):
        m.put(x, y, "^")
    m.rect(38, 30, 39, 32, "#")  # колонна на нижней площадке
    m.put(12, 4, "D")
    m.put(46, 34, "@")
    m.put(5, 16, "b")
    m.put(30, 22, "c")
    m.put(47, 22, "c")
    m.put(20, 8, "c")
    return m


def room3():
    """Кольцо вокруг провала: большой эллипс, в середине провал, через него мостик с кольями."""
    m = Map(56, 42)
    m.ellipse(28, 21, 25, 17.5)
    m.octagon(17, 14, 38, 27, 3, "#")  # провал
    m.rect(26, 8, 29, 34)  # мостик сверху вниз через провал
    for (x, y) in ((26, 12), (27, 12), (28, 12), (29, 12), (26, 29), (27, 29), (28, 29), (29, 29)):
        m.put(x, y, "^")
    for (x, y) in ((8, 14), (8, 15), (47, 26), (47, 27)):
        m.put(x, y, "~")
    m.put(27, 4, "D")
    m.put(28, 37, "@")
    m.put(10, 25, "c")
    m.put(45, 13, "c")
    m.put(16, 9, "b")
    return m


def boss():
    """Логово Мазохи: большой восьмиугольник, четыре колонны — в них он врезается тараном."""
    m = Map(52, 42)
    m.octagon(3, 4, 48, 38, 8)
    for (x, y) in ((14, 13), (36, 13), (14, 28), (36, 28)):
        m.rect(x, y, x + 1, y + 2, "#")
    m.put(25, 4, "D")
    m.put(26, 35, "@")
    m.put(26, 14, "M")
    m.put(8, 14, "b")
    m.put(43, 14, "b")
    return m


def hub():
    """Квартира Озона: тесная комната 14×8."""
    m = Map(18, 13)
    m.rect(2, 3, 15, 10)
    return m


if __name__ == "__main__":
    for name, fn in (("room1", room1), ("room2", room2), ("room3", room3), ("boss", boss), ("hub", hub)):
        fn().save(name)
        print(name, "ok")
