# Test-Erklärung: Tag Test Beispiel

## Übersicht

Diese Datei erklärt **Schritt für Schritt**, wie ein Testfall in `tag_test.go` funktioniert.

---

## SCHRITT 1: Testdaten definieren (Zeilen 11-17)

```go
type scenario struct {
	testName        string      // Name des Test-Szenarios
	tagName         string      // Input: Tag-Name wie "v1.0.0"
	ref             string      // Input: Commit-Referenz (oder leer)
	force           bool        // Input: Soll Tag erzwungen werden?
	expectedCmdArgs []string    // Expected: Welchen Git-Befehl erwarten wir?
}
```

**Was ist das?**
- Eine **Struktur** die ein Test-Szenario beschreibt
- Enthält **Eingabewerte** (tagName, ref, force)
- Enthält **Erwartete Ausgabe** (expectedCmdArgs)

---

## SCHRITT 2: Test-Szenario erstellen (Zeilen 34-40)

```go
{
	testName:        "create lightweight tag with force flag",
	tagName:         "v1.0.0",
	ref:             "",
	force:           true,
	expectedCmdArgs: []string{"git", "tag", "--force", "--", "v1.0.0"},
}
```

**Bedeutung:**
- **testName**: Beschreibung was wir testen → "Tag mit force-Flag erstellen"
- **tagName**: `"v1.0.0"` → Der Tag soll "v1.0.0" heißen
- **ref**: `""` → Leer = auf aktuellem HEAD (kein spezifischer Commit)
- **force**: `true` → Wir wollen `--force` Flag verwenden
- **expectedCmdArgs**: Der Git-Befehl den wir erwarten:
  ```bash
  git tag --force -- v1.0.0
  ```

---

## SCHRITT 3: Testschleife (Zeile 50-60)

```go
for _, s := range scenarios {
	t.Run(s.testName, func(t *testing.T) {
		// Test-Code hier
	})
}
```

**Was passiert hier?**
- Geht durch **alle** Szenarien (Zeile 50)
- Für jedes Szenario wird ein **eigener Sub-Test** erstellt (Zeile 51)
- `s` ist das aktuelle Szenario

---

## SCHRITT 4: Test-Setup (Zeilen 52-54)

```go
runner := oscommands.NewFakeRunner(t)
gitCommon := buildGitCommon(commonDeps{runner: runner})
tagCommands := NewTagCommands(gitCommon)
```

**Was passiert?**

**Zeile 52:** Erstellt einen **Fake-Runner**
- Das ist ein **Mock-Objekt**
- Führt Git-Befehle NICHT wirklich aus
- Speichert nur welche Befehle aufgerufen wurden

**Zeile 53:** Baut die Git-Common Abhängigkeiten
- Erstellt alle nötigen Objekte
- Nutzt unseren Fake-Runner

**Zeile 54:** Erstellt das TagCommands-Objekt
- Das ist das Objekt das wir testen wollen

---

## SCHRITT 5: Funktion aufrufen (Zeile 56)

```go
cmdObj := tagCommands.CreateLightweightObj(s.tagName, s.ref, s.force)
```

**Konkret für unser Szenario:**
```go
cmdObj := tagCommands.CreateLightweightObj("v1.0.0", "", true)
```

**Was passiert intern?** Schauen wir in `tag.go`:

```go
func (self *TagCommands) CreateLightweightObj(tagName string, ref string, force bool) *oscommands.CmdObj {
	cmdArgs := NewGitCmd("tag").        // Startet mit "git tag"
		ArgIf(force, "--force").         // force=true → fügt "--force" hinzu
		Arg("--", tagName).              // fügt "--" und "v1.0.0" hinzu
		ArgIf(len(ref) > 0, ref).        // ref="" → fügt NICHTS hinzu
		ToArgv()                          // Konvertiert zu String-Array
	
	return self.cmd.New(cmdArgs)
}
```

**Schritt-für-Schritt Ausführung:**

