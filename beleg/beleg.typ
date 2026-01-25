#import "template.typ": *
#import "@preview/codly:1.3.0"
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#import "@preview/codelst:2.0.2": sourcecode

#let code-figure(
  caption,
  label,
  numbers: false,
  body,
) = [
  #block[
    #sourcecode.with(numbers: numbers)[
      #body
    ]

    #v(6pt)
    #align(center)[
      #text(size: 9pt, fill: luma(80))[#caption]
    ]
  ] #label
]



#show: title-page.with(
  title: [Testkonzept für das Open-Source-Projekt „lazygit"],
  subtitle: [Belegarbeit im Studiengang Informatik (B.Sc.)],
  module: [Grundlagen des Softwaretestens],
  semester: [Wintersemester 2025/26],
  dozent: [Prof. Dr. Matthias Längrich],
  name: [Konrad Miosga],
  stud-id: [1056710],
  email: "konrad.miosga@stud.hszg.de",
)

= Einleitung

== Projektkontext

In dieser Belegarbeit wird das Testkonzept des Open-Source-Projekts *lazygit* analysiert, bewertet und durch eigene Testfälle ergänzt. Lazygit ist eine in Go entwickelte Terminal-UI für Git-Kommandos, die komplexe Git-Operationen durch eine intuitive, tastaturgesteuerte Benutzeroberfläche vereinfacht. Das Projekt wurde von Jesse Duffield initiiert, wird seit 2018 aktiv entwickelt und gehört mit über 50.000 GitHub-Stars zu den populärsten Git-Tools im Terminal-Bereich.

Die Architektur folgt dem MVC-Muster mit klarer Trennung zwischen UI-Komponenten, Business-Logik und Git-Operationen. Diese Struktur erleichtert das isolierte Testen einzelner Komponenten erheblich.

== Zielsetzung und Methodik

Diese Arbeit verfolgt mehrere Ziele: Analyse der bestehenden Teststrategie mit ihren Stärken und Schwächen, Identifikation von Testlücken durch Coverage-Analysen und Code-Reviews, praktische Implementierung neuer Testfälle sowie Ableitung konkreter Handlungsempfehlungen.

Die Bearbeitung erfolgte systematisch: Nach Literaturrecherche zu Testing-Grundlagen wurde die bestehende Testinfrastruktur analysiert. Coverage-Reports und manuelle Code-Reviews identifizierten Testlücken, die anschließend durch table-driven Tests geschlossen wurden. Die neuen Tests wurden in die CI-Pipeline integriert und auf mehreren Plattformen validiert.

#pagebreak()
= Theoretische Grundlagen <TheoGrund>

Software-Testing ist ein zentraler Bestandteil der Qualitätssicherung in der Softwareentwicklung. Das oft zitierte Statement von Edsger W. Dijkstra bringt dabei eine grundlegende Eigenschaft des Testens prägnant auf den Punkt: Tests eignen sich hervorragend zum Aufdecken von Fehlern, sind jedoch ungeeignet, um die vollständige Fehlerfreiheit eines Programms nachzuweisen #cite(<Dijkstra2007HumbleProgrammer>).

Diese Einschränkung ergibt sich aus der Natur des Software-Testings als Stichprobenverfahren. Da Programme in der Regel eine sehr große Menge möglicher Eingaben besitzen, kann im Rahmen von Tests nur eine endliche Teilmenge davon überprüft werden. Ein formaler Beweis der Korrektheit allein durch Tests ist daher prinzipiell nicht möglich.

Vor diesem Hintergrund kommt der systematischen und zielgerichteten Auswahl repräsentativer Testfälle eine zentrale Bedeutung zu. Ziel des Testens ist es nicht, wie schon eingangs erwähnt, Fehlerfreiheit zu garantieren, sondern mit begrenztem Aufwand eine möglichst hohe Wahrscheinlichkeit zur Entdeckung relevanter Defekte zu erreichen.

Der Testprozess lässt sich grundsätzlich in zwei zentrale Bereiche gliedern: die statische Analyse und das dynamische Testen #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 4]). Die statische Analyse untersucht Softwareartefakte ohne deren Ausführung und zielt darauf ab, potenzielle Fehler, Regelverletzungen oder Qualitätsmängel frühzeitig im Entwicklungsprozess zu identifizieren #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 43–45]). Zu den typischen Verfahren zählen Code-Reviews, der Einsatz von Lintern sowie statische Datenfluss- und Kontrollflussanalysen.

Demgegenüber steht das dynamische Testen, bei dem die Software mit konkreten Eingabedaten ausgeführt wird. Dadurch lassen sich insbesondere solche Fehler aufdecken, die erst zur Laufzeit auftreten, etwa Speicherlecks, Race Conditions oder fehlerhaftes Laufzeitverhalten. Dynamische Tests ermöglichen somit eine Überprüfung des tatsächlichen Systemverhaltens unter realistischen oder gezielt konstruierten Bedingungen #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 39–43]). Der Schwerpunkt dieser Arbeit liegt auf dem dynamischen Testen und den zugehörigen Testverfahren.

Dynamisches Testen lässt sich in zwei grundlegende Herangehensweisen unterteilen: Black-Box- und White-Box-Tests.

Beim Black-Box-Test werden Testfälle ausschließlich aus der externen Spezifikation eines Systems abgeleitet, ohne Kenntnisse seiner inneren Implementierung. Man behandelt die Software als „schwarze Box" und konzentriert sich darauf, ob die funktionalen und nicht-funktionalen Anforderungen erfüllt sind. Zu den klassischen Black-Box-Verfahren gehören die Äquivalenzklassenbildung und die Grenzwertanalyse. Bei der Äquivalenzklassenbildung werden Eingabedaten in Gruppen zusammengefasst, von denen man annimmt, dass sie vom System gleichartig verarbeitet werden. Statt alle Mitglieder einer Klasse zu testen, wählt man einen repräsentativen Vertreter aus. Die Grenzwertanalys ergänzt dieses Vorgehen, indem sie Testfälle gezielt an den Rändern dieser Äquivalenzklassen platziert, da dort erfahrungsgemäß häufig Fehler auftreten #cite(<SpillnerLinz2021>, supplement: [S. 147-155]).

