class_name LookPalette
extends RefCounted
## La paleta del mundo "Mundo Impreso" (biblia de arte §4), por función.
##
## Todo color nuevo del mundo sale de aquí. Los colores van en el espacio de
## la pantalla: con luz neutra 1,0 se ven tal cual (ver
## look_globals.gdshaderinc). Lo saturado se reserva para filamentos, textiles
## y luces; nada es negro puro (lo oscuro es tinta índigo o grafito). El cian
## INTERACTION significa "esto se toca o se está construyendo" (§4.8).

# Entorno y diorama (§4.1). El fondo y el resplandor cambian con la hora:
# los pone DayCycle.
const BACKGROUND: String = "141b2d"
const BASE_PRINTED: String = "56689a"
const BASE_BRIM: String = "4a6f9e"
const BASE_SHADOW: String = "05070f"
const BASE_SHADOW_ALPHA: float = 0.6

# Cuarto (§4.2).
const FLOOR_TILE: String = "e8c49c"
const FLOOR_TILE_B: String = "e2bb91"
const FLOOR_GROUT: String = "f2e2cb"
const WALL_WINDOW: String = "bfd8c2"
const WALL_BACK: String = "f2dcbc"
const TRIM: String = "f4ede2"
const DOOR: String = "a8693a"
const DOOR_PANEL: String = "b77a47"
const BRASS: String = "e0b44a"
const WINDOW_ALUMINIUM: String = "dfe4ea"
const WINDOW_BARS: String = "2a2e3a"
const WINDOW_SILL: String = "efe7da"
const CURTAIN: String = "e2a93b"
const CURTAIN_FOLD: String = "c98f2c"

# Materiales de los objetos (§4.3).
const WOOD_LIGHT: String = "d9a066"
const WOOD_MID: String = "b97a48"
const WOOD_DARK: String = "7a4b2e"
const METAL_DARK: String = "2b2f3a"
const METAL_MID: String = "5a6274"
const ALUMINIUM: String = "cfd5dd"
const METAL_BRASS: String = "e0aa45"
const COMPUTER_BEIGE: String = "e6dcc4"
const COMPUTER_BEIGE_WORN: String = "c9bb9a"
const CARDBOARD: String = "c99a62"
const CARDBOARD_DARK: String = "a87a48"
const TAPE: String = "d8b97a"
const CRATE: String = "dca05a"
const CRATE_DARK: String = "a8703a"
const CONCRETE_TILE: String = "cfcac0"
const CONCRETE_GRAIN: String = "b9b3a8"
const FAILED_PIECE: String = "3b3b45"

# Textiles, plantas y decoración (§4.4).
const TIGER_BLANKET: String = "d08a48"
const TIGER_STRIPES: String = "3a2a26"
const TIGER_BELLY: String = "f0d2a0"
const SHEET: String = "f4efe6"
const PILLOW: String = "cfe1f2"
const RUG_BASE: String = "e9dcc0"
const RUG_PATTERN: Array[String] = ["2f8f8a", "c4553b", "2f3a57", "e0a43a"]
const DOORMAT: String = "8a6a4a"
const POUF: String = "3f9e8e"
const PLANTS: Array[String] = ["3f8f4f", "4fa65a", "2f7a45"]
const PLANT_SPROUT: String = "5bb866"
const CLAY_POT: String = "c2683f"
const TIN_CAN: String = "c9ced6"
const PAINT_BUCKET: String = "f2f0ea"
const PAINT_BUCKET_STRIPE: String = "2f8f8f"

# Impresoras (§4.5): cuerpo, acento y detalles de cada familia.
const CUBE_FRAME: String = "2c2f3d"
const CUBE_ACCENT: String = "3f86e0"
const PEI_BED: String = "c99a4e"
const KNOBS: String = "f0c419"
const NOZZLE: String = "e0aa45"
const PRINTER_WHITE: String = "eceef2"
const PRINTER_GREEN: String = "4cbf5a"
const PRINTER_PURPLE: String = "9b5de5"
const VAULT_GRAPHITE: String = "2c2d36"
const VAULT_INSIDE: String = "ffd58a"
const RESIN_BASE: String = "2b2f3a"
const RESIN_LID: String = "f28c28"
const RESIN_LID_ALPHA: float = 0.55
const TITAN_GRAPHITE: String = "34363f"
const TITAN_ORANGE: String = "f28c28"
const TITAN_INSIDE: String = "fff1d6"
const SPOOL_FLANGE: String = "d9dde3"
const SPOOL_HUB: String = "8a8f9c"

# Personaje (§4.6).
const SKIN: String = "e9b48e"
const SKIN_SHADE: String = "dc9f7c"
const HAIR: String = "5c341d"
const HAIR_MID: String = "7d4b2a"
const HAIR_FOLD: String = "3e2414"
const HAIR_SHINE: String = "9a6238"
const HOODIE: String = "3e4250"
const HOODIE_CUFF: String = "2f323d"
const HOODIE_ACCENT: String = "f0a63a"
const DRAWSTRINGS: String = "f4efe4"
const LOGO: Array[String] = ["38d6ff", "2fb3c9", "1f8fae"]
const JEANS: String = "3d5c96"
const JEANS_CUFF: String = "5876b0"
const SHOES: String = "f4f1ea"
const SHOE_SOLE: String = "d9d2c4"
const SHOE_STRIPE: String = "38d6ff"
const EYE_LINE: String = "2a1a22"
const IRIS_TOP: String = "5b3226"
const IRIS_BOTTOM: String = "c07a3e"
const PUPIL: String = "1d1226"
const EYE_SHINE: String = "ffffff"
const BROWS: String = "4a2a18"
const MOUTH: String = "7d3346"
const BLUSH: String = "ff8599"
const BLUSH_ALPHA: float = 0.4
const OUTLINE: String = "1a1830"
const OUTLINE_HAIR: String = "2e180c"

# Luces y efectos (§4.7).
const LAMP: String = "ffb05a"
const LAMP_HALO: String = "ffb35c"
const MONITOR: String = "8fd0ff"
const MONITOR_HALO: String = "6fd3ff"
const LED_STRIP: String = "38d6ff"
const BED_LED: String = "cfeeff"
const BED_LAMP: String = "ffc070"
const STRING_LIGHTS: String = "ffd27a"
const MOON: String = "9db4ff"
const HOT_LAYER: String = "ff8a3d"
const REVEAL_CUT: String = "ff8030"
const REVEAL_PREVIEW: String = "38d0ff"
## Destellos de "pieza lista" (§9.5): el dorado de la guirnalda.
const READY_SPARKLE: String = STRING_LIGHTS

# Interacción (§4.8): marcas del piso, marco de cercanía y destino.
const INTERACTION: String = "38d6ff"
