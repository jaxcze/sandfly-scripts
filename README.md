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
| `chatgpt.lua` | ChatGPT | Každá zpráva konverzace je jedna položka uvozená slovem Vy nebo ChatGPT a přečte se celá, i část mimo obrazovku. Odpovědi jsou nadpisy, ovládací prvek čtení Zprávy přechází po všech zprávách; seznamy a tabulky se čtou po řádcích. Vaše fotky mají v nabídce Akce Popsat obrázek a Rozpoznat text na obrázku. Tlačítka pod odpovědí (Kopírovat, Přečíst nahlas, Sdílet, hodnocení, Zdroje, Další akce) se při švihání přeskakují a jsou v nabídce Akce, spolu se Zobrazit celou zprávu (okno, ve kterém jde text číst po řádcích, slovech i znacích). Příkaz Zobrazit poslední zprávu je v SandFly menu. |

## Testovací skripty

Rozpracované skripty jsou ve složce [testovani](testovani). Hlavní zdroj je nenabízí, protože SandFly čte jen soubory přímo ve složce zdroje. Kdo je chce zkoušet, přidá si druhý zdroj:

```
github.com/jaxcze/sandfly-scripts/tree/main/testovani
```

| Skript | Aplikace | Co dělá |
|---|---|---|
| `linkedin.lua` | LinkedIn | Každý příspěvek ve feedu je jedna položka: autor, čas, text, obrázek nebo odkazovaný článek a vaše reakce. Tlačítka uvnitř příspěvku se při švihání přeskakují, reakce, komentáře a přesdílení jsou v nabídce Akce. V nastavení jde zapnout podpis autora a počty reakcí a zvolit, jestli číst celý text, nebo jen začátek. |

## Jak psát skripty

Popis rozhraní je v dokumentu [Writing SandFly scripts](https://github.com/aaron-gh/SandFly/blob/master/docs/scripting.md). Strukturu obrazovky aplikace zjistíte příkazem **Copy screen tree** (Kopírovat strom obrazovky), který jde přidat do SandFly menu v části **Ovládací prvky**.

## Licence

Apache License 2.0, viz [LICENSE](LICENSE).