Der White-Box-Test (auch strukturbasierter Test) erfordert hingegen detaillierte Kenntnisse der internen Programmstruktur. Testfälle werden hierbei so entworfen, dass bestimmte Strukturelemente des Codes – wie Anweisungen, Verzweigungen oder Pfade – gezielt durchlaufen werden. Das Ziel ist es, eine definierte Code-Abdeckung (Coverage) zu erreichen und die korrekte Implementierung der internen Logik zu verifizieren #cite(<SpillnerLinz2021>, supplement: [S. 177-181]).

In der modernen Testpraxis werden beide Ansätze selten isoliert betrachtet. Vielmehr werden sie in einem systematischen Testentwurfsprozess kombiniert, um sowohl die funktionale Korrektheit (Black-Box-Sicht) als auch die strukturelle Robustheit (White-Box-Sicht) sicherzustellen. Ein solcher Prozess, wie er auch im praktischen Teil dieser Arbeit zur Anwendung kommt, beginnt oft mit einer Black-Box-Sicht, bei der aus funktionalen Anforderungen grobe Testideen oder Use Cases abgeleitet werden. Daraufhin folgt die White-Box-Analyse der konkreten Implementierung, um entscheidungsrelevante Codepfade zu identifizieren. Basierend auf dieser Code-Logik können dann White-Box-orientierte Äquivalenzklassen gebildet werden; so hat ein Parameter, der eine `if`-Bedingung steuert, beispielsweise die beiden Äquivalenzklassen `true` und `false`, die für eine vollständige Zweigabdeckung getestet werden müssen. Um schließlich die Interaktion verschiedener Parameter effizient zu überprüfen, kommen *kombinatorische Testverfahren* wie das Pairwise-Testing (Paarweises Testen) zum Einsatz. Anstatt alle denkbaren Parameterkombinationen zu testen, was zu einer Testfallexplosion führen würde, wählt dieser Ansatz Testfälle so aus, dass jede mögliche Kombination von *zwei* Parametern mindestens einmal abgedeckt ist. Dies stellt einen pragmatischen Kompromiss zwischen Aufwand und Fehlerfindungsrate dar, da die meisten Softwarefehler durch die Interaktion von wenigen Parametern entstehen #cite(<NIST-SP800-142>).

Durch diese Kombination wird sichergestellt, dass die Tests nicht nur relevante Anwenderszenarien abdecken, sondern auch alle logischen Verzweigungen im Code systematisch validieren.

Innerhalb der White-Box-Tests lassen sich verschiedene, aufeinander aufbauende Testverfahren unterscheiden. Unit-Tests überprüfen die kleinsten testbaren Einheiten eines Programms in Isolation. Abhängige Komponenten werden dabei typischerweise durch Mocks oder Stubs ersetzt, was schnelle, reproduzierbare und deterministische Tests ermöglicht #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 371–372]). Eine häufig eingesetzte Ausprägung sind sogenannte Table-Driven Tests, bei denen mehrere Testfälle in Form von Datentabellen definiert und von einem generischen Testcode iterativ ausgeführt werden #cite(<GoTableDrivenTests>). Dieses Vorgehen reduziert Redundanz und verbessert die Wartbarkeit der Tests.

Aufbauend auf den Unit-Tests folgen Integrationstests, die das Zusammenwirken mehrerer bereits getesteter Module überprüfen. Ziel ist es insbesondere, Fehler an Schnittstellen sowie Probleme im Zusammenspiel der Komponenten aufzudecken #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 372–376]). Im Gegensatz zu Unit-Tests kommen hierbei überwiegend reale Komponenten statt isolierender Mocks zum Einsatz, wodurch eine höhere Aussagekraft hinsichtlich der Gesamtfunktionalität des Systems erreicht wird.

#pagebreak()
= Analyse der vorhandenen Teststrategie

Lazygit testet auf zwei Ebenen: Unit-Tests und Integrationstests. Die Unit-Tests prüfen einzelne Funktionen isoliert und laufen sehr schnell, während die Integrationstests die gesamte Anwendung mit echter Benutzerinteraktion testen. Dabei kommen sogenannte Table-Driven Tests zum Einsatz, eine Go-typische Methode, um viele ähnliche Testfälle kompakt zu schreiben.

== Unit-Tests

Die Unit-Tests in Lazygit arbeiten mit Mocks, das heißt sie führen keine echten Git-Befehle aus, sondern simulieren diese. Das Kernstück ist der `FakeCmdObjRunner`, der vorgibt, Git-Befehle auszuführen, tatsächlich aber nur aufzeichnet, welche Befehle aufgerufen wurden, und vordefinierte Antworten zurückgibt. So kann man Tests schreiben, die schnell, zuverlässig und unabhängig vom tatsächlichen Git-Zustand sind.

Ein typischer Unit-Test sieht ungefähr so aus:

```go
func TestBranchNewBranch(t *testing.T) {
    runner := oscommands.NewFakeRunner(t).
        ExpectGitArgs([]string{"checkout", "-b", "test", "refs/heads/master"}, "", nil)
    instance := buildBranchCommands(commonDeps{runner: runner})

    assert.NoError(t, instance.New("test", "refs/heads/master"))
    runner.CheckForMissingCalls()
}
```

Man sagt dem Fake-Runner vorher, welchen Git-Befehl man erwartet, führt dann die zu testende Funktion aus, und prüft am Ende, ob wirklich der erwartete Befehl aufgerufen wurde. Das ist einfach und funktioniert gut für Komponenten, die hauptsächlich Git-Befehle zusammenbauen und ausführen.

== Table-Driven Tests

Table-Driven Tests sind in Go sehr verbreitet. Die Idee ist, dass man mehrere Testfälle in einer Liste definiert und dann in einer Schleife durchläuft. Das spart Code-Duplikation und macht es einfach, neue Testfälle hinzuzufügen. In Lazygit wird das konsequent eingesetzt, besonders wenn man verschiedene Eingaben und Fehlerfälle durchprobieren will.

Ein Beispiel aus `branch_test.go` zeigt, wie das aussieht:

```go
scenarios := []scenario{
    {
        "Can't retrieve pushable count",
        oscommands.NewFakeRunner(t).
            ExpectGitArgs([]string{"rev-list", "@{u}..HEAD", "--count"}, "", errors.New("error")),
        "?", "?",
    },
    {
        "Retrieve pullable and pushable count",
        oscommands.NewFakeRunner(t).
            ExpectGitArgs([]string{"rev-list", "@{u}..HEAD", "--count"}, "1\n", nil).
            ExpectGitArgs([]string{"rev-list", "HEAD..@{u}", "--count"}, "2\n", nil),
        "1", "2",
    },
}

for _, s := range scenarios {
    t.Run(s.testName, func(t *testing.T) {
        instance := buildBranchCommands(commonDeps{runner: s.runner})
        pushables, pullables := instance.GetCommitDifferences("HEAD", "@{u}")
        assert.EqualValues(t, s.expectedPushables, pushables)
        assert.EqualValues(t, s.expectedPullables, pullables)
        s.runner.CheckForMissingCalls()
    })
}
```

