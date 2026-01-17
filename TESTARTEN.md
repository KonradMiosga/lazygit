# Testarten im Lazygit-Projekt

Dieses Dokument beschreibt die verschiedenen Testarten, die im Lazygit-Projekt verwendet werden.

---

## 1. Unit Tests

**📍 Wo:** `pkg/utils/*_test.go`, `pkg/commands/git_commands/*_test.go`

**Beispiele:** 
- `string_stack_test.go`
- `tag_test.go`
- `slice_test.go`

### Charakteristika:
- Testen einzelne Funktionen/Methoden isoliert
- Verwenden Mocks (FakeRunner, keine echten Git-Befehle)
- Schnell ausführbar
- Keine externen Abhängigkeiten

### Beispiel aus tag_test.go:
```go
func TestTagCommands_CreateLightweightObj(t *testing.T) {
    // Testet nur die Befehlsgenerierung, nicht die Ausführung
    runner := oscommands.NewFakeRunner(t)
    gitCommon := buildGitCommon(commonDeps{runner: runner})
    tagCommands := NewTagCommands(gitCommon)
    
    cmdObj := tagCommands.CreateLightweightObj("v1.0.0", "", true)
    
    assert.Equal(t, expectedCmdArgs, cmdObj.Args())
}
```

**Zweck:** Einzelne Funktionen in Isolation testen, um sicherzustellen, dass die Logik korrekt ist.

---

## 2. Table-Driven Tests

**📍 Wo:** Fast überall in `*_test.go` Dateien

**Beispiele:**
- `slice_test.go`
- `branch_test.go`
- `tag_test.go`

### Charakteristika:
- Mehrere Testfälle in einer Test-Funktion
- Test-Szenarien in einem Array/Slice definiert
- Schleife iteriert über alle Szenarien
- Reduziert Code-Duplikation
- Macht Tests lesbarer und wartbarer

### Beispiel:
```go
func TestNextIndex(t *testing.T) {
    type scenario struct {
        testName string
        list     []int
        element  int
        expected int
    }

    scenarios := []scenario{
        {
            testName: "one element",
            list:     []int{1},
            element:  1,
            expected: 0,
        },
        {
            testName: "two elements",
            list:     []int{1, 2},
            element:  1,
            expected: 1,
        },
    }
    
    for _, s := range scenarios {
        t.Run(s.testName, func(t *testing.T) {
            result := NextIndex(s.list, s.element)
            assert.Equal(t, s.expected, result)
        })
    }
}
```

**Zweck:** Viele ähnliche Testfälle effizient und übersichtlich testen.

---

## 3. Integration Tests

**📍 Wo:** `pkg/integration/tests/`

**Beispiele:**
- `bisect/basic.go`
- `branch/checkout_autostash.go`
- `commit/new_branch.go`

### Charakteristika:
- Starten eine **echte lazygit Session**
- Simulieren User-Interaktionen (Tastendruck, Navigation)
- Testen mehrere Komponenten zusammen
- Verwenden echte Git-Repositories (im Test erstellt)
- Langsamer als Unit Tests
- Testen realistische User-Workflows

### Struktur:
```go
var CheckoutAutostash = NewIntegrationTest(NewIntegrationTestArgs{
    Description: "Check out a branch that requires performing autostash",
    SetupRepo: func(shell *Shell) {
        // Erstellt echtes Git-Repo
        shell.CreateFileAndAdd("file", "a\n\nb")
        shell.Commit("add file")
        shell.UpdateFileAndAdd("file", "a\n\nc")
        shell.Commit("edit last line")
        shell.Checkout("HEAD^")
        shell.UpdateFile("file", "b\n\nb")
    },
    Run: func(t *TestDriver, keys config.KeybindingConfig) {
        // Simuliert User-Aktionen
        t.Views().Branches().
            Focus().
            Press(keys.Universal.Confirm)
        
        // Prüft erwartete Ergebnisse
        t.Views().Information().Content(Contains("Autostashed"))
    },
})
```

### Ausführung:
```bash
# Über TUI (empfohlen)
go run cmd/integration_test/main.go tui

# Über CLI
go run cmd/integration_test/main.go cli [testname]
```

**Zweck:** Testen wie mehrere Komponenten zusammenarbeiten und ob die Gesamtfunktionalität korrekt ist.

---

## 4. Command-Building Tests

**📍 Wo:** `pkg/commands/git_commands/*_test.go`

**Beispiele:**
- `git_command_builder_test.go`
- `sync_test.go`
- `branch_test.go`

### Charakteristika:
- Testen **nur** die Git-Befehlsgenerierung
- Verwenden FakeRunner (keine echte Ausführung)
- Prüfen ob korrekte Git-Befehle gebaut werden
- Validieren Befehlsargumente und deren Reihenfolge
- NICHT die tatsächliche Ausführung

