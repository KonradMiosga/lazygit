#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

#codly(languages: codly-languages)
#codly(display-icon: false)

#let title-page(
  title: [],
  subtitle: [],
  name: [],
  stud-id: [],
  email: [],
  module: [],
  dozent: [],
  semester: [],
  doc,
) = {
  set page(paper: "a4", margin: 2.5cm)
  set text(
    font: "Liberation Sans",
    size: 11pt,
    lang: "de",
  )
  set par(justify: true)
  align(horizon + center)[
    #text(size: 28pt, weight: "bold", title)\
    #v(5em)
    #text(size: 14pt, weight: "bold", subtitle)\
    // #text(size: 14pt, weight: "bold", "Belegarbeit im Studiengang Informatik (B.Sc.)")\
    #v(5em)
    #text(size: 16pt, weight: "bold", module)\
    #text(size: 16pt, weight: "bold", semester)\
    #v(2em)
    #text(size: 14pt, weight: "bold", "Dozent: " + dozent)\
    #v(1em)
    #text(size: 12pt, "Hochschule Zittau/Görlitz")\
    #text(size: 12pt, "Fakultät Elektrotechnik und Informatik")\
  ]
  align(center + bottom)[
    #text(size: 12pt, weight: "bold", "Verfasser: " + name)\
    #text(size: 12pt, weight: "bold", "Matrikelnummer: " + stud-id)\
    #text(size: 12pt, weight: "bold", "E-Mail-Adresse: " + email)\
    #v(5em)
    #text(size: 12pt, "Datum der Abgabe: " + datetime.today().display("[day].[month].[year]"))
  ]
  pagebreak()
  set page(fill: none, margin: 2.6cm)
  set par(leading: 1.2em)
  outline(indent: auto)
  pagebreak()
  show raw.where(block: true): set text(size: 8pt)
  show raw.where(block: true): set par(leading: 0.6em)
  set heading(numbering: "1.")
  show ref: set text(fill: blue)
  show heading: set block(below: 1.5em, above: 1.5em)
  set par(leading: 1.1em, spacing: 2em)
  counter(page).update(1)
  set page(numbering: "1")

  doc
}