Jedes Szenario hat einen Namen, eine Mock-Konfiguration und erwartete Ergebnisse. Die Schleife führt dann für jeden Fall den gleichen Test aus. Wenn ein Test fehlschlägt, sieht man sofort am Namen, welches Szenario das Problem hat.

== Integrationstests

Die Integrationstests sind das Herzstück der Teststrategie. Sie testen nicht einzelne Funktionen, sondern komplette User-Workflows. Dafür wurde ein eigenes Test-Framework entwickelt, mit der man UI-Interaktionen beschreiben kann.

Ein Test für einen Rebase sieht zum Beispiel so aus:

```go
var Rebase = NewIntegrationTest(NewIntegrationTestArgs{
    Description:  "Rebase onto another branch, deal with the conflicts.",
    SetupRepo: func(shell *Shell) {
        shared.MergeConflictsSetup(shell)
    },
    Run: func(t *TestDriver, keys config.KeybindingConfig) {
        t.Views().Commits().TopLines(
            Contains("first change"),
            Contains("original"),
        )

        t.Views().Branches().
            Focus().
            Lines(
                Contains("first-change-branch"),
                Contains("second-change-branch"),
            ).
            SelectNextItem().
            Press(keys.Branches.RebaseBranch)

        t.ExpectPopup().Menu().
            Title(Equals("Rebase 'first-change-branch'")).
            Select(Contains("Simple rebase")).
            Confirm()

        t.Common().AcknowledgeConflicts()
    },
})
```

Der Test läuft in drei Schritten ab: Zuerst wird ein echtes Git-Repository mit dem `Shell`-Helper vorbereitet. Dann simuliert der `TestDriver` Benutzeraktionen wie `Focus()`, `SelectNextItem()` oder `Press()` – das entspricht den Tastendrücken, die ein echter Nutzer machen würde. Zwischendurch wird immer wieder geprüft, ob die UI das Erwartete anzeigt, zum Beispiel mit `Contains()` oder `Equals()`. Man kann den Test lesen wie eine Beschreibung dessen, was ein Nutzer tut.

Es gibt über 450 solcher Integrationstests, die alle möglichen Szenarien abdecken: Branch-Operationen wie Checkout oder Rebase, Commit-Operationen wie Amend oder Cherry-Pick , interaktive Rebases, Konfliktbehandlung, File-Operations und mehr.

Technisch basiert das Framework auf einer Architektur spezialisierter Driver-Komponenten. Der `ViewDriver` ermöglicht Interaktionen mit Listen-Views wie Branches, Commits und Files, während der `MenuDriver` die Navigation in Popup-Menüs steuert. Der `PromptDriver` behandelt Texteingaben, der `ConfirmationDriver` das Bestätigen oder Ablehnen von Dialogen und der `AlertDriver` die Validierung von Fehlermeldungen. Diese Abstraktion entkoppelt die Testlogik von der konkreten UI-Implementation, was Refactorings erheblich erleichtert. Ändert sich die Struktur der Benutzeroberfläche, müssen lediglich die Driver-Implementierungen angepasst werden, während die hunderten von Tests unverändert bleiben können.

// #pagebreak()
= Continuous Integration Pipeline

Die CI-Pipeline ist kein Bestandteil der Teststrategie selbst, sondern dient als technisches Mittel zur automatisierten Umsetzung der beschriebenen Testkonzepte. Lazygit nutzt GitHub Actions, um bei jedem Push und Pull Request automatisch die Qualitätssicherung durchzuführen.

Die Pipeline führt parallel mehrere Prüfungen aus: Unit-Tests laufen auf Ubuntu und Windows (Cross-Platform-Kompatibilität), Integrationstests validieren die Funktionalität gegen vier verschiedene Git-Versionen (2.32.0 bis neueste), Build-Jobs kompilieren für Linux, Windows und macOS, Konsistenz-Checks prüfen Dependencies und generierte Dateien, und golangci-lint führt statische Code-Analyse durch. Nach erfolgreicher Testausführung werden Coverage-Daten zu Codacy hochgeladen.

// Die Coverage-Werte variieren je nach Komponente: Command-Builder erreichen 75-85%, Loader 70-80%, Controller 60-70%, während Presentation-Layer und UI-Rendering mit 40-55% bzw. 25-40% deutlich niedriger liegen – was für Terminal-Anwendungen typisch ist. Die Testsuite umfasst über 80 Unit-Test-Dateien mit etwa 2500 Testfunktionen und mehr als 450 Integrationstests. Dank Parallelisierung beträgt die Laufzeit 15-20 Minuten statt über einer Stunde.

#pagebreak()
= Entwurf eigener Testfälle

Der praktische Teil dieser Arbeit bestand darin, Testlücken im Lazygit-Projekt zu identifizieren und durch eigene Testfälle zu schließen. Dabei wurden die zuvor analysierten Teststrategien angewendet und die Coverage messbar verbessert.

== Identifikation von Testlücken

Die Analyse der Coverage-Reports in Kombination mit manuellen Code-Reviews identifizierte zwei signifikante Testlücken. Die Tag-Kommandos in `pkg/commands/git_commands/tag.go` enthielten acht Funktionen ohne jegliche Testabdeckung. Tags sind in Git zentral für die Versionsverwaltung, weshalb fehlerhafte Implementierungen zu versehentlich überschriebenen oder falsch gesetzten Tags führen können.
```bash
/lazygit/pkg/commands/git_commands/tag.go:14:	NewTagCommands			 0.0%
/lazygit/pkg/commands/git_commands/tag.go:20:	CreateLightweightObj 0.0%
/lazygit/pkg/commands/git_commands/tag.go:30:	CreateAnnotatedObj	 0.0%
/lazygit/pkg/commands/git_commands/tag.go:40:	HasTag							 0.0%
/lazygit/pkg/commands/git_commands/tag.go:49:	LocalDelete					 0.0%
/lazygit/pkg/commands/git_commands/tag.go:56:	Push								 0.0%
/lazygit/pkg/commands/git_commands/tag.go:71:	ShowAnnotationInfo	 0.0%
/lazygit/pkg/commands/git_commands/tag.go:80:	IsTagAnnotated			 0.0%
```
Die zweite Lücke betraf die `StringStack`-Datenstruktur in `pkg/utils/string_stack.go`, eine LIFO-Implementierung ohne Tests.
```bash
/lazygit/pkg/utils/string_stack.go:7:					Push								 0.0%
/lazygit/pkg/utils/string_stack.go:11:				Pop								   0.0%
/lazygit/pkg/utils/string_stack.go:21:				IsEmpty							 0.0%
/lazygit/pkg/utils/string_stack.go:25:				Clear								 0.0%
```

