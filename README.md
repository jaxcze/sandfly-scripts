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
| `facebook-cz.lua` | Facebook | Česká úprava skriptu Facebook Actions and Skip. Švihnutím nahoru a dolů na příspěvku nebo upozornění se listuje akcemi (To se mi líbí, Zareagovat, Okomentovat, Sdílet, další možnosti, popisy obrázků), poklepáním se vybraná akce spustí. Švihnutí dvěma prsty doprava nebo SandFly+J přeskočí sekce Příběhy, Reels a Lidé, které možná znáte. Autor úpravy: Tomáš Hromádka. |
| `messenger-cz.lua` | Messenger | Každá zpráva v konverzaci je jedna položka: Vy nebo jméno odesílatele, text, fotka, samolepka nebo odkaz (doména a název stránky), souřadnice česky, počet reakcí, jestli byla upravená, čas a jestli ji druhý viděl. Švihání zůstává jako v SandFly; avatary, časy mezi zprávami a tlačítka u zprávy se přeskakují. Ovládací prvek čtení Zprávy přechází po zprávách a konverzaci sám posouvá. V nabídce Akce je Otevřít polohu v mapách (Android nabídne mapové aplikace) a Sdílet polohu (klasický sdílecí dialog), Otevřít odkaz, Zobrazit celou zprávu, Možnosti zprávy (odpovědět, reagovat…), Zobrazit reakce, Přeposlat, To se mi líbí, Přidat reakci, Otevřít profil a telefonní čísla, u fotky Popsat obrázek a Rozpoznat text na obrázku. Příkaz Přejít do pole pro psaní je v SandFly menu a na SandFly+J. Původní skript napsal Tomáš Hromádka, verzi 5 přepsal Jan Balák. |
| `youtube-music.lua` | YouTube, YouTube Music | Úprava skriptu Aarona Hewitta pro YouTube, rozšířená o YouTube Music. Vnořená tlačítka v seznamech (Další akce) se při švihání přeskakují a jsou v nabídce Akce. Klávesové zkratky přehrávače: K pozastavit, J a L posun, šipky hlasitost, M ztlumit, F celá obrazovka, C titulky, Shift+N a Shift+P další a předchozí, I minipřehrávač, číslice 0 až 9 skok na 0 až 90 %. Autor úpravy: Tomáš Hromádka. |
| `linkedin.lua` | LinkedIn | Každý příspěvek ve feedu je jedna položka: autor, čas, text, obrázek nebo odkazovaný článek a vaše reakce. Tlačítka uvnitř příspěvku se při švihání přeskakují, reakce, komentáře a přesdílení jsou v nabídce Akce. V nastavení jde zapnout podpis autora a počty reakcí a zvolit, jestli číst celý text, nebo jen začátek. |
| `coffeelink.lua` | De'Longhi Coffee Link | Posuvníky parametrů nápoje mají název a ohlašují skutečnou hodnotu (160 ml, Silná) místo procent, přečtenou rozpoznáním textu. V nabídce Akce posuvníku je Vybrat hodnotu ze seznamu. Parametry nápoje se otevřou akcí Upravit parametry na detailu nápoje, bez tažení. Tlačítka bez názvu mají popisky, srdíčka a tlačítka Příprava říkají název nápoje, nadpisy jsou označené. Průvodci Vytvořit a Bean Adapt říkají číslo kroku a stav voleb, kolečko mlýnku má úrovně a výběr ze seznamu, tlačítko OK v kroku Příprava upozorní, že spustí přípravu espressa. |
| `cgtransit.lua` | CG Transit | Detail spojení: každý úsek se přečte jako věta (spoj, odjezd, mezizastávky, příjezd, směr) bez znaků z ikonového písma, s nástupištěm a „na znamení“; tarifní pásma a dopravce jde zapnout. Hlavní obrazovka: Odkud a Kam místo „null:“, záložky říkají, která je vybraná, seznam tras se při vstupu ohlásí jménem záložky a oblíbené i úprava trasy jsou v nabídce Akce. |

## Testovací skripty

Rozpracované skripty jsou ve složce [testovani](testovani). Hlavní zdroj je nenabízí, protože SandFly čte jen soubory přímo ve složce zdroje. Kdo je chce zkoušet, přidá si druhý zdroj:

```
github.com/jaxcze/sandfly-scripts/tree/main/testovani
```

Teď tam žádný skript není.

## Jak psát skripty

Popis rozhraní je v dokumentu [Writing SandFly scripts](https://github.com/aaron-gh/SandFly/blob/master/docs/scripting.md). Strukturu obrazovky aplikace zjistíte příkazem **Copy screen tree** (Kopírovat strom obrazovky), který jde přidat do SandFly menu v části **Ovládací prvky**.

## Licence

Apache License 2.0, viz [LICENSE](LICENSE).
