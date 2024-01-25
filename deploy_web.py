#!/bin/env python3
import bs4

import os

if os.name == "nt":
    os.system("godot.exe --headless --export-release Web ./web-build/cardgame.html")
else:
    os.system("godot --headless --export-release Web ./web-build/cardgame.html")

with open("web-build/cardgame.html", "r") as f:
    txt = f.read()
    soup = bs4.BeautifulSoup(txt, "html.parser")

script_tag = soup.new_tag("script", src="enable-threads.js")
soup.head.append(script_tag)

with open("web-build/cardgame.html", "w") as f:
    f.write(str(soup))
