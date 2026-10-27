KINGDOM DEFENSE (Godot 4.2+)
1. Rozpakuj ZIP.
2. Uruchom Godota -> Import -> wskaż plik project.godot.
3. Naciśnij F5 (Play).

Sterowanie: LPM - budowa/menu/wybór, PPM lub Esc - anuluj, Spacja - następna fala,
P - pauza, M - dźwięk, F11 (lub przycisk "Ekran F11") - pełny ekran.
Okno można dowolnie powiększać - gra skaluje się razem z nim.
Najedź na wroga, żołnierza lub wieżę, aby zobaczyć statystyki (klik na wroga przypina panel).

POZIOMY
- Ekran wyboru ma stałą siatkę 6 slotów (3x2), bez przewijania. Wolne sloty pokazują "Wkrótce".
  Gdy poziomów będzie więcej niż 6, pojawią się przyciski stron.
- Poziom 3 "Rzeka Mostów": otwarty jest zawsze jeden most; co 20 s (czasu gry) zmienia się na drugi.
  Most nie zamknie się, dopóki wrogowie są na jego zjeździe (od rozwidlenia) lub na samym moście -
  wtedy napis przy moście pokazuje "czeka na wrogów". Wrogowie na rozwidleniu idą otwartym mostem.
- Poziom 4 "Rozdroża": darmowa Wieża Rycerska (pomarańczowa), drugi start od 4. fali (losowy).

Zapis: odblokowane poziomy i checkpoint rozgrywki zapisują się automatycznie
(po każdej wyczyszczonej fali i przy budowie/ulepszaniu między falami; zapamiętywany jest też
stan mostów). Na ekranie wyboru poziomu pojawi się przycisk "Kontynuuj".
Plik zapisu: user://save.cfg

Balans i mapy: słowniki TOWERS, BRANCHES, ENEMIES i LEVELS na górze main.gd.
Czas zmiany mostów: klucz "bridge_period" w poziomie 3.
