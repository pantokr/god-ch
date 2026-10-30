"""앱 아이콘을 그려서 안드로이드(레거시 · 적응형)와 웹 아이콘 파일로 내보낸다.

도안: 보라 → 분홍 그라데이션 바탕 위에 흰 하트 하나("같이").
실행: python tool/make_icon.py  (Pillow 필요)
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
BRAND = (106, 45, 255)  # AppPalette.light.brand
ACCENT = (232, 25, 159)  # AppPalette.light.accent
SS = 4  # 확대해서 그린 뒤 줄여 가장자리를 매끄럽게 한다.


def gradient(size):
    """왼쪽 위(보라)에서 오른쪽 아래(분홍)로 가는 대각선 그라데이션."""
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(BRAND[i] + (ACCENT[i] - BRAND[i]) * t) for i in range(3))
    return img


def heart_mask(size, scale, dy=0.0):
    """하트 모양 마스크. scale은 하트 너비가 전체의 몇 배인지 (0~1)."""
    big = size * SS
    mask = Image.new('L', (big, big), 0)
    d = ImageDraw.Draw(mask)
    pts = []
    for i in range(720):
        t = 2 * math.pi * i / 720
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((x, y))
    k = big * scale / 32.0  # x 범위가 -16..16
    cx, cy = big / 2, big / 2 + big * dy
    d.polygon([(cx + x * k, cy + y * k) for x, y in pts], fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def foreground(size, scale=0.44):
    """투명 바탕 위의 흰 하트와 옅은 그림자 (적응형 아이콘의 앞면, 안전 영역 안에 둔다)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    m = heart_mask(size, scale, dy=0.01)
    shadow = Image.new('RGBA', (size, size), (60, 10, 120, 0))
    shadow.putalpha(m.point(lambda v: int(v * 0.35)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.015))
    shifted = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shifted.paste(shadow, (0, round(size * 0.012)), shadow)
    img = Image.alpha_composite(img, shifted)
    white = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    white.putalpha(m)
    return Image.alpha_composite(img, white)


def legacy(size):
    """레거시 아이콘: 바탕과 하트를 합친 정사각형 (둥근 모서리는 시스템이 만든다)."""
    bg = gradient(size).convert('RGBA')
    return Image.alpha_composite(bg, foreground(size, 0.52))


def save(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(rel)


# ---- 안드로이드
res = 'android/app/src/main/res'
legacy_px = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
adaptive_px = {k: round(v * 108 / 48) for k, v in legacy_px.items()}  # 108dp 기준
for d, px in legacy_px.items():
    save(legacy(px * 2).resize((px, px), Image.LANCZOS), f'{res}/mipmap-{d}/ic_launcher.png')
for d, px in adaptive_px.items():
    save(gradient(px), f'{res}/mipmap-{d}/ic_launcher_background.png')
    save(foreground(px * 2).resize((px, px), Image.LANCZOS), f'{res}/mipmap-{d}/ic_launcher_foreground.png')

xml_path = os.path.join(ROOT, res, 'mipmap-anydpi-v26', 'ic_launcher.xml')
os.makedirs(os.path.dirname(xml_path), exist_ok=True)
with open(xml_path, 'w', encoding='utf-8') as f:
    f.write(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n'
    )
print('mipmap-anydpi-v26/ic_launcher.xml')

# ---- 웹
for px in (192, 512):
    save(legacy(px), f'web/icons/Icon-{px}.png')
    # 마스크 가능 아이콘: 가장자리까지 바탕이고 하트는 안쪽 80% 안에 둔다.
    bg = gradient(px).convert('RGBA')
    save(Image.alpha_composite(bg, foreground(px, 0.40)), f'web/icons/Icon-maskable-{px}.png')
save(legacy(64).resize((32, 32), Image.LANCZOS), 'web/favicon.png')
