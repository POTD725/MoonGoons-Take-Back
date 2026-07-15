from pathlib import Path

W, H = 720, 760
parts = []
A = parts.append
A(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <linearGradient id="space" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#020712"/><stop offset="0.55" stop-color="#071421"/><stop offset="1" stop-color="#02050b"/></linearGradient>
  <linearGradient id="deck" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#23394b"/><stop offset="1" stop-color="#101b26"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#667f90"/><stop offset="1" stop-color="#263b4a"/></linearGradient>
  <radialGradient id="core"><stop stop-color="#9effff"/><stop offset="0.28" stop-color="#39dfff"/><stop offset="0.7" stop-color="#07537e"/><stop offset="1" stop-color="#031525"/></radialGradient>
  <filter id="shadow" x="-30%" y="-30%" width="160%" height="180%"><feDropShadow dx="0" dy="10" stdDeviation="9" flood-color="#000" flood-opacity=".65"/></filter>
  <filter id="glow"><feGaussianBlur stdDeviation="3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  <pattern id="grid" width="28" height="28" patternUnits="userSpaceOnUse"><path d="M28 0H0V28" fill="none" stroke="#3c7993" stroke-opacity=".12" stroke-width="1"/></pattern>
</defs>''')
A('<rect width="720" height="760" fill="url(#space)"/>')
for i in range(85):
    x = (i * 83 + 31) % 720
    y = (i * 47 + 17) % 420
    r = 0.7 + (i % 3) * 0.35
    opacity = 0.25 + (i % 5) * 0.1
    A(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#c8f5ff" opacity="{opacity:.2f}"/>')
A('<circle cx="626" cy="88" r="54" fill="#12324c" opacity=".8"/><circle cx="608" cy="70" r="45" fill="#1d4f73" opacity=".42"/>')
A('<path d="M610 42c28 8 48 22 65 44" fill="none" stroke="#6cb7df" stroke-opacity=".28" stroke-width="3"/>')
A('<g transform="translate(585 145) scale(.8)" opacity=".85"><path d="M0 16L44 0l26 8-24 10 30 10-21 8-35-9-22 8z" fill="#314d63" stroke="#7ee8ff"/><path d="M18 27h30l18 7-30 6z" fill="#0a2031"/><rect x="51" y="28" width="22" height="4" fill="#39ddff" filter="url(#glow)"/></g>')
A('<path d="M68 260L356 96l296 166v278L360 704 68 540z" fill="#101923" stroke="#5aa4c4" stroke-opacity=".45" stroke-width="3" filter="url(#shadow)"/>')
A('<path d="M84 271L356 117l280 154v255L360 680 84 526z" fill="url(#grid)" opacity=".75"/>')
for offset in [0, 36, 72]:
    A(f'<path d="M118 {484-offset/3}L360 {622-offset/4}L602 {484-offset/3}" fill="none" stroke="#29d9ff" stroke-opacity="{.22-offset*.001}" stroke-width="3"/>')
A('<path d="M360 149v505M111 292l497 287M609 292L111 579" stroke="#5dddf5" stroke-opacity=".12"/>')


def iso_building(cx, cy, width, depth, height, name, accent, kind="facility", level=1):
    x1 = cx - width / 2
    x2 = cx + width / 2
    sy = depth / 2
    top = [(cx, cy - sy - height), (x2, cy - height), (cx, cy + sy - height), (x1, cy - height)]
    left = [(x1, cy - height), (cx, cy + sy - height), (cx, cy + sy), (x1, cy)]
    right = [(x2, cy - height), (cx, cy + sy - height), (cx, cy + sy), (x2, cy)]
    A(f'<g filter="url(#shadow)" data-building="{name}">')
    A(f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in left)}" fill="#132532" stroke="{accent}" stroke-opacity=".55"/>')
    A(f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in right)}" fill="#0a1822" stroke="{accent}" stroke-opacity=".55"/>')
    A(f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in top)}" fill="url(#roof)" stroke="{accent}" stroke-width="2"/>')
    inset = 10
    inner_top = [(cx, cy - sy - height + inset), (x2 - inset, cy - height), (cx, cy + sy - height - inset), (x1 + inset, cy - height)]
    A(f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in inner_top)}" fill="url(#deck)" stroke="{accent}" stroke-opacity=".65"/>')
    for index in range(3):
        light_x = x1 + 14 + index * (width - 28) / 2
        A(f'<rect x="{light_x:.1f}" y="{cy-height+14+index%2*9:.1f}" width="16" height="5" rx="2" fill="{accent}" opacity=".85" filter="url(#glow)"/>')
    if kind == "hq":
        A(f'<ellipse cx="{cx}" cy="{cy-height+4}" rx="34" ry="16" fill="#062a43" stroke="#53e8ff" stroke-width="3"/>')
        A(f'<ellipse cx="{cx}" cy="{cy-height+4}" rx="20" ry="10" fill="url(#core)" filter="url(#glow)"/>')
        for dx, dy in [(-46, -8), (46, -8), (-42, 18), (42, 18)]:
            A(f'<rect x="{cx+dx-12}" y="{cy-height+dy-6}" width="24" height="12" rx="3" fill="#0c3147" stroke="#4de4ff"/>')
    elif kind == "lab":
        for index in range(3):
            A(f'<ellipse cx="{cx-28+index*28}" cy="{cy-height+2+index%2*6}" rx="8" ry="14" fill="#173c32" stroke="#5bffb0" stroke-width="2"/>')
            A(f'<circle cx="{cx-28+index*28}" cy="{cy-height-2+index%2*6}" r="4" fill="#74ffbc" filter="url(#glow)"/>')
    elif kind == "training":
        for index in range(5):
            px = cx - 46 + (index % 3) * 34
            py = cy - height - 2 + (index // 3) * 24
            A(f'<circle cx="{px}" cy="{py}" r="5" fill="#dba15e"/><path d="M{px-5} {py+6}h10l4 14h-18z" fill="#263d4b"/>')
    elif kind == "hospital":
        for index in range(4):
            px = cx - 38 + (index % 2) * 50
            py = cy - height - 4 + (index // 2) * 24
            A(f'<rect x="{px-16}" y="{py-6}" width="32" height="13" rx="4" fill="#1d4351" stroke="#5df5ff"/>')
        A(f'<path d="M{cx-5} {cy-height-26}h10v12h12v10h-12v12h-10v-12h-12v-10h12z" fill="#62f4ff" filter="url(#glow)"/>')
    elif kind == "robotics":
        for index in range(3):
            px = cx - 34 + index * 34
            A(f'<rect x="{px-9}" y="{cy-height-8}" width="18" height="24" rx="5" fill="#2d4557" stroke="#a5d9ef"/>')
            A(f'<circle cx="{px}" cy="{cy-height-1}" r="3" fill="#ffb43f"/>')
            A(f'<path d="M{px-11} {cy-height+10}l-8 12M{px+11} {cy-height+10}l8 12" stroke="#829cad" stroke-width="4"/>')
    elif kind == "armory":
        for index in range(4):
            px = cx - 44 + index * 29
            A(f'<path d="M{px} {cy-height+16}l18-9" stroke="#63cfff" stroke-width="4"/><rect x="{px+11}" y="{cy-height+2}" width="13" height="5" fill="#d7f6ff"/>')
    elif kind == "storage":
        for row in range(2):
            for column in range(3):
                px = cx - 38 + column * 30
                py = cy - height - 8 + row * 22
                A(f'<rect x="{px-11}" y="{py-7}" width="22" height="14" fill="#6a5638" stroke="#d9aa5c"/><path d="M{px-11} {py}h22M{px} {py-7}v14" stroke="#a9824b"/>')
    elif kind == "crime":
        A(f'<circle cx="{cx}" cy="{cy-height+2}" r="18" fill="#2b1245" stroke="#d16cff" stroke-width="3" filter="url(#glow)"/>')
        for index in range(4):
            px = cx - 44 + index * 29
            A(f'<rect x="{px-10}" y="{cy-height+14}" width="20" height="10" rx="2" fill="#31164a" stroke="#b65bff"/>')
    text_width = max(105, min(180, len(name) * 8 + 24))
    A(f'<rect x="{cx-text_width/2}" y="{cy+sy+7}" width="{text_width}" height="34" rx="7" fill="#04101a" fill-opacity=".96" stroke="{accent}" stroke-opacity=".85"/>')
    A(f'<text x="{cx}" y="{cy+sy+21}" fill="#ecfbff" font-size="12" font-family="Arial, sans-serif" font-weight="700" text-anchor="middle">{name}</text>')
    A(f'<text x="{cx}" y="{cy+sy+34}" fill="{accent}" font-size="9" font-family="Arial, sans-serif" text-anchor="middle">LEVEL {level}</text>')
    A('</g>')


iso_building(360, 340, 230, 126, 95, "POLICE HEADQUARTERS", "#ffd65c", "hq", 18)
iso_building(205, 220, 175, 96, 70, "RESEARCH LAB", "#56ffac", "lab", 12)
iso_building(515, 220, 175, 96, 70, "TRAINING CENTER", "#ffb05d", "training", 13)
iso_building(170, 390, 145, 84, 62, "CRIME LAB", "#cf62ff", "crime", 14)
iso_building(550, 390, 145, 84, 62, "HOSPITAL", "#5ef4ff", "hospital", 12)
iso_building(220, 545, 145, 82, 58, "ROBOTICS BAY", "#a7cfff", "robotics", 10)
iso_building(360, 570, 145, 82, 58, "STORAGE DEPOT", "#ffca66", "storage", 15)
iso_building(500, 545, 145, 82, 58, "ARMORY", "#56baff", "armory", 13)

corridors = [((275, 293), (252, 271)), ((445, 293), (468, 271)), ((257, 399), (227, 423)), ((463, 399), (493, 423)), ((310, 467), (261, 505)), ((360, 478), (360, 520)), ((410, 467), (459, 505))]
for (x1, y1), (x2, y2) in corridors:
    A(f'<path d="M{x1} {y1}L{x2} {y2}" stroke="#203848" stroke-width="18" stroke-linecap="round"/><path d="M{x1} {y1}L{x2} {y2}" stroke="#62e8ff" stroke-opacity=".55" stroke-width="3" stroke-linecap="round" filter="url(#glow)"/>')
for index in range(28):
    x = 115 + (index * 73) % 485
    y = 270 + (index * 41) % 280
    A(f'<circle cx="{x}" cy="{y-6}" r="2.8" fill="#bdefff"/><path d="M{x} {y-3}v10m-5 8l5-8 5 8m-8-10l-5 6m8-6l5 6" stroke="#6dc7e5" stroke-width="2" stroke-linecap="round"/>')
A('<g transform="translate(530 620) rotate(-12)" filter="url(#shadow)"><path d="M-74 12L-18-28 48-18 88 5 45 23-20 30z" fill="#263d51" stroke="#8aeaff" stroke-width="2"/><path d="M-45 5L-10-16 38-10 56 0 17 7z" fill="#0a1e2e"/><path d="M-10-16l12-18 32 8 4 16" fill="#37546a" stroke="#8aeaff"/><rect x="54" y="1" width="28" height="6" fill="#4cecff" filter="url(#glow)"/><rect x="-64" y="11" width="18" height="5" fill="#ff5d88" filter="url(#glow)"/></g>')
A('<rect x="28" y="24" width="410" height="58" rx="12" fill="#04111c" fill-opacity=".92" stroke="#5be6ff" stroke-opacity=".6"/>')
A('<text x="48" y="52" fill="#f0fbff" font-size="22" font-family="Arial, sans-serif" font-weight="800">MOONGOONS TAKE BACK</text>')
A('<text x="48" y="71" fill="#75e8ff" font-size="11" font-family="Arial, sans-serif">ORBITAL PEACEKEEPER STATION // DECK 07</text>')
A('<g transform="translate(525 28)"><rect width="165" height="50" rx="10" fill="#071827" stroke="#56efbd"/><circle cx="22" cy="25" r="7" fill="#56efbd" filter="url(#glow)"/><text x="38" y="23" fill="#dffef4" font-size="12" font-family="Arial" font-weight="700">STATION ONLINE</text><text x="38" y="39" fill="#84bdd0" font-size="9" font-family="Arial">HULL 100% · O₂ 100%</text></g>')
A('<ellipse cx="360" cy="340" rx="138" ry="85" fill="none" stroke="#ffd65c" stroke-width="3" stroke-dasharray="8 8" opacity=".7"/>')
A('<text x="360" y="728" fill="#9eefff" font-size="11" font-family="Arial" text-anchor="middle">TOUCH A FACILITY TO OPEN REPAIR, UPGRADE, STAFF, EQUIPMENT, AND ADD-ON OPTIONS</text>')
A('</svg>')
output = Path("assets/generated/approved_station_deck.svg")
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("".join(parts), encoding="utf-8")
print(f"Generated {output} ({output.stat().st_size} bytes)")
