#import "template.typ": *
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
= Theoretische Grundlagen

Software-Testing ist ein zentraler Bestandteil der Qualitätssicherung in der Softwareentwicklung. Das oft zitierte Statement von Edsger W. Dijkstra bringt dabei eine grundlegende Eigenschaft des Testens prägnant auf den Punkt: Tests eignen sich hervorragend zum Aufdecken von Fehlern, sind jedoch ungeeignet, um die vollständige Fehlerfreiheit eines Programms nachzuweisen #cite(<Dijkstra2007HumbleProgrammer>).

Diese Einschränkung ergibt sich aus der Natur des Software-Testings als Stichprobenverfahren. Da Programme in der Regel eine sehr große Menge möglicher Eingaben besitzen, kann im Rahmen von Tests nur eine endliche Teilmenge davon überprüft werden. Ein formaler Beweis der Korrektheit allein durch Tests ist daher prinzipiell nicht möglich.

Vor diesem Hintergrund kommt der systematischen und zielgerichteten Auswahl repräsentativer Testfälle eine zentrale Bedeutung zu. Ziel des Testens ist es nicht, Fehlerfreiheit zu garantieren, sondern mit begrenztem Aufwand eine möglichst hohe Wahrscheinlichkeit zur Entdeckung relevanter Defekte zu erreichen.

Der Testprozess lässt sich grundsätzlich in zwei zentrale Bereiche gliedern: die statische Analyse und das dynamische Testen #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 4]). Die statische Analyse untersucht Softwareartefakte ohne deren Ausführung und zielt darauf ab, potenzielle Fehler, Regelverletzungen oder Qualitätsmängel frühzeitig im Entwicklungsprozess zu identifizieren #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 43–45]). Zu den typischen Verfahren zählen Code-Reviews, der Einsatz von Lintern sowie statische Datenfluss- und Kontrollflussanalysen.

Demgegenüber steht das dynamische Testen, bei dem die Software mit konkreten Eingabedaten ausgeführt wird. Dadurch lassen sich insbesondere solche Fehler aufdecken, die erst zur Laufzeit auftreten, etwa Speicherlecks, Race Conditions oder fehlerhaftes Laufzeitverhalten. Dynamische Tests ermöglichen somit eine Überprüfung des tatsächlichen Systemverhaltens unter realistischen oder gezielt konstruierten Bedingungen #cite(<LiggesmeyerSoftwareQualitaet2009>, supplement: [S. 39–43]). Der Schwerpunkt dieser Arbeit liegt auf dem dynamischen Testen und den zugehörigen Testverfahren.

Dynamisches Testen lässt sich grundsätzlich in Black-Box-Tests und White-Box-Tests unterteilen. Black-Box-Tests leiten Testfälle ausschließlich aus Spezifikationen und Anforderungen ab, ohne Kenntnis der internen Programmstruktur. Typische Verfahren sind hierbei die Äquivalenzklassenbildung sowie die Grenzwertanalyse. White-Box-Tests hingegen konstruieren Testfälle auf Basis der internen Programmstruktur mit dem Ziel, definierte Abdeckungskriterien wie Anweisungs- oder Pfadabdeckung zu erfüllen #cite(<HoffmannSoftwareQualitaet2013>, supplement: [S. 173–174]). In der praktischen Testpraxis werden beide Ansätze häufig kombiniert, um sowohl funktionale als auch strukturelle Aspekte der Software zu überprüfen.

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

Es gibt über 450 solcher Integrationstests, die alle möglichen Szenarien abdecken: Branch-Operationen wie Checkout oder Rebase (über 100 Tests), Commit-Operationen wie Amend oder Cherry-Pick (über 120 Tests), interaktive Rebases (über 140 Tests), Konfliktbehandlung, File-Operations und noch mehr. Das Framework bietet verschiedene "Driver" für unterschiedliche UI-Komponenten – einen für Listen, einen für Menüs, einen für Eingabefelder. Wenn sich die UI-Struktur ändert, muss man nur die Driver anpassen, nicht jeden einzelnen Test.

