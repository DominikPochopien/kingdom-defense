class_name Balance
## Ogólne liczby balansu: ekonomia, umiejętności gracza i skalowanie ulepszeń wież.
## Statystyki konkretnych wież i wrogów są w tower_data.gd i enemy_data.gd.

# --- Ekonomia ---
## Jaki ułamek wydanego złota wraca przy sprzedaży wieży.
const SELL_REFUND := 0.6
## Premia za wezwanie fali, gdy poprzednia jeszcze trwa.
const EARLY_BONUS := 25

# --- Umiejętność: Deszcz ognia ---
const FIRE_COOLDOWN := 30.0
const FIRE_STRIKES := 8
const FIRE_SPREAD := 100.0       # promień rozrzutu uderzeń wokół kliknięcia
const FIRE_RADIUS := 60.0        # promień pojedynczego wybuchu
const FIRE_DAMAGE := 50.0        # obrażenia magiczne
const FIRE_FIRST_DELAY := 0.25
const FIRE_DELAY_STEP := 0.17

# --- Umiejętność: Posiłki ---
const REINF_COOLDOWN := 18.0
const REINF_COUNT := 2
const REINF_HP := 70.0
const REINF_DAMAGE := 6.0
const REINF_RADIUS := 110.0
const REINF_LIFETIME := 15.0

# --- Leśni Łucznicy (sprzymierzeńcy na poziomach z "archer_posts") ---
const FOREST_ARCHER_RANGE := 185.0      # jak Łucznicy na 2. poziomie
const FOREST_ARCHER_DAMAGE := 12.0
const FOREST_ARCHER_RELOAD := 0.7
const FOREST_ARCHER_DART_SPEED := 560.0
const FOREST_ARCHER_PERIOD := 20.0      # co ile sekund pojawia się łucznik w każdym z miejsc (poziom może nadpisać: "archer_period")
const FOREST_ARCHER_MAX := 2            # ilu łuczników naraz (= liczba gniazd)
const FOREST_ARCHER_MIN_TIME := 18.0    # ile sekund łucznik zostaje na mapie (losowo od-do)
const FOREST_ARCHER_MAX_TIME := 25.0
const FOREST_ARCHER_FIRST := 4.0        # pierwszy łucznik po tylu sekundach gry

# --- Bohater: Rycerz (poziomy z kluczem "hero") ---
const HERO_HP := 400.0
const HERO_DAMAGE := 16.0               # obrażenia zwykłego ciosu (co 1 s)
const HERO_RANGE := 110.0               # promień szukania wrogów wokół jego posterunku
const HERO_RESPAWN := 15.0
const HERO_REGEN := 8.0                 # HP/s, gdy nie walczy
const HERO_SPIN_COOLDOWN := 10.0        # Obrót: co ile sekund można go użyć
const HERO_SPIN_TIME := 3.0             # jak długo się kręci
const HERO_SPIN_TICK := 0.5             # co ile sekund zadaje obrażenia w trakcie obrotu
const HERO_SPIN_DAMAGE := 18.0          # obrażenia jednego trafienia obrotu
const HERO_SPIN_RADIUS := 65.0

# --- Palma z kokosami (poziomy z kluczem "palms") ---
const PALM_FIRST := 8.0                 # pierwsze kokosy najwcześniej po tylu sekundach
const PALM_MIN_TIME := 14.0             # potem co tyle sekund (losowo od-do)
const PALM_MAX_TIME := 19.0
const PALM_DAMAGE := 10.0               # małe obrażenia fizyczne
const PALM_STUN := 3.0                  # ogłuszenie (s)

# --- Ptak z jajkami (poziomy z kluczem "birds") ---
const BIRD_MIN_TIME := 12.0             # co ile sekund przylatuje ptak (losowo od-do)
const BIRD_MAX_TIME := 22.0
const BIRD_SPEED := 150.0
const BIRD_RANGE := 150.0               # jak daleko od ptaka może być wróg trafiony jajkiem
const BIRD_EGG_RELOAD := 1.5
const BIRD_EGG_DAMAGE := 1.0
const BIRD_EGG_SPEED := 240.0

# --- Skalowanie wież z poziomem (1-3) ---
const DMG_PER_LEVEL := 0.5       # +50% obrażeń za każdy poziom
const RANGE_PER_LEVEL := 0.08    # +8% zasięgu
const RATE_PER_LEVEL := 0.1      # -10% czasu przeładowania

# --- Koszty ulepszeń (mnożnik kosztu budowy) ---
const UPGRADE_COST_TO_2 := 0.9
const UPGRADE_COST_TO_3 := 1.3
const BRANCH_COST := 1.8
