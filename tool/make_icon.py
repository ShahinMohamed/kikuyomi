"""Draw the Kikuyomi app icon.

A bookmark with a waveform cut out of it: one shape that says both of the things the app does,
rather than a book and a speaker sharing a canvas. The waveform is knocked out of the gold rather
than drawn on top of it, so the mark stays a single silhouette and survives being shrunk to the
48 pixels a launcher actually gives it.

Produces a full-bleed master for iOS and Windows, and a transparent foreground for Android's
adaptive icon, whose mark is smaller because the launcher may crop it to a circle.

Run from the repository root:  python tool/make_icon.py app/icon
Then, from app/:               dart run flutter_launcher_icons
"""

from PIL import Image, ImageDraw

S = 1024
NAVY = (35, 36, 57)      # #232439
GOLD = (241, 180, 65)    # #F1B441


def mark(size, scale=1.0):
    """The bookmark and its waveform, on a transparent canvas.

    Drawn at four times the requested size and scaled down, because the notch and the pill ends are
    diagonals and curves that alias badly at icon sizes otherwise.
    """
    ss = 4
    n = size * ss
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    u = n / 1024 * scale
    cx = n / 2
    cy = n / 2

    half_w = 202 * u
    top = cy - 268 * u
    bottom = cy + 268 * u
    notch = 132 * u

    # The bookmark. Square at the top, a V taken out of the bottom: the corners are the lowest
    # points, which is what makes the shape read as a ribbon rather than as an arrow.
    d.polygon(
        [
            (cx - half_w, top),
            (cx + half_w, top),
            (cx + half_w, bottom),
            (cx, bottom - notch),
            (cx - half_w, bottom),
        ],
        fill=GOLD,
    )

    # The waveform, knocked out so the navy behind shows through. Heights are uneven and the middle
    # bar is tallest, because three bars of one height read as a pause symbol.
    bar_w = 40 * u
    gap = 78 * u
    heights = (186 * u, 268 * u, 144 * u)
    mid_y = cy - 58 * u
    for i, h in enumerate(heights):
        bx = cx + (i - 1) * gap
        d.rounded_rectangle(
            [bx - bar_w / 2, mid_y - h / 2, bx + bar_w / 2, mid_y + h / 2],
            radius=bar_w / 2,
            fill=(0, 0, 0, 0),
        )

    return img.resize((size, size), Image.LANCZOS)


def master():
    img = Image.new("RGBA", (S, S), NAVY + (255,))
    img.alpha_composite(mark(S, 1.0))
    return img.convert("RGB")


if __name__ == "__main__":
    import sys

    out = sys.argv[1] if len(sys.argv) > 1 else "."
    master().save(f"{out}/icon_master.png")
    # Android crops an adaptive icon to whatever shape the launcher likes, so the foreground is the
    # mark alone, drawn smaller to stay inside the safe zone.
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg.alpha_composite(mark(S, 0.60))
    fg.save(f"{out}/icon_foreground.png")
    for px in (128, 48):
        master().resize((px, px), Image.LANCZOS).save(f"{out}/icon_preview_{px}.png")
    print("wrote icon_master.png, icon_foreground.png, previews")
