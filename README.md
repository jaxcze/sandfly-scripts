# SandFly skripty

Skripty v jazyce Lua pro odečítač obrazovky [SandFly](https://github.com/aaron-gh/SandFly) pro Android.

*Lua scripts for the SandFly screen reader for Android. The scripts are made for apps set to Czech.*

## Instalace

V nastavení SandFly otevřete **Aplikace** > **Skripty** > **Zdroje skriptů** > **Přidat zdroj** a zadejte:

```
github.com/jaxcze/sandfly-scripts
```

Pak vyberte skript ze seznamu. SandFly bude jednou denně kontrolovat novější verze.

Jednotlivý skript jde nainstalovat i bez přidání zdroje: stáhněte soubor `.lua` a v SandFly zvolte **Aplikace** > **Skripty** > **Importovat skript**, nebo soubor sdílejte do **Install SandFly script**.

Skripty nejsou podepsané od SandFly, instalace proto ukáže „Not signed by SandFly“.

## Skripty

| Skript | Aplikace | Co dělá |
|---|---|---|
| `x-feed.lua` | X (Twitter) | Každý příspěvek ve feedu je jedna položka: přečte se jméno, text, obrázky a videa a čas. Tlačítka uvnitř příspěvku se při švihání přeskakují. Odpovědět, Znovu publikovat, Lajknout, Záložka, Sdílet a Zobrazit profil jsou v nabídce Akce, stejně jako obrázky příspěvku. V nastavení skriptu jde zapnout čtení @jména a počtů odpovědí, repostů a lajků. |

## Jak psát skripty

Popis rozhraní je v dokumentu [Writing SandFly scripts](https://github.com/aaron-gh/SandFly/blob/master/docs/scripting.md). Strukturu obrazovky aplikace zjistíte příkazem **Copy screen tree** (Kopírovat strom obrazovky), který jde přidat do SandFly menu v části **Ovládací prvky**.

## Licence

Apache License 2.0, viz [LICENSE](LICENSE).