1. `NewGitCmd("tag")` → `["git", "tag"]`
2. `ArgIf(true, "--force")` → `["git", "tag", "--force"]` ✅ (weil force=true)
3. `Arg("--", "v1.0.0")` → `["git", "tag", "--force", "--", "v1.0.0"]`
4. `ArgIf(len("") > 0, "")` → Nichts hinzugefügt ❌ (weil ref leer ist)
5. `ToArgv()` → Finales Array: `["git", "tag", "--force", "--", "v1.0.0"]`

**Ergebnis:** `cmdObj` enthält jetzt diesen Befehl

---

## SCHRITT 6: Assertion (Zeile 58)

```go
assert.Equal(t, s.expectedCmdArgs, cmdObj.Args())
```

**Aufschlüsseln:**

```go
assert.Equal(
	t,                      // Test-Kontext
	s.expectedCmdArgs,      // Was wir ERWARTEN
	cmdObj.Args()           // Was wir BEKOMMEN haben
)
```

**Konkret:**
```go
assert.Equal(
	t,
	[]string{"git", "tag", "--force", "--", "v1.0.0"},  // ERWARTET
	[]string{"git", "tag", "--force", "--", "v1.0.0"}   // BEKOMMEN
)
```

**Was macht assert.Equal?**
- Vergleicht beide Arrays Element für Element
- Wenn sie **gleich** sind → ✅ Test besteht
- Wenn sie **unterschiedlich** sind → ❌ Test schlägt fehl

---

## Vollständiger Ablauf für EINEN Testfall

```
┌─────────────────────────────────────────────────────┐
│ 1. Szenario definieren                              │
│    - tagName: "v1.0.0"                             │
│    - ref: ""                                        │
│    - force: true                                    │
│    - expected: ["git", "tag", "--force", "--", "v1.0.0"] │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 2. Test-Setup                                       │
│    - Fake-Runner erstellen (keine echten Git-Cmds) │
│    - TagCommands-Objekt erstellen                  │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 3. Funktion aufrufen                                │
│    tagCommands.CreateLightweightObj("v1.0.0", "", true) │
│                                                     │
│    Intern passiert:                                │
│    ├─ NewGitCmd("tag")          → ["git", "tag"]  │
│    ├─ ArgIf(true, "--force")    → + "--force"     │
│    ├─ Arg("--", "v1.0.0")       → + "--", "v1.0.0" │
│    └─ ArgIf(false, "")          → nichts           │
│                                                     │
│    Ergebnis: ["git", "tag", "--force", "--", "v1.0.0"] │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 4. Vergleichen                                      │
│    Erwartet: ["git", "tag", "--force", "--", "v1.0.0"] │
│    Bekommen: ["git", "tag", "--force", "--", "v1.0.0"] │
│    → GLEICH ✅ Test besteht!                        │
└─────────────────────────────────────────────────────┘
```

---

## Warum ist das gut?

### 1. Testet echte Logik
- Die `ArgIf(force, "--force")` Bedingung wird getestet
- Die `ArgIf(len(ref) > 0, ref)` Bedingung wird getestet

### 2. Leicht zu erweitern
Neues Szenario? Einfach hinzufügen:
```go
{
	testName:        "mein neuer Test",
	tagName:         "v2.0.0",
	ref:             "HEAD~1",
	force:           false,
	expectedCmdArgs: []string{"git", "tag", "--", "v2.0.0", "HEAD~1"},
}
```

### 3. Klare Fehler
Wenn der Test fehlschlägt:
```
Expected: ["git", "tag", "--force", "--", "v1.0.0"]
Got:      ["git", "tag", "--", "v1.0.0"]
```
→ Man sieht sofort: `--force` fehlt!

---

## Zusammenfassung

**Das Grundprinzip:**
1. **Input definieren** (tagName, ref, force)
2. **Erwartete Ausgabe definieren** (expectedCmdArgs)
3. **Funktion aufrufen** mit dem Input
4. **Ausgabe vergleichen** mit der erwarteten Ausgabe

**Table-Driven Tests:**
- Ein Test-Framework
- Mehrere Szenarien in einer Liste
- Alle werden nacheinander durchlaufen
- Jedes Szenario ist ein eigener Sub-Test

**Die Idee:** Wir geben **Input** → rufen **Funktion** auf → vergleichen **Output** mit **erwartetem Ergebnis**.