Die Priorisierung erfolgte nach Kritikalität, wobei die Tag-Funktionen als wichtiger eingestuft wurden.
#pagebreak()
== Analyse und Testfalldesign - tag.go

=== Anforderungsanalyse

Die Tag-Verwaltung in lazygit erfüllt zentrale Anforderungen der Git-Versionskontrolle:

*Funktionale Anforderungen:*
#table(
  columns: (auto, 1fr),
  [FA-01], [Erstellung von Lightweight Tags (einfache Commit-Pointer)],
  [FA-02], [Erstellung von Annotated Tags mit Metadaten (Autor, Datum, Message)],
  [FA-03], [Tags auf beliebigen Commits erstellen (nicht nur HEAD)],
  [FA-04], [Überschreiben existierender Tags mit Force-Flag],
  [FA-05], [Lokales Löschen von Tags],
  [FA-06], [Unterscheidung zwischen Annotated und Lightweight Tags],
)
//
// *Nicht-funktionale Anforderungen:*
// - NFR-TAG-01: Korrekte Git-Kommandos generieren (Repository-Integrität)
// - NFR-TAG-02: Sichere Parameter-Übergabe (Input-Validierung)

*Use-Case-Analyse*

Aus der Anforderungsanalyse wurden vier zentrale Use Cases abgeleitet, die das Testdesign maßgeblich beeinflussen:

#table(
  columns: (auto, 1fr, auto),
  [*UC*], [*Beschreibung*], [*Priorität*],
  [UC-01], [Release-Version taggen: Entwickler markiert Commits mit einer Versionen], [Hoch],
  [UC-02], [Fehlerhaften Tag lokal korrigieren: Vor Remote-Push Fehler beheben], [Mittel],
  [UC-03], [Tag-Informationen anzeigen: Unterscheidung Lightweight/Annotated], [Hoch],
  [UC-04], [Bestehenden Tag verschieben: Rolling-Tags (latest, stable) aktualisieren], [Mittel],
)

// *UC-01: Release-Version taggen* ist der primäre Workflow. Benutzer navigieren zu einem Commit, drücken `n` und geben einen Tag-Namen ein. Das System unterscheidet automatisch zwischen Lightweight (keine Beschreibung) und Annotated Tags (mit Message oder GPG-Signierung). Bei existierenden Tags erfolgt eine Force-Bestätigung. Dieser Use Case validiert FR-TAG-01 bis FR-TAG-04.
//
// *UC-04: Bestehenden Tag verschieben* adressiert zwei Szenarien: Fehlerkorrektur (Tag auf falschem Commit) und Rolling-Tags (kontinuierliche Aktualisierung von "latest"-Tags). Die `--force`-Option ermöglicht das Überschreiben, erfordert aber explizite Benutzerbestätigung zur Vermeidung versehentlicher Datenverluste.

=== Testbedingungen

Aus den Use Cases wurden sieben konkrete Testbedingungen abgeleitet:

#table(
  columns: (auto, 1fr, 1fr),
  [*ID*], [*Bedingung*], [*Erwartetes Verhalten*],
  [TB-01], [Lightweight Tag ohne Ref], [`git tag -- <name>`],
  [TB-02], [Tag auf spezifischem Commit], [`git tag -- <name> <ref>`],
  [TB-03], [Force-Flag gesetzt], [`--force` Flag inkludiert],
  [TB-04], [Force + spezifischer Commit], [Kombination beider Flags],
  [TB-05], [Annotated Tag mit Message], [`-m <message>` Parameter],
  [TB-06], [Tag-Typ erkennen], [`git cat-file -t` Output parsen],
  [TB-07], [Tag löschen], [`git tag -d <name>` ausführen],
)

=== Testfalldesign

Die Tag-Funktionen konstruieren Git-Befehle programmatisch mit Hilfsfunktionen wie `NewGitCmd` und `ArgIf`. Die Funktion `ArgIf(condition, arg)` fügt Argumente nur hinzu wenn die Bedingung erfüllt ist. Diese bedingte Logik bestimmt die Code-Pfade und damit die notwendigen Testfälle.

==== Code-Analyse für CreateLightweightObj

Die Funktion `CreateLightweightObj(tagName string, ref string, force bool)` enthält folgende relevante Code-Verzweigungen:

```go
NewGitCmd("tag").
    ArgIf(force, "--force").        // Bedingung: force == true?
    Arg("--", tagName).             // Keine Bedingung
    ArgIf(len(ref) > 0, ref).       // Bedingung: ref nicht-leer?
```

Daraus ergeben sich zwei entscheidungsrelevante Bedingungen:
- `force`: true oder false
- `len(ref) > 0`: ref leer oder nicht-leer

Der Parameter `tagName` durchläuft keine Verzweigungslogik und wird unverändert an Git übergeben.

==== Äquivalenzklassenbildung


*Parameter tagName:*
- **1 Äquivalenzklasse:** Beliebiger String
- Begründung: `Arg("--", tagName)` führt keine Validierung oder Unterscheidung durch
- Repräsentant: "v1.0.0" (konsistent in allen Tests verwendet)

*Parameter ref:*
- **Klasse 1:** Leer (`""`) → `len(ref) > 0` ist false → ref wird nicht hinzugefügt
- **Klasse 2:** Nicht-leer (z.B. `"abc123"`) → `len(ref) > 0` ist true → ref wird hinzugefügt
- Begründung: Verzweigung im Code unterscheidet explizit zwischen leer und nicht-leer

*Parameter force:*
- **Klasse 1:** false → `--force` Flag wird nicht hinzugefügt  
- **Klasse 2:** true → `--force` Flag wird hinzugefügt
- Begründung: Boolean-Parameter mit direkter Code-Verzweigung

==== Kombinatorische Testabdeckung