### Beispiel:
```go
func TestBranchNewBranch(t *testing.T) {
    runner := oscommands.NewFakeRunner(t).
        ExpectGitArgs([]string{"checkout", "-b", "test", "refs/heads/master"}, "", nil)
    
    instance := buildBranchCommands(commonDeps{runner: runner})
    
    assert.NoError(t, instance.New("test", "refs/heads/master"))
    runner.CheckForMissingCalls()
}
```

**Zweck:** Sicherstellen, dass die richtigen Git-Befehle mit den richtigen Argumenten generiert werden.

---

## 5. Parser/Loader Tests

**📍 Wo:** `pkg/commands/git_commands/*_loader_test.go`

**Beispiele:**
- `commit_loader_test.go`
- `branch_loader_test.go`
- `stash_loader_test.go`

### Charakteristika:
- Testen das Parsen von Git-Output
- Verwenden vorgefertigte Git-Output-Strings
- Prüfen ob Daten korrekt in Modelle umgewandelt werden
- Validieren Parsing-Logik für verschiedene Git-Ausgabeformate

### Beispiel:
```go
var commitsOutput = strings.ReplaceAll(
    `+0eea75e8c631fba6b58135697835d58ba4c18dbc|1640826609|Jesse Duffield|jessedduffield@gmail.com|b21997d6b4cbdf84b149|>|HEAD -> better-tests|better typing for rebase mode
+b21997d6b4cbdf84b149d8e6a2c4d06a8e9ec164|1640824515|Jesse Duffield|jessedduffield@gmail.com|e94e8fc5b6fab4cb755f|>|origin/better-tests|fix logging`,
    "|", "\x00")

func TestGetCommits(t *testing.T) {
    runner := oscommands.NewFakeRunner(t).
        ExpectGitArgs([]string{"log", "HEAD", ...}, commitsOutput, nil)
    
    commits, err := loader.GetCommits(opts)
    
    // Prüft ob der Output korrekt zu Commit-Objekten geparst wurde
    assert.NoError(t, err)
    assert.Len(t, commits, 2)
    assert.Equal(t, "0eea75e8c631fba6b58135697835d58ba4c18dbc", commits[0].Hash)
}
```

**Zweck:** Sicherstellen, dass Git-Ausgaben korrekt interpretiert und in verwendbare Datenstrukturen umgewandelt werden.

---

## 6. Mock-basierte Tests

**📍 Wo:** Überall wo `FakeRunner` verwendet wird

### Charakteristika:
- Verwenden Mock-Objekte statt echter Abhängigkeiten
- `FakeRunner` simuliert Git-Befehle ohne sie auszuführen
- Können Fehler simulieren
- Volle Kontrolle über Return-Werte
- Ermöglichen Tests ohne Git-Installation

### Beispiel:
```go
func TestBranchGetCommitDifferences(t *testing.T) {
    runner := oscommands.NewFakeRunner(t).
        ExpectGitArgs([]string{"rev-list", "@{u}..HEAD", "--count"}, "1\n", nil).
        ExpectGitArgs([]string{"rev-list", "HEAD..@{u}", "--count"}, "2\n", nil)
    
    instance := buildBranchCommands(commonDeps{runner: runner})
    pushables, pullables := instance.GetCommitDifferences("HEAD", "@{u}")
    
    assert.Equal(t, "1", pushables)
    assert.Equal(t, "2", pullables)
    runner.CheckForMissingCalls()
}
```

### Fehler-Simulation:
```go
runner := oscommands.NewFakeRunner(t).
    ExpectGitArgs([]string{"push"}, "", errors.New("network error"))
```

**Zweck:** Tests unabhängig von externen Abhängigkeiten machen und Fehlerfälle einfach simulieren.

---

## 7. End-to-End Tests

**📍 Wo:** `pkg/integration/tests/` (gehören zu Integration Tests)

### Charakteristika:
- Testen komplette User-Workflows von Anfang bis Ende
- Von Setup bis zum erwarteten Endergebnis
- Mehrere Features zusammen
- Realistischste Tests
- Am nächsten an echter Benutzung

### Beispiel - Bisect Workflow:
```go
var Basic = NewIntegrationTest(NewIntegrationTestArgs{
    Description: "Start a git bisect to find a bad commit",
    SetupRepo: func(shell *Shell) {
        shell.NewBranch("mybranch").CreateNCommits(10)
    },
    Run: func(t *TestDriver, keys config.KeybindingConfig) {
        // 1. Bisect starten
        t.Views().Commits().Press(keys.Commits.ViewBisectOptions)
        t.ExpectPopup().Menu().Select(Contains("Mark as bad")).Confirm()
        
        // 2. Guten Commit markieren
        t.Views().Commits().NavigateToLine(Contains("commit 01"))
        t.Views().Commits().Press(keys.Commits.ViewBisectOptions)
        t.ExpectPopup().Menu().Select(Contains("Mark as good")).Confirm()
        
        // 3. Ergebnis prüfen
        t.Views().Information().Content(Contains("Bisecting"))
    },
})
```

