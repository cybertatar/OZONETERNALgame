"""Мини-библиотека для пиксель-арта: заливки, автоматическая обводка, листы."""

from PIL import Image


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.img.load()

    def put(self, x, y, c):
        self._px(x, y, c)

    def _px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = hexc(c) if isinstance(c, str) else c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[x, y]
        return (0, 0, 0, 0)

    def rect(self, x0, y0, x1, y1, c):
        """Прямоугольник, края включительно."""
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self._px(x, y, c)

    def clear(self, x, y):
        self._px(x, y, (0, 0, 0, 0))

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (x + 0.5 - cx) / max(rx, 0.01)
                dy = (y + 0.5 - cy) / max(ry, 0.01)
                if dx * dx + dy * dy <= 1.0:
                    self._px(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self._px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def outline(self, c, diagonal=False):
        """Обводка снаружи всех непрозрачных пикселей."""
        col = hexc(c) if isinstance(c, str) else c
        src = self.img.copy().load()
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            nb += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        for y in range(self.h):
            for x in range(self.w):
                if src[x, y][3] != 0:
                    continue
                for dx, dy in nb:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and src[xx, yy][3] != 0 and src[xx, yy] != col:
                        self.px[x, y] = col
                        break

    def flip(self):
        c = Canvas(self.w, self.h)
        c.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        c.px = c.img.load()
        return c


def sheet(frames, cols=None):
    """Склеивает кадры (список строк кадров или плоский список) в лист."""
    rows = frames if isinstance(frames[0], list) else [frames]
    fw, fh = rows[0][0].w, rows[0][0].h
    cols = cols or max(len(r) for r in rows)
    out = Image.new("RGBA", (fw * cols, fh * len(rows)), (0, 0, 0, 0))
    for j, r in enumerate(rows):
        for i, f in enumerate(r):
            out.paste(f.img, (i * fw, j * fh))
    return out


def preview(img, scale, path, bg=(70, 62, 58, 255)):
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    base = Image.new("RGBA", big.size, bg)
    base.alpha_composite(big)
    base.save(path)


class Scaled(Canvas):
    """Холст, на котором рисунок из координат меньшего холста ложится крупнее
    настоящими пикселями (обводка остаётся в 1 px)."""

    def __init__(self, w, h, s):
        super().__init__(round(w * s), round(h * s))
        self.s = s

    def _r(self, v):
        return round(v * self.s)

    def put(self, x, y, c):
        Canvas.rect(self, self._r(x), self._r(y), self._r(x + 1) - 1, self._r(y + 1) - 1, c)

    def rect(self, x0, y0, x1, y1, c):
        x0, x1 = min(x0, x1), max(x0, x1)
        y0, y1 = min(y0, y1), max(y0, y1)
        Canvas.rect(self, self._r(x0), self._r(y0), self._r(x1 + 1) - 1, self._r(y1 + 1) - 1, c)

    def get(self, x, y):
        return Canvas.get(self, self._r(x + 0.5) - 1 if self.s > 1 else x, self._r(y + 0.5) - 1 if self.s > 1 else y)

    def ellipse(self, cx, cy, rx, ry, c):
        Canvas.ellipse(self, cx * self.s, cy * self.s, rx * self.s, ry * self.s, c)

    def line(self, x0, y0, x1, y1, c):
        Canvas.line(self, self._r(x0), self._r(y0), self._r(x1), self._r(y1), c)