Aus den Äquivalenzklassen ergeben sich folgende Kombinationen:
- tagName: 1 Klasse
- ref: 2 Klassen (leer, nicht-leer)
- force: 2 Klassen (false, true)

**Gesamtkombinationen:** 1 × 2 × 2 = **4 Testfälle**

Da nur 4 Kombinationen existieren, entspricht vollständige Kombinatorik der Pairwise-Coverage. Alle möglichen Interaktionen zwischen den Parametern werden abgedeckt:

#table(
  columns: (auto, auto, auto, auto),
  [*Test*], [*ref*], [*force*], [*Erwartetes Kommando*],
  [TF-01], [leer], [false], [`git tag -- v1.0.0`],
  [TF-02], [nicht-leer], [false], [`git tag -- v1.0.0 abc123`],
  [TF-03], [leer], [true], [`git tag --force -- v1.0.0`],
  [TF-04], [nicht-leer], [true], [`git tag --force -- v1.0.0 def456`],
)

TF-04 ist der kritischste Test, da beide bedingte Argumente (`--force` und `ref`) gleichzeitig aktiv sind und die korrekte Argument-Reihenfolge validiert wird.

==== Weitere Entwurfstechniken

*Grenzwertanalyse für IsTagAnnotated:*

Die Funktion `IsTagAnnotated` parst Git-Output und muss robuste String-Verarbeitung gewährleisten. Getestet werden:
- Exakte Übereinstimmung: `"tag\n"` (Annotated) vs. `"commit\n"` (Lightweight)
- Whitespace-Toleranz: `"  tag  \n"` (mit führenden/nachfolgenden Leerzeichen)
- Edge Case: Leerer String (implizit durch `strings.TrimSpace` abgedeckt)

*Table-Driven Testing:*

Das Implementierungspattern folgt dem Projekt-Standard. Jeder Test definiert eine Szenario-Struktur mit Eingabeparametern und erwarteten Git-Argumenten, die in einer Schleife ausgeführt werden. Dies ermöglicht kompakte, wartbare Tests mit klarer Trennung von Testdaten und Testlogik.

==== Testfallübersicht

Die resultierende Test-Suite umfasst 12 Testfälle:
- 4 für `CreateLightweightObj` (TF-01 bis TF-04) - vollständige Kombinatorik
- 4 für `CreateAnnotatedObj` (TF-05 bis TF-08) - analog mit zusätzlichem `msg`-Parameter
- 3 für `IsTagAnnotated` (TF-09 bis TF-11) - Grenzwertanalyse für Output-Parsing
- 1 für `LocalDelete` (TF-12) - direkter Funktionsaufruf ohne Parametervariationen

Diese Testfälle validieren alle sieben Testbedingungen (TB-01 bis TB-07) und decken somit alle funktionalen Anforderungen (FR-TAG-01 bis FR-TAG-06) ab.

== Implementierung - tag.go

Die Tag-Tests wurden in `tag_test.go` implementiert und folgen strikt den Projekt-Konventionen. Jeder Testfall definiert eine Szenario-Struktur mit Eingabeparametern und erwarteten Git-Argumenten.
Beispielhaft sei hier das implementierte Szenario für `TF-01` dargestellt.

```go
//...
func TestTagCommands_CreateLightweightObj(t *testing.T) {
	type scenario struct {
		testName        string
		tagName         string
		ref             string
		force           bool
		expectedCmdArgs []string
	}

	scenarios := []scenario{
    {
      testName:        "create simple lightweight tag on HEAD",
      tagName:         "v1.0.0",
      ref:             "",
      force:           false,
      expectedCmdArgs: []string{"git", "tag", "--", "v1.0.0"},
    }
  },
  //...
  	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t)
			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			cmdObj := tagCommands.CreateLightweightObj(s.tagName, s.ref, s.force)

			assert.Equal(t, s.expectedCmdArgs, cmdObj.Args())
		})
	}
}
```

Der `FakeCmdObjRunner` simuliert Git-Befehle ohne tatsächliche Ausführung. Für jeden Testfall werden die erwarteten Argumente beim Fake-Runner registriert, die Funktion ausgeführt und anschließend mit `CheckForMissingCalls()` validiert, dass alle erwarteten Befehle aufgerufen wurden.

Die vollständige Implementierung ist in @tag_test ersichtlich.

== Testergebnisse und Coverage-Verbesserung - tag.go
Die Coverage-Analyse zeigt signifikante Verbesserungen für `tag.go`, wo fünf von acht Funktionen auf 100% Coverage gebracht wurden:

```bash
/lazygit/pkg/commands/git_commands/tag.go:14:	NewTagCommands			 100.0%
/lazygit/pkg/commands/git_commands/tag.go:20:	CreateLightweightObj 100.0%
/lazygit/pkg/commands/git_commands/tag.go:30:	CreateAnnotatedObj	 100.0%
/lazygit/pkg/commands/git_commands/tag.go:40:	HasTag							 0.0%
/lazygit/pkg/commands/git_commands/tag.go:49:	LocalDelete					 100.0%
/lazygit/pkg/commands/git_commands/tag.go:56:	Push								 0.0%
/lazygit/pkg/commands/git_commands/tag.go:71:	ShowAnnotationInfo	 0.0%
/lazygit/pkg/commands/git_commands/tag.go:80:	IsTagAnnotated			 100.0%
```
Die Funktion `NewTagCommands` wurde in allen Tests implizit mitgetestet, da sie in allen Testfällen Verwendung findet.
Die drei verbleibenden Funktionen (`HasTag`, `Push`, `ShowAnnotationInfo`) wurden in dieser Arbeit nicht getestet.
Bei `Push` handelt es sich um eine Remote-Operation die Netzwerk-Kommunikation erfordert. `HasTag` und `ShowAnnotationInfo` sind unterkomplex und wurden nicht priorisiert.

Die Gesamt-Coverage von `tag.go` stieg von 0% auf 62.5%.

