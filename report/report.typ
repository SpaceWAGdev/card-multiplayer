#set text(font: "Noto Sans Mono")

#text(size: 20pt, [
  = Projektbericht
])

/ Noah Büchold: #link("buechold.noah@gmail.com")
/ Liam Stedman: #link("starlight-caffeine@posteo.org")

#text(size: 14pt, [
#(
  (datetime.today() - duration(weeks: 1)).display("[day].[month].[year]")
) - 
#datetime.today().display("[day].[month].[year]")
])

#line(length: 100%)

#let data = json("commits.json")
#let lines

#(
  for commit in data {
    let dt = (datetime(year: 1970, month: 1, day: 1) + duration(seconds: int(commit.datetime)))
    
    [*#dt.display("[day].[month].[year]")*]

    let col
    if commit.author_email == "starlight-caffeine@posteo.org" {
      col = purple
    }
    else {
      col = red
    }
    
    " " + link(("https://github.com/SpaceWAGdev/card-multiplayer/commit/" + commit.hexsha),commit.hexsha)

    [ \ ]

    text(fill: col, [ #commit.author_email \ ])
    [ #commit.changes.lines veränderte Zeile(n) \ ]
    [ #commit.changes.files veränderte Datei(en) \ ]

    text(commit.commit_message)

    line(length: 100%)
  }
)