Technisch basiert das Framework auf einer Architektur spezialisierter Driver-Komponenten. Der `ViewDriver` ermöglicht Interaktionen mit Listen-Views wie Branches, Commits und Files, während der `MenuDriver` die Navigation in Popup-Menüs steuert. Der `PromptDriver` behandelt Texteingaben, der `ConfirmationDriver` das Bestätigen oder Ablehnen von Dialogen und der `AlertDriver` die Validierung von Fehlermeldungen. Diese Abstraktion entkoppelt die Testlogik von der konkreten UI-Implementation, was Refactorings erheblich erleichtert. Ändert sich die Struktur der Benutzeroberfläche, müssen lediglich die Driver-Implementierungen angepasst werden, während die hunderten von Tests unverändert bleiben können.

// #pagebreak()
// = Continuous Integration Pipeline
//
// Lazygit nutzt GitHub Actions für die automatisierte Qualitätssicherung. Bei jedem Push und Pull Request läuft eine CI-Pipeline, die in der Datei `.github/workflows/ci.yml` konfiguriert ist.
//
// Die Pipeline besteht im Wesentlichen aus fünf verschiedenen Jobs, die alle gleichzeitig laufen. Der erste Job führt die Unit-Tests aus, und zwar sowohl auf Ubuntu als auch auf Windows. Das ist wichtig, weil Lazygit eine Cross-Platform-Anwendung ist und auf verschiedenen Betriebssystemen laufen muss. GitHub Actions nutzt dafür eine sogenannte Matrix-Strategy, die den gleichen Test automatisch mit verschiedenen Konfigurationen ausführt. Die Unit-Tests werden mit dem Befehl `go test ./... -short` gestartet, wobei das `-short`-Flag dafür sorgt, dass nur die schnellen Unit-Tests laufen und die zeitintensiven Integrationstests übersprungen werden. Die Testergebnisse und Coverage-Daten werden anschließend als Artifacts hochgeladen, sodass sie später wieder abgerufen werden können.
//
// Der zweite Job ist für die Integrationstests zuständig und testet gegen vier verschiedene Git-Versionen: 2.32.0 als älteste unterstützte Version, 2.38.2 als erste Version mit einer bestimmten Rebase-Funktion, 2.44.0 als aktuell stabile Version und die neueste Version, die es gibt. Diese Kompatibilitätsprüfung ist notwendig, weil Git zwischen Versionen manchmal Breaking Changes einführt und Lazygit mit allen noch unterstützten Versionen funktionieren soll. Für die älteren Git-Versionen wird Git tatsächlich aus dem Quellcode kompiliert, was theoretisch sehr lange dauern würde, aber durch Caching beschleunigt wird. Ein Skript namens `run_integration_tests.sh` orchestriert die Testausführung.
//
// Der dritte Job kompiliert Lazygit für verschiedene Plattformen – Linux, Windows und macOS (Darwin). Auch wenn hier keine Tests laufen, ist dieser Build-Schritt wichtig, weil er sicherstellt, dass der Code überhaupt auf allen Zielsystemen kompiliert werden kann. In Go funktioniert das über Umgebungsvariablen wie `GOOS=linux` oder `GOOS=windows`, die dem Compiler sagen, für welches System er bauen soll.
//
// Der vierte Job prüft die Konsistenz der Codebase. Er stellt sicher, dass die Dependencies im `vendor`-Verzeichnis mit den Angaben in `go.mod` übereinstimmen, dass keine veralteten Dependencies referenziert werden und dass automatisch generierte Dateien aktuell sind. Diese Checks sind vielleicht nicht so spannend, aber durchaus wichtig – es ist schon öfter passiert, dass jemand vergessen hat, nach einer Dependency-Änderung `go mod tidy` auszuführen, und dann baut es auf anderen Rechnern nicht mehr.
//
// Der fünfte Job führt statische Code-Analyse mit golangci-lint durch. Dieser Linter ist ziemlich gründlich und findet potenzielle Bugs wie Null-Pointer-Dereferenzierungen, Performance-Probleme, unsichere Code-Patterns und Style-Violations. Manchmal ist er auch etwas pingelig, aber besser zu pingelig als zu lasch.
//
// Nachdem all diese Jobs durchgelaufen sind, gibt es noch einen speziellen `upload-coverage` Job, der darauf wartet, dass Unit-Tests und Integrationstests fertig sind. Er sammelt dann alle Coverage-Daten ein, fügt sie zusammen und lädt das Ergebnis zu Codacy hoch, einem Service, der Code-Qualität und Test-Coverage trackt. Das Zusammenführen der Coverage-Daten ist etwas komplizierter geworden seit Go 1.21, weil das neue Coverage-Format andere Tools benötigt (`go tool covdata`), aber dafür kann es jetzt auch Coverage von kompilierten Binaries erfassen, was für die Integrationstests wichtig ist.
//
// Die Coverage-Werte sind je nach Komponente unterschiedlich. Die Command-Builder-Komponenten, die Git-Befehle zusammenbauen, haben mit 75-85% eine recht gute Coverage. Die Loader-Komponenten kommen auf 70-80%, die Controller-Logik auf 60-70%. Die Presentation-Layer und UI-Rendering-Komponenten haben mit 40-55% bzw. 25-40% deutlich niedrigere Werte. Das ist aber bei Terminal-Anwendungen ganz normal – UI-Code ist generell schwieriger zu testen und ändert sich auch häufiger. Das Projekt gleicht das durch die umfangreichen Integrationstests aus, die die UI indirekt mittesten.
//
// Zusätzlich zu den Tests gibt es noch ein paar Safeguards. Die Pipeline prüft zum Beispiel, dass keine `fixup!`-Commits versehentlich gemergt werden und dass Pull Requests bestimmte Labels haben. Direkt auf den Master-Branch pushen ist sowieso nicht erlaubt – alles muss über Pull Requests gehen, und die können nur gemergt werden, wenn alle Checks grün sind. Dank der Parallelisierung dauert die gesamte Pipeline typischerweise nur 15-20 Minuten. Würde alles hintereinander laufen, wäre man bei über einer Stunde.
//
// Insgesamt umfasst die Testsuite über 80 Unit-Test-Dateien mit etwa 2500 einzelnen Testfunktionen und mehr als 450 Integrationstests. Die Unit-Tests laufen in rund 10 Sekunden durch, die Integrationstests brauchen 5-10 Minuten. Das Verhältnis von Test-Code zu Produktionscode liegt in kritischen Packages bei etwa 1.2:1 – das heißt, für jede Zeile Produktionscode gibt es etwas mehr als eine Zeile Test-Code. Die schnellen Unit-Tests ermöglichen es Entwicklern, nach jeder kleinen Änderung `go test ./...` laufen zu lassen, ohne lange warten zu müssen.
//
#pagebreak()
= Entwurf eigener Testfälle