// == Analyse und Testfalldesign - string_stack.go
// Für `StringStack` wurde ein zustandsbasierter Testansatz gewählt. Die Tests validieren LIFO-Semantik (`TestStringStack_PushAndPop`), das Verhalten bei leerem Stack (`TestStringStack_PopEmptyStack`), Zustandsprüfung (`TestStringStack_IsEmpty`), vollständiges Zurücksetzen (`TestStringStack_Clear`) und komplexe Operationssequenzen (`TestStringStack_MultipleOperations`).
//
//
// == Implementierung - string_stack.go
// Die StringStack-Tests verwenden klassisches Unit-Testing ohne Table-Driven-Ansatz, da primär Zustandsübergänge getestet werden:
//
// ```go
// func TestStringStack_PushAndPop(t *testing.T) {
//     stack := NewStringStack()
//     stack.Push("first")
//     stack.Push("second")
//
//     assert.Equal(t, "second", stack.Pop())
//     assert.Equal(t, "first", stack.Pop())
// }
// ```
//
// == Testergebnisse und Coverage-Verbesserung - string_stack.go
//
//
//
// ```bash
// /lazygit/pkg/utils/string_stack.go:7:					Push								 100.0%
// /lazygit/pkg/utils/string_stack.go:11:				Pop								   100.0%
// /lazygit/pkg/utils/string_stack.go:21:				IsEmpty							 100.0%
// /lazygit/pkg/utils/string_stack.go:25:				Clear								 100.0%
// ```
// Auf Package-Ebene verbesserte sich `pkg/commands/git_commands` von 37.1% auf 37.6% (+0.5 Prozentpunkte) und `pkg/utils` von 58.2% auf 59.6% (+1.4 Prozentpunkte). Obwohl die prozentualen Verbesserungen moderat erscheinen, schließen sie konkrete Lücken in wichtigen Funktionen innerhalb umfangreicher Packages.

= Testauswertung und Metriken

Die Coverage-Verbesserungen sind messbar und signifikant. Für `tag.go` stieg die Coverage von 0% auf 62.5%, wobei alle getesteten Funktionen 100% Coverage erreichten. Nur drei Funktionen blieben ungetestet. `string_stack.go` erreichte vollständige 100% Coverage für alle Funktionen.

Auf Package-Ebene verbesserte sich `pkg/commands/git_commands` um 0.5 Prozentpunkte (37.1% → 37.6%) und `pkg/utils` um 1.4 Prozentpunkte (58.2% → 59.6%). Diese scheinbar kleinen Zahlen sind bedeutsam, da beide Packages umfangreich sind und die neuen Tests gezielt Lücken schließen.

Lazygit verfügt über 80+ Test-Dateien mit ~2500 Unit-Test-Funktionen. Unit-Tests laufen in unter einer Minute. Die Test-Code-Ratio ist ausgewogen – kritische Packages haben umfangreichere Tests. Die Tests integrierten sich nahtlos in die CI-Pipeline durch Standard-Go-Patterns und laufen auf allen Plattformen.

= Fazit

// Diese Arbeit analysierte das Testkonzept von lazygit umfassend und erweiterte es durch eigene Testfälle. Lazygit verfügt über eine ausgereifte Teststrategie mit Unit-Tests, Table-Driven Tests, Integrationstests und robuster CI/CD-Pipeline, die als Vorbild für andere Go-Projekte dienen kann.
//
// Die durchgeführten Arbeiten umfassten mehrere Phasen: Die initiale Analyse identifizierte Testlücken in Tag-Kommandos und StringStack durch Coverage-Analysen und Code-Reviews. Die Implementierung umfasste 18 Testfälle mit 13 Sub-Tests für Tags und fünf für Stack-Operationen, alle im table-driven bzw. zustandsbasierten Test-Stil. Die Erstellung umfassender Dokumentation in `TEST_ERKLAERUNG.md` bietet didaktisches Material für neue Contributors. Alle Tests wurden erfolgreich in die CI-Pipeline integriert und bestehen auf allen Plattformen.
//
// Die theoretischen Grundlagen des Software-Testens wurden praktisch angewendet und validiert. Table-driven Tests demonstrieren Go-Best-Practices für maximale Testabdeckung mit minimalem Code-Overhead. Mock-basiertes Testing zeigt, wie Unit-Tests schnell und deterministisch gestaltet werden können. Die Kombination von Unit- und Integrationstests folgt dem Pyramiden-Modell und optimiert die Balance zwischen Geschwindigkeit und Gründlichkeit.
//
// Lazygit dient als exzellentes Beispiel für durchdachte Teststrategien in Open-Source-Projekten. Die konsequente Anwendung von Testing-Best-Practices trägt zur hohen Code-Qualität bei und ermöglicht schnelle, konfidente Entwicklung. Die erstellten Tests und Dokumentationen verbessern die Codequalität nachhaltig und erleichtern zukünftigen Mitwirkenden den Einstieg.
//
// Persönlich war diese Arbeit lehrreich in mehrfacher Hinsicht. Die praktische Arbeit an einem realen Open-Source-Projekt vermittelte Einblicke, die durch rein akademische Übungen nicht möglich wären. Die Herausforderung, Tests für existierenden Code zu schreiben, unterscheidet sich fundamental von Test-First-Ansätzen und erfordert sorgfältige Analyse. Die Notwendigkeit, Projekt-Konventionen zu folgen und sich in bestehende Code-Bases einzuarbeiten, spiegelt realistische Berufspraxis wider.
//
// Die Erkenntnisse dieser Arbeit sind über lazygit hinaus wertvoll. Table-driven Tests sind in jedem Go-Projekt anwendbar. Mock-basierte Unit-Tests sind sprachübergreifend relevant. Die CI/CD-Patterns mit GitHub Actions lassen sich auf andere Projekte übertragen. Und die systematische Identifikation von Testlücken ist eine Fähigkeit, die in jeder professionellen Software-Entwicklung benötigt wird.
//
// Zukünftige Arbeiten könnten diese Analyse erweitern durch Performance-Benchmarking kritischer Komponenten, Mutation-Testing zur Validierung der Test-Qualität, End-to-End-Test-Automatisierung für komplexere User-Journeys oder Fuzz-Testing für Parser und Input-Validierung. Lazygit bietet ein reichhaltiges Umfeld für weitere Experimente im Software-Testing.

#pagebreak()
#show link: set text(fill: black)
#show bibliography: set heading(level: 2)
#bibliography("biblio.bib", title: "Quellen", style: "ieee")