**Zweck:** Sicherstellen, dass komplette User-Workflows wie erwartet funktionieren.

---

## Testpyramide im Lazygit-Projekt

```
        ┌─────────────────────┐
        │  Integration/E2E    │  ← Wenige, langsam, realistisch
        │      Tests          │     Vollständige Workflows
        │  (pkg/integration/) │
        ├─────────────────────┤
        │  Command Building   │  ← Mittel, mittel-schnell
        │  & Parser Tests     │     Git-Befehlsgenerierung
        │  (*_test.go)        │     Output-Parsing
        ├─────────────────────┤
        │    Unit Tests       │  ← Viele, schnell, isoliert
        │   (Table-Driven)    │     Einzelne Funktionen
        │  (utils/*_test.go)  │     Kleine Code-Einheiten
        └─────────────────────┘
```

### Verteilung:
- **Unit Tests**: ~70-80% aller Tests
- **Command/Parser Tests**: ~15-20% aller Tests
- **Integration/E2E Tests**: ~5-10% aller Tests

---

## Was FEHLT im Projekt

Diese Testarten wurden **nicht** gefunden:

- ❌ **Benchmark Tests** (keine `func BenchmarkXxx` gefunden)
  - Würden Performance messen
  - Format: `func BenchmarkMyFunction(b *testing.B)`

- ❌ **Performance Tests**
  - Würden Laufzeit und Ressourcenverbrauch messen

- ❌ **Fuzz Tests** (keine `func FuzzXxx`)
  - Würden zufällige Inputs generieren
  - Go 1.18+ Feature

- ❌ **Property-Based Tests**
  - Würden Eigenschaften statt konkreter Werte testen

---

## Tests ausführen

### Alle Unit Tests:
```bash
go test ./pkg/...
```

### Spezifisches Package:
```bash
go test ./pkg/utils
go test ./pkg/commands/git_commands
```

### Einzelner Test:
```bash
go test ./pkg/utils -run TestStringStack
```

### Mit Verbose Output:
```bash
go test ./pkg/utils -v
```

### Integration Tests (TUI):
```bash
go run cmd/integration_test/main.go tui
```

### Integration Tests (CLI):
```bash
# Alle Tests
go run cmd/integration_test/main.go cli

# Spezifischer Test
go run cmd/integration_test/main.go cli branch/checkout

# Im langsamen Modus (zum Zuschauen)
go run cmd/integration_test/main.go cli --slow branch/checkout
```

---

## Die wichtigsten Testarten für Belegarbeit

### 1. **Unit Tests**
- Einfachste Form
- Gutes Einstiegsbeispiel: `string_stack_test.go`
- Zeigt Grundprinzipien

### 2. **Table-Driven Tests**
- Professionelles Pattern
- Zeigt fortgeschrittenes Testing
- Beispiel: `tag_test.go`

### 3. **Integration Tests**
- Komplexeste Form
- Zeigt realistische Workflows
- Beispiel: `pkg/integration/tests/branch/`

---

## Best Practices im Projekt

### ✅ Gut gemacht:
1. **Konsistente Namenskonvention**: `*_test.go`
2. **Table-Driven Tests**: Reduziert Duplikation
3. **Mock-Objekte**: Tests sind schnell und isoliert
4. **Klare Test-Namen**: Beschreiben was getestet wird
5. **Helper-Funktionen**: `buildGitCommon()`, `buildBranchCommands()`
6. **Separate Integration Tests**: Eigenes Package

### ⚠️ Könnte besser sein:
1. Keine Benchmark Tests
2. Manche Funktionen haben keine Tests (z.B. `status.go`)
3. Test-Coverage nicht dokumentiert

---

## Zusammenfassung

Das Lazygit-Projekt verwendet eine **gute Mischung** aus verschiedenen Testarten:

- **Unit Tests** für schnelle, isolierte Tests einzelner Funktionen
- **Table-Driven Tests** als Pattern für effiziente, übersichtliche Tests
- **Mock-basierte Tests** für Unabhängigkeit von Git
- **Integration Tests** für realistische End-to-End-Szenarien

Diese Kombination sorgt für:
- ✅ Schnelle Entwicklung (schnelle Unit Tests)
- ✅ Hohe Qualität (gute Test-Abdeckung)
- ✅ Zuverlässigkeit (Integration Tests fangen Regressions-Fehler)
- ✅ Wartbarkeit (klare, strukturierte Tests)