Der praktische Teil dieser Arbeit bestand darin, Testlücken im Lazygit-Projekt zu identifizieren und durch eigene Testfälle zu schließen. Dabei wurden die zuvor analysierten Teststrategien angewendet und die Coverage messbar verbessert.

== Identifikation von Testlücken

Die Analyse der Coverage-Reports aus der CI-Pipeline in Kombination mit manuellen Code-Reviews identifizierte zwei signifikante Testlücken. Die Tag-Kommandos in `pkg/commands/git_commands/tag.go` enthielten acht Funktionen ohne jegliche Testabdeckung. Tags sind in Git zentral für die Versionsverwaltung, weshalb fehlerhafte Implementierungen zu versehentlich überschriebenen oder falsch gesetzten Tags führen können. Die zweite Lücke betraf die `StringStack`-Datenstruktur in `pkg/utils/string_stack.go`, eine LIFO-Implementierung ohne Tests. Die Priorisierung erfolgte nach Kritikalität, wobei die Tag-Funktionen als wichtiger eingestuft wurden.

== Analyse und Testfalldesign

Die Tag-Funktionen konstruieren Git-Befehle programmatisch mit Hilfsfunktionen wie `NewGitCmd` und `ArgIf`, die Argumente nur unter bestimmten Bedingungen hinzufügen. Beispielsweise fügt `ArgIf(force, "--force")` das Force-Flag nur bei Bedarf hinzu. Diese bedingte Logik ist fehleranfällig und erfordert Tests für verschiedene Parameter-Kombinationen.

