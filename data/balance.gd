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

# --- Skalowanie wież z poziomem (1-3) ---
const DMG_PER_LEVEL := 0.5       # +50% obrażeń za każdy poziom
const RANGE_PER_LEVEL := 0.08    # +8% zasięgu
const RATE_PER_LEVEL := 0.1      # -10% czasu przeładowania

# --- Koszty ulepszeń (mnożnik kosztu budowy) ---
const UPGRADE_COST_TO_2 := 0.9
const UPGRADE_COST_TO_3 := 1.3
const BRANCH_COST := 1.8
