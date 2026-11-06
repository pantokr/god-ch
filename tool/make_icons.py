"""God-Ch 아이콘 생성: G 글자의 가로획이 십자가가 되는 마크 (God's Church).

실행: python tool/make_icons.py
마크 도형은 lib/core/widgets/brand_mark.dart 와 같은 좌표(0~100)를 쓴다.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SS = 4  # 확대해서 그린 뒤 줄여 모서리를 매끄럽게 한다.

# 브랜드 그라데이션 (theme.dart 의 라이트 테마 값)
STOPS = [(0x2F55FF, 0.0), (0x7B2DFF, 0.5), (0xE8199F, 1.0)]


def rgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255)


def gradient(size):
    """왼쪽 위 → 오른쪽 아래 대각선 그라데이션."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            for (c0, t0), (c1, t1) in zip(STOPS, STOPS[1:]):
                if t <= t1:
                    k = (t - t0) / (t1 - t0)
                    a, b = rgb(c0), rgb(c1)
                    px[x, y] = tuple(round(a[i] + (b[i] - a[i]) * k) for i in range(3))
                    break
    return img


# 마크 도형 (0~100 좌표)
CX, CY, R, W = 50.0, 50.0, 26.0, 9.0
BAR_Y = 47.0  # 십자가 가로획 높이
CROSS_TOP, CROSS_BOTTOM, CROSS_LEFT, CROSS_RIGHT = 33.0, 65.0, 39.0, CX + R + W / 2
ARM = 8.0


def mark_layer(size, scale):
    """투명 배경 위에 흰 마크. scale: 마크가 캔버스에서 차지하는 배율 (1 = 100좌표가 캔버스 전체)."""
    big = size * SS
    layer = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(layer)
    u = big / 100 * scale
    off = (big - 100 * u) / 2

    def p(x, y):
        return (off + x * u, off + y * u)

    # G 고리: 가로획 높이에서 시계 방향으로 한 바퀴, 오른쪽 위에 틈
    end = math.degrees(math.asin((BAR_Y - CY) / R))  # 가로획과 만나는 각도
    start_deg, stop_deg = end, -48.0
    ro, ri = R + W / 2, R - W / 2
    ox0, oy0 = p(CX - ro, CY - ro)
    ox1, oy1 = p(CX + ro, CY + ro)
    d.pieslice([ox0, oy0, ox1, oy1], start_deg, stop_deg, fill=255)
    ix0, iy0 = p(CX - ri, CY - ri)
    ix1, iy1 = p(CX + ri, CY + ri)
    d.ellipse([ix0, iy0, ix1, iy1], fill=0)
    for deg in (stop_deg,):  # 위쪽 끝만 둥글게 (아래쪽은 가로획이 덮는다)
        a = math.radians(deg)
        cx, cy = p(CX + R * math.cos(a), CY + R * math.sin(a))
        r = W * u / 2
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    # 십자가: 세로획 + G의 가로획을 겸하는 가로획
    h = ARM * u / 2
    ax, ay = p(CX, CROSS_TOP)
    bx, by = p(CX, CROSS_BOTTOM)
    d.rounded_rectangle([ax - h, ay, bx + h, by], radius=h, fill=255)
    lx, ly = p(CROSS_LEFT, BAR_Y)
    rx, _ = p(CROSS_RIGHT, BAR_Y)
    d.rounded_rectangle([lx, ly - h, rx, ly + h], radius=h, fill=255)
    return layer.resize((size, size), Image.LANCZOS)


def icon(size, scale=0.62, bg=True, rounded=0.0):
    base = gradient(size).convert("RGBA") if bg else Image.new("RGBA", (size, size))
    white = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    base.paste(white, (0, 0), mark_layer(size, scale))
    if rounded:
        m = Image.new("L", (size * SS, size * SS), 0)
        ImageDraw.Draw(m).rounded_rectangle(
            [0, 0, size * SS - 1, size * SS - 1], radius=size * SS * rounded, fill=255
        )
        base.putalpha(m.resize((size, size), Image.LANCZOS))
    return base


def save(img, rel):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("write", rel)


def main():
    web = "web/icons"
    save(icon(192), f"{web}/Icon-192.png")
    save(icon(512), f"{web}/Icon-512.png")
    save(icon(192, 0.5), f"{web}/Icon-maskable-192.png")
    save(icon(512, 0.5), f"{web}/Icon-maskable-512.png")
    save(icon(32, 0.72, rounded=0.22), "web/favicon.png")

    res = "android/app/src/main/res"
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for k, s in legacy.items():
        save(icon(s, 0.62, rounded=0.22), f"{res}/mipmap-{k}/ic_launcher.png")
    for k, s in adaptive.items():
        save(gradient(s).convert("RGB"), f"{res}/mipmap-{k}/ic_launcher_background.png")
        save(icon(s, 0.5, bg=False), f"{res}/mipmap-{k}/ic_launcher_foreground.png")

    # iOS: 투명하지 않은 정사각형 (모서리는 iOS가 깎는다). 파일 이름의 크기 x 배율로 만든다.
    ios = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for f in (ROOT / ios).glob("Icon-App-*.png"):
        name = f.stem.removeprefix("Icon-App-")
        size, scale = name.split("@")
        px = round(float(size.split("x")[0]) * int(scale.removesuffix("x")))
        save(icon(px, 0.62).convert("RGB"), f"{ios}/{f.name}")

    # 미리보기 (저장소 밖)
    save(icon(1024, 0.62, rounded=0.22), "build/icon_preview.png")


if __name__ == "__main__":
    main()