Für die Tag-Kommandos wurde Table-Driven Testing gewählt, da dies dem Projekt-Standard entspricht und sich optimal für Parametervariationen eignet. Die Tests für `CreateLightweightObj` decken vier Szenarien ab: einfacher Tag auf HEAD, Tag auf spezifischem Commit, Force-Flag zum Überschreiben existierender Tags und die Kombination aller Parameter. Für `CreateAnnotatedObj` wurden analoge Tests mit zusätzlichem Message-Parameter entwickelt. Die Funktion `IsTagAnnotated` parst Git-Ausgaben ("commit" vs. "tag") und erhielt Tests mit verschiedenen Ausgabeformaten inklusive Whitespace-Varianten.

Für `StringStack` wurde ein zustandsbasierter Testansatz gewählt. Die Tests validieren LIFO-Semantik (`TestStringStack_PushAndPop`), das Verhalten bei leerem Stack (`TestStringStack_PopEmptyStack`), Zustandsprüfung (`TestStringStack_IsEmpty`), vollständiges Zurücksetzen (`TestStringStack_Clear`) und komplexe Operationssequenzen (`TestStringStack_MultipleOperations`).

== Implementierung

Die Tag-Tests wurden in `tag_test.go` implementiert und folgen strikt den Projekt-Konventionen. Jeder Testfall definiert eine Szenario-Struktur mit Eingabeparametern und erwarteten Git-Argumenten:

```go
{
    testName: "create lightweight tag on HEAD",
    tagName:  "v1.0",
    commitSha: "",
    force:    false,
    expectedArgs: []string{"tag", "v1.0"},
}
```

Der `FakeCmdObjRunner` simuliert Git-Befehle ohne tatsächliche Ausführung. Für jeden Testfall werden die erwarteten Argumente beim Fake-Runner registriert, die Funktion ausgeführt und anschließend mit `CheckForMissingCalls()` validiert, dass alle erwarteten Befehle aufgerufen wurden.

Die StringStack-Tests verwenden klassisches Unit-Testing ohne Table-Driven-Ansatz, da primär Zustandsübergänge getestet werden:

```go
func TestStringStack_PushAndPop(t *testing.T) {
    stack := NewStringStack()
    stack.Push("first")
    stack.Push("second")
    
    assert.Equal(t, "second", stack.Pop())
    assert.Equal(t, "first", stack.Pop())
}
```

== Testergebnisse und Coverage-Verbesserung

Insgesamt wurden 18 Tests implementiert: 13 für Tag-Operationen und 5 für StringStack. Die lokale Ausführung mit `go test ./pkg/commands/git_commands -run TestTag -v` dauert unter 10 Millisekunden. Die CI-Pipeline validierte alle Tests erfolgreich auf Ubuntu und Windows ohne plattformspezifische Probleme.

Die Coverage-Analyse zeigt signifikante Verbesserungen für `tag.go`, wo fünf von acht Funktionen auf 100% Coverage gebracht wurden:
- `NewTagCommands`: 0% → 100%
- `CreateLightweightObj`: 0% → 100%
- `CreateAnnotatedObj`: 0% → 100%
- `LocalDelete`: 0% → 100%
- `IsTagAnnotated`: 0% → 100%

Die drei verbleibenden Funktionen (`HasTag`, `Push`, `ShowAnnotationInfo`) sind Remote-Operationen, die Netzwerk-Kommunikation erfordern und besser durch Integrationstests abgedeckt werden. Die Gesamt-Coverage von `tag.go` stieg von 0% auf 62.5%.

Für `string_stack.go` wurde vollständige Coverage erreicht:
- `Push`: 0% → 100%
- `Pop`: 0% → 100%
- `IsEmpty`: 0% → 100%
- `Clear`: 0% → 100%

Auf Package-Ebene verbesserte sich `pkg/commands/git_commands` von 37.1% auf 37.6% (+0.5 Prozentpunkte) und `pkg/utils` von 58.2% auf 59.6% (+1.4 Prozentpunkte). Obwohl die prozentualen Verbesserungen moderat erscheinen, schließen sie konkrete Lücken in wichtigen Funktionen innerhalb umfangreicher Packages.

= Testauswertung und Metriken

Die Coverage-Verbesserungen sind messbar und signifikant. Für `tag.go` stieg die Coverage von 0% auf 62.5%, wobei alle getesteten Funktionen 100% Coverage erreichten. Nur drei Remote-Funktionen blieben ungetestet. `string_stack.go` erreichte vollständige 100% Coverage für alle Funktionen.