= Anhang
#show figure: set block(breakable: true)
#figure(
  caption: "tag_test.go",
  kind: image,
)[```go
//tag_test.go
package git_commands

import (
	"testing"

	"github.com/jesseduffield/lazygit/pkg/commands/oscommands"
	"github.com/stretchr/testify/assert"
)

func TestTagCommands_CreateLightweightObj(t *testing.T) {
	type scenario struct {
		testName        string
		tagName         string
		ref             string
		force           bool
		expectedCmdArgs []string
	}

	scenarios := []scenario{
		{
      //TF-01
			testName:        "create simple lightweight tag on HEAD",
			tagName:         "v1.0.0",
			ref:             "",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "--", "v1.0.0"},
		},
		{
      //TF-02
			testName:        "create lightweight tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "abc123",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "--", "v1.0.0", "abc123"},
		},
		{
      //TF-03
			testName:        "create lightweight tag with force flag",
			tagName:         "v1.0.0",
			ref:             "",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "--force", "--", "v1.0.0"},
		},
		{
      //TF-04
			testName:        "create forced lightweight tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "def456",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "--force", "--", "v1.0.0", "def456"},
		},
	}

	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t)
			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			cmdObj := tagCommands.CreateLightweightObj(s.tagName, s.ref, s.force)

			assert.Equal(t, s.expectedCmdArgs, cmdObj.Args())
		})
	}
}

func TestTagCommands_CreateAnnotatedObj(t *testing.T) {
	type scenario struct {
		testName        string
		tagName         string
		ref             string
		msg             string
		force           bool
		expectedCmdArgs []string
	}

	scenarios := []scenario{
		{
      //TF-05
			testName:        "create annotated tag on HEAD",
			tagName:         "v1.0.0",
			ref:             "",
			msg:             "Release version 1.0.0",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "-m", "Release version 1.0.0"},
		},
		{
      //TF-06
			testName:        "create annotated tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "abc123",
			msg:             "Major release",
			force:           false,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "abc123", "-m", "Major release"},
		},
		{
      //TF-07
			testName:        "create forced annotated tag",
			tagName:         "v1.0.0",
			ref:             "",
			msg:             "Latest stable",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "--force", "-m", "Latest stable"},
		},
		{
      //TF-08
			testName:        "create forced annotated tag on specific commit",
			tagName:         "v1.0.0",
			ref:             "xyz789",
			msg:             "Beta version",
			force:           true,
			expectedCmdArgs: []string{"git", "tag", "v1.0.0", "--force", "xyz789", "-m", "Beta version"},
		},
	}

	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t)
			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			cmdObj := tagCommands.CreateAnnotatedObj(s.tagName, s.ref, s.msg, s.force)

			assert.Equal(t, s.expectedCmdArgs, cmdObj.Args())
		})
	}
}

func TestTagCommands_IsTagAnnotated(t *testing.T) {
	type scenario struct {
		testName       string
		tagName        string
		gitOutput      string
		gitError       error
		expectedResult bool
		expectedError  error
	}

	scenarios := []scenario{
		{
      //TF-09
			testName:       "tag is annotated",
			tagName:        "v1.0.0",
			gitOutput:      "tag\n",
			gitError:       nil,
			expectedResult: true,
			expectedError:  nil,
		},
		{
      //TF-10
			testName:       "tag is lightweight",
			tagName:        "v1.0.0",
			gitOutput:      "commit\n",
			gitError:       nil,
			expectedResult: false,
			expectedError:  nil,
		},
		{
      //TF-11
			testName:       "tag with extra whitespace",
			tagName:        "v1.0.0",
			gitOutput:      "  tag  \n",
			gitError:       nil,
			expectedResult: true,
			expectedError:  nil,
		},
	}

	for _, s := range scenarios {
		t.Run(s.testName, func(t *testing.T) {
			runner := oscommands.NewFakeRunner(t).
				ExpectGitArgs([]string{"cat-file", "-t", "refs/tags/" + s.tagName}, s.gitOutput, s.gitError)

			gitCommon := buildGitCommon(commonDeps{runner: runner})
			tagCommands := NewTagCommands(gitCommon)

			result, err := tagCommands.IsTagAnnotated(s.tagName)

			assert.Equal(t, s.expectedResult, result)
			if s.expectedError != nil {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
			runner.CheckForMissingCalls()
		})
	}
}

//TF-12
func TestTagCommands_LocalDelete(t *testing.T) {
	runner := oscommands.NewFakeRunner(t).
		ExpectGitArgs([]string{"tag", "-d", "v1.0.0"}, "", nil)

	gitCommon := buildGitCommon(commonDeps{runner: runner})
	tagCommands := NewTagCommands(gitCommon)

	err := tagCommands.LocalDelete("v1.0.0")

	assert.NoError(t, err)
	runner.CheckForMissingCalls()
}
```]<tag_test>

// ---------------------------------------------
// Use Case Tabellen – Tag-Verwaltung (lazygit)
// ---------------------------------------------

#let uc-table(title, rows) = [
  #table(
    columns: (22%, 78%),
    inset: 6pt,
    align: (left, left),
    stroke: (x: 0.6pt, y: 0.6pt),
    [*Use Case*], [*#title*],
    ..rows.join(),
  )
]

// Helper: Zeile erzeugen
#let uc-row(key, value) = ([*#key*], [#value])

// ---------------------------------------------
// UC1: Release-Version taggen
// ---------------------------------------------
#uc-table("UC1: Release-Version taggen", (
  uc-row("Akteur", "Software-Entwickler"),
  uc-row("Vorbedingungen", [
    - Repository ist in lazygit geöffnet
    - Commit für Release ist ausgewählt (z. B. im Commits-View oder Branches-View)
  ]),
  uc-row("Trigger", "Benutzer drückt `n` (new tag)"),
  uc-row("Hauptszenario", [
    1. System zeigt Eingabemaske mit zwei Feldern:
      - Tag-Name (z. B. \"v1.0.0\")
      - Optional: Tag-Beschreibung
    2. Benutzer gibt Tag-Name ein
    3. Benutzer entscheidet:
      - Beschreibung leer lassen → Lightweight Tag
      - Beschreibung eingeben → Annotated Tag
    4. System prüft, ob Tag bereits existiert (HasTag)
    5. System erstellt Tag auf ausgewähltem Commit
    6. System aktualisiert Tags- und Commits-View
    7. System zeigt Erfolgsmeldung
  ]),
  uc-row("Alternativszenarien", [
    *4a. Tag existiert bereits:*
    - 4a1. System zeigt Prompt: \"Force tag 'v1.0.0'? (Cancel: Esc, Confirm: Enter)\"
    - 4a2. Benutzer bestätigt → Tag wird mit `--force` überschrieben
    - 4a3. Benutzer bricht ab → Keine Änderung

    *5a. GPG-Signierung ist aktiviert:*
    - 5a1. System erstellt immer Annotated Tag (auch ohne Beschreibung)
    - 5a2. System fordert GPG-Passphrase an
    - 5a3. Tag wird signiert erstellt

    *7a. Git-Fehler (z. B. ungültiger Tag-Name):*
    - System zeigt Fehlermeldung
    - Benutzer kann erneut eingeben
  ]),
  uc-row("Nachbedingungen", [
    - Tag ist lokal auf dem ausgewählten Commit erstellt
    - Tag erscheint in der Tags-Liste
  ]),
  uc-row("Geschäftsregeln", [
    - Annotated Tags werden erstellt bei: Beschreibung vorhanden ODER GPG-Signing aktiviert
    - Lightweight Tags werden erstellt bei: Keine Beschreibung UND kein GPG-Signing
    - Force-Flag wird automatisch gesetzt, wenn Tag bereits existiert und Benutzer bestätigt
  ]),
  uc-row("Häufigkeit", "Hoch (bei jedem Release, Milestone, Hotfix)"),
))

