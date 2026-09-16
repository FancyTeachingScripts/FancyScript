Mehr Infos unter https://valentin-herrmann.com/demo/

Dieses Repo enthält die Latex-Vorlage für die FancyTeachingScripts mit einer einfachen Demo.

## Vorlage einbinden (Submodul statt Fork)

Bisher wurde dieses Repo für jedes Kursskript geforkt. Änderungen an der Vorlage
mussten dann per Merge in jeden Fork zurückgeholt werden – das erzeugt bei jedem
Abgleich Konflikte, und in der Praxis wurde dadurch monatelang gar nicht mehr
synchronisiert.

Stattdessen wird dieses Repo jetzt als **Submodul unter `template/`** eingebunden:

```bash
git submodule add -b main git@github.com:FancyTeachingScripts/FancyScript.git template
bash template/tools/init-course.sh
```

Es wird nie gemerged, sondern nur ein Commit-Zeiger verschoben – Konflikte sind damit
strukturell ausgeschlossen. Jedes Kursskript pinnt seine eigene Vorlagen-Version, alte
Skripte kompilieren also weiter, auch wenn sich die Vorlage weiterentwickelt.

### Arbeitsablauf

Die Vorlage wird typischerweise *aus einem laufenden Kursskript heraus* verbessert –
mitten in der Stunde, wenn ein Makro-Bug auffällt. Genau das bleibt unverändert
möglich, weil ein Submodul ein echtes, beschreibbares Arbeitsverzeichnis ist:

```bash
# 1. Bug im Makro – direkt an Ort und Stelle beheben, wie bisher:
$EDITOR template/sty/4_Skript.sty
template/tools/build.sh main.tex            # neu bauen, Fix sofort sehen

# 2. Für alle Kurse veröffentlichen:
cd template && git commit -am "fix ..." && git push && cd ..
git add template && git commit -m "bump template"   # Version festhalten

# 3. Ein anderer Kurs übernimmt, wann er will:
git submodule update --remote --merge
```

`init-course.sh` setzt die git-Konfiguration, die diesen Ablauf absichert:
`submodule.template.update merge` (kein detached HEAD, Fixes werden nicht zu
verwaisten Commits) und `push.recurseSubmodules on-demand` (das Submodul wird
zuerst gepusht, der Zeiger verweist nie auf einen unbekannten Commit).

## Aufbau

- `sty/` – die gemeinsamen Pakete; `MainPackage.sty` ist der Einstiegspunkt.
- `tools/gen-main.sh` – erzeugt die 39 Treiberdateien in `main/` aus
  `tools/options.conf` (Optionen × Themes). Diese Dateien werden **generiert und
  nicht mehr eingecheckt** – genau das verhindert, dass sich Tippfehler und
  veraltete Kommentare über 39 fast identische Dateien verteilen.
- `tools/build.sh` – eine Datei bauen. `--draft` = ein einziger TeX-Durchlauf,
  ca. 3× schneller (gemessen 19,7 s statt 56,5 s), aber Querverweise, TOC und
  Beamer-Navigation sind **nicht** konvergiert – nur zum Zwischenschauen.
- `tools/build-parallel.sh` – alle 39 bauen, Parallelität auf `nproc` begrenzt.
- `tools/optimize-frames.sh` – die Animationsbilder verkleinern.
- `tools/init-course.sh` – einmalige git-Konfiguration für ein Kursrepo.
- `.github/workflows/release.yml`, `pr-preview.yml` – **wiederverwendbare**
  Workflows (`workflow_call`). Jedes Kursrepo enthält nur noch einen ~10-zeiligen
  Aufruf, der `website_path` und `commit_label` übergibt. Dieses Repo baut seine
  eigene Demo über denselben Workflow (`template_dir: '.'`).

## Kompilieren

In einem Kursrepo (Vorlage als Submodul unter `template/`):

```
tectonic -Z search-path=. -Z search-path=template -Z search-path=template/sty/moloch \
  -Z continue-on-errors -o build main.tex
```

**Reihenfolge ist wichtig:** `.` muss vor `template` stehen. Dieses Repo hat
(für seine eigene Demo) selbst ein `selected.tex`/`_Skripte`/`_Aufgaben` im
Wurzelverzeichnis – dieselben relativen Pfade wie in jedem Kursrepo. Stünde
`template` zuerst, würde jedes Kursrepo beim Kompilieren die Demo-Inhalte der
Vorlage statt seiner eigenen Inhalte bekommen (genau das ist einmal passiert,
siehe #15). `tools/build.sh` & Co. haben die richtige Reihenfolge bereits fest
eingebaut.

Es muss **keine einzige `\usepackage{sty/...}`-Zeile geändert werden**: Weil das
Wurzelverzeichnis des Suchpfads weiterhin ein `sty/` enthält, lösen alle bisherigen
Pfade unverändert auf.

## Architektur auf einen Blick (für Menschen & LLMs)

- **Modell:** `template/` ist ein Git-Submodul, kein Fork. Nie mergen, nur den
  Commit-Zeiger im Kursrepo bewegen (`git add template && git commit`). Jedes
  Kursrepo pinnt seine eigene Version, alte Skripte bleiben stabil.
- **Suchpfad:** Tectonic löst Inhalte über `-Z search-path` auf (kein `TEXINPUTS`).
  Kursrepo-Pfad **immer vor** `template`-Pfad, s.o.
- **CI:** `release.yml` / `pr-preview.yml` hier sind wiederverwendbare
  (`workflow_call`) Workflows; jedes Kursrepo hat nur einen ~10-zeiligen Aufruf.
  Da jedes Kursrepo aus einem Fork dieses Repos entstand, ist
  `default_workflow_permissions` org-weit `read` – jeder Caller-Workflow braucht
  daher einen expliziten `permissions:`-Block, sonst schlägt der Call mit
  `startup_failure` fehl (kein einzelner Job wird erstellt).
- **PR-Previews:** `comment-on-pr` veröffentlicht PDFs auf dem `previews`-Branch
  und verlinkt sie über `cdn.jsdelivr.net`. jsDelivr ignoriert Query-Strings für
  sein Caching (kein `?v=`-Cachebuster möglich) und cached branch-Inhalte
  stundenlang; deshalb bekommt jeder Commit einen eigenen Dateinamen
  (`<datei>-<sha>.pdf`, `sha` = `github.event.pull_request.head.sha` – **nicht**
  `$GITHUB_SHA`, das ist bei `pull_request`-Events der Merge-Commit, nicht der
  eigentliche PR-Head, siehe #17).

Wer auch seine Skripte [hier](https://github.com/FancyTeachingScripts) gesammelt zur Verfügung stellen möchte, kann mich jederzeit für entsprechende Berechtigungen kontaktieren.