Auf Package-Ebene verbesserte sich `pkg/commands/git_commands` um 0.5 Prozentpunkte (37.1% → 37.6%) und `pkg/utils` um 1.4 Prozentpunkte (58.2% → 59.6%). Diese scheinbar kleinen Zahlen sind bedeutsam, da beide Packages umfangreich sind und die neuen Tests gezielt Lücken schließen.

Lazygit verfügt über 80+ Test-Dateien mit ~2500 Unit-Test-Funktionen. Unit-Tests laufen in unter einer Minute. Die Test-Code-Ratio ist ausgewogen – kritische Packages haben umfangreichere Tests. Die Tests integrierten sich nahtlos in die CI-Pipeline durch Standard-Go-Patterns und laufen auf allen Plattformen.

= Fazit

Diese Arbeit analysierte das Testkonzept von lazygit umfassend und erweiterte es durch eigene Testfälle. Lazygit verfügt über eine ausgereifte Teststrategie mit Unit-Tests, Table-Driven Tests, Integrationstests und robuster CI/CD-Pipeline, die als Vorbild für andere Go-Projekte dienen kann.

Die durchgeführten Arbeiten umfassten mehrere Phasen: Die initiale Analyse identifizierte Testlücken in Tag-Kommandos und StringStack durch Coverage-Analysen und Code-Reviews. Die Implementierung umfasste 18 Testfälle mit 13 Sub-Tests für Tags und fünf für Stack-Operationen, alle im table-driven bzw. zustandsbasierten Test-Stil. Die Erstellung umfassender Dokumentation in `TEST_ERKLAERUNG.md` bietet didaktisches Material für neue Contributors. Alle Tests wurden erfolgreich in die CI-Pipeline integriert und bestehen auf allen Plattformen.

Die theoretischen Grundlagen des Software-Testens wurden praktisch angewendet und validiert. Table-driven Tests demonstrieren Go-Best-Practices für maximale Testabdeckung mit minimalem Code-Overhead. Mock-basiertes Testing zeigt, wie Unit-Tests schnell und deterministisch gestaltet werden können. Die Kombination von Unit- und Integrationstests folgt dem Pyramiden-Modell und optimiert die Balance zwischen Geschwindigkeit und Gründlichkeit.

Lazygit dient als exzellentes Beispiel für durchdachte Teststrategien in Open-Source-Projekten. Die konsequente Anwendung von Testing-Best-Practices trägt zur hohen Code-Qualität bei und ermöglicht schnelle, konfidente Entwicklung. Die erstellten Tests und Dokumentationen verbessern die Codequalität nachhaltig und erleichtern zukünftigen Mitwirkenden den Einstieg.

Persönlich war diese Arbeit lehrreich in mehrfacher Hinsicht. Die praktische Arbeit an einem realen Open-Source-Projekt vermittelte Einblicke, die durch rein akademische Übungen nicht möglich wären. Die Herausforderung, Tests für existierenden Code zu schreiben, unterscheidet sich fundamental von Test-First-Ansätzen und erfordert sorgfältige Analyse. Die Notwendigkeit, Projekt-Konventionen zu folgen und sich in bestehende Code-Bases einzuarbeiten, spiegelt realistische Berufspraxis wider.

Die Erkenntnisse dieser Arbeit sind über lazygit hinaus wertvoll. Table-driven Tests sind in jedem Go-Projekt anwendbar. Mock-basierte Unit-Tests sind sprachübergreifend relevant. Die CI/CD-Patterns mit GitHub Actions lassen sich auf andere Projekte übertragen. Und die systematische Identifikation von Testlücken ist eine Fähigkeit, die in jeder professionellen Software-Entwicklung benötigt wird.

Zukünftige Arbeiten könnten diese Analyse erweitern durch Performance-Benchmarking kritischer Komponenten, Mutation-Testing zur Validierung der Test-Qualität, End-to-End-Test-Automatisierung für komplexere User-Journeys oder Fuzz-Testing für Parser und Input-Validierung. Lazygit bietet ein reichhaltiges Umfeld für weitere Experimente im Software-Testing.

#pagebreak()
#show link: set text(fill: black)
#show bibliography: set heading(level: 2)
#bibliography("biblio.bib", title: "Quellen", style: "ieee")