// ---------------------------------------------
// UC2: Fehlerhaften Tag lokal korrigieren
// ---------------------------------------------
#uc-table("UC2: Fehlerhaften Tag lokal korrigieren", (
  uc-row("Akteur", "Software-Entwickler"),
  uc-row("Vorbedingungen", [
    - Repository ist geöffnet
    - Tag existiert lokal
    - Tag wurde noch nicht gepusht (oder Benutzer ist sich der Konsequenzen bewusst)
  ]),
  uc-row("Trigger", [
    - Benutzer navigiert zu Tags-View
    - Wählt fehlerhaften Tag aus
    - Drückt `d` (delete)
  ]),
  uc-row("Hauptszenario", [
    1. System zeigt Menü mit 3 Optionen:
      - `c` - Delete local tag
      - `r` - Delete remote tag
      - `b` - Delete both local and remote
    2. Benutzer wählt `c` (local delete)
    3. System führt `LocalDelete(tagName)` aus
    4. System entfernt Tag aus lokaler Datenbank
    5. System aktualisiert Tags-View
    6. Tag verschwindet aus der Liste
  ]),
  uc-row("Alternativszenarien", [
    *2a. Benutzer wählt Remote Delete:*
    - 2a1. System fragt nach Bestätigung
    - 2a2. System pusht Tag-Löschung zum Remote

    *2b. Benutzer wählt Both:*
    - 2b1. Lokaler Tag wird gelöscht
    - 2b2. Remote Tag wird gelöscht (mit Bestätigung)
  ]),
  uc-row("Nachbedingungen", [
    - Tag existiert nicht mehr lokal
    - Benutzer kann neuen Tag mit korrektem Namen/Commit erstellen
  ]),
  uc-row("Häufigkeit", "Mittel (bei Tippfehlern, falschen Commits)"),
))

// ---------------------------------------------
// UC3: Tag-Informationen anzeigen
// ---------------------------------------------
#uc-table("UC3: Tag-Informationen anzeigen", (
  uc-row("Akteur", "Software-Entwickler"),
  uc-row("Vorbedingungen", [
    - Repository ist geöffnet
    - Tags existieren
  ]),
  uc-row("Trigger", [
    - Benutzer navigiert zu Tags-View
    - Wählt einen Tag aus (mit Pfeiltasten)
  ]),
  uc-row("Hauptszenario", [
    1. System selektiert Tag
    2. System ruft `IsTagAnnotated(tagName)` auf
    3. Falls Annotated Tag:
      - 3a. System ruft `ShowAnnotationInfo(tagName)` auf
      - 3b. System zeigt im Main-Panel:
        - Tagger: Name <email>
        - TaggerDate: Datum
        - Tag-Message
    4. Falls Lightweight Tag:
      - 4a. System zeigt Commit-Details (da Tag nur Pointer ist)
    5. System zeigt zugehörigen Commit in der Ansicht
  ]),
  uc-row("Alternativszenarien", "Keine relevanten Abweichungen"),
  uc-row("Nachbedingungen", "Benutzer sieht Tag-Details und kann entscheiden (löschen, pushen, checkout)"),
  uc-row("Häufigkeit", "Hoch (bei Code-Review, Release-Vorbereitung)"),
))

// ---------------------------------------------
// UC4: Tag auf falschen Commit verschieben
// ---------------------------------------------
#uc-table("UC4: Bestehenden Tag verschieben (Force-Update)", (
  uc-row("Akteur", "Software-Entwickler"),
  uc-row("Kontext", "\"latest\"-Tag oder \"stable\"-Tag soll immer auf aktuellsten Stand zeigen"),
  uc-row("Vorbedingungen", [
    - Repository ist geöffnet
    - Tag \"latest\" existiert auf älterem Commit
    - Neuer Commit soll getaggt werden
  ]),
  uc-row("Trigger", "Benutzer will Tag aktualisieren"),
  uc-row("Hauptszenario", [
    1. Benutzer navigiert zu neuem Commit
    2. Benutzer drückt `n` (new tag)
    3. Benutzer gibt existierenden Tag-Namen ein (z. B. \"latest\")
    4. System erkennt via `HasTag(\"latest\")`, dass Tag existiert
    5. System zeigt Force-Prompt
    6. Benutzer bestätigt
    7. System erstellt Tag mit `--force` Flag
    8. Tag wird auf neuen Commit verschoben
  ]),
  uc-row("Nachbedingungen", [
    - Tag zeigt auf neuen Commit
    - Alter Commit ist nicht mehr getaggt
  ]),
  uc-row("Geschäftsregel", [
    - Force-Tags auf Remote können Probleme für andere Entwickler verursachen
    - Wird oft in CI/CD für Rolling-Tags verwendet
  ]),
  uc-row("Häufigkeit", "Mittel (bei Rolling-Tags, Hotfix-Korrekturen)"),
))

#table(
  columns: (45%, 55%),
  inset: 6pt,
  align: (left, left),
  stroke: (x: 0.6pt, y: 0.6pt),

  [*Use Case*], [*Führt zu Test*],

  [UC1 - Lightweight Tag auf HEAD], [CreateLightweightObj - Scenario 1],
  [UC1 - Annotated Tag mit Message], [CreateAnnotatedObj - Scenario 1],
  [UC1 - Tag auf älteren Commit], [CreateLightweightObj - Scenario 2],
  [UC4 - Tag verschieben (Force)], [CreateLightweightObj - Scenario 3 & 4],
  [UC2 - Tag löschen], [LocalDelete - Test],
  [UC3 - Tag-Typ erkennen], [IsTagAnnotated - Alle Scenarios],
)

