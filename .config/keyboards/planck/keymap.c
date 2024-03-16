#include QMK_KEYBOARD_H


enum planck_layers {
    _QWERTY,
    _NUMBER,
    _SYMBOL,
    _ADJUST,
    _NAVIGATE,
    _GUI_LAYER
};


#define CTRL_ESC   LCTL_T(KC_ESC)
#define MACOS_LCK  LCTL(LGUI(KC_Q))
#define CTRL_LEFT  LCTL(KC_LEFT)
#define CTRL_RGHT  LCTL(KC_RIGHT)
#define CTRL_UP    LCTL(KC_UP)
#define CTRL_DOWN  LCTL(KC_DOWN)
#define CMD_LEFT   LGUI(KC_LEFT)
#define CMD_RGHT   LGUI(KC_RIGHT)
#define CMD_UP     LGUI(KC_UP)
#define CMD_DOWN   LGUI(KC_DOWN)
#define ALT_LEFT   LALT(KC_LEFT)
#define ALT_RGHT   LALT(KC_RIGHT)
#define ALT_UP     LALT(KC_UP)
#define ALT_DOWN   LALT(KC_DOWN)
#define NUMBER     MO(_NUMBER)
#define SYMBOL     MO(_SYMBOL)
#define NAVIGATE   MO(_NAVIGATE)
#define GUI_L      LT(_GUI_LAYER, KC_LBRC)
#define GUI_R      LT(_GUI_LAYER, KC_RBRC)

#define WM_FULL    S(LALT(KC_F))    // Native fullscreen
#define WM_FLOAT   S(LALT(KC_F))    // yabai float
#define WM_NEXT    S(LGUI(KC_C))    // Sends window to next space, and follows it
#define WM_PREV    S(LGUI(KC_Z))    // Sends window to previous space, and follows it
#define WM_SWAPW   S(LALT(KC_H))    // Swap current windows place with window the west
#define WM_SWAPS   S(LALT(KC_J))    // Swap current windows place with window the south
#define WM_SWAPN   S(LALT(KC_K))    // Swap current windows place with window the north
#define WM_SWAPE   S(LALT(KC_L))    // Swap current windows place with window the east
#define WM_MON1    LCTL(LALT(KC_1)) // Focus monitor 1
#define WM_MON2    LCTL(LALT(KC_2)) // Focus monitor 2
#define WM_MON3    LCTL(LALT(KC_3)) // Focus monitor 3
#define WM_SPACE1  LGUI(LALT(KC_1)) // Focus space 1
#define WM_SPACE2  LGUI(LALT(KC_2)) // Focus space 2
#define WM_SPACE3  LGUI(LALT(KC_3)) // Focus space 3
#define WM_SPACE4  LGUI(LALT(KC_4)) // Focus space 4
#define WM_SPACE5  LGUI(LALT(KC_5)) // Focus space 5
#define WM_SND1    S(LGUI(KC_1))    // Send current window to space 1
#define WM_SND2    S(LGUI(KC_2))    // Send current window to space 2
#define WM_SND3    S(LGUI(KC_3))    // Send current window to space 3
#define WM_SND4    S(LGUI(KC_4))    // Send current window to space 4
#define WM_SND5    S(LGUI(KC_5))    // Send current window to space 5

#define WM_N       LALT(LGUI(KC_UP))
#define WM_NE      LCTL(LGUI(KC_RGHT))
#define WM_E       LALT(LGUI(KC_RGHT))
#define WM_SE      S(LCTL(LGUI(KC_RGHT)))
#define WM_S       LALT(LGUI(KC_DOWN))
#define WM_SW      S(LCTL(LGUI(KC_LEFT)))
#define WM_W       LALT(LGUI(KC_LEFT))
#define WM_CNTR    LALT(LGUI(KC_C))



const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

/* Qwerty base layer
 * ,-----------------------------------------------------------------------------------------------------------------------.
 * |   Tab   |    Q    |    W    |    E    |    R    |    T    |    Y    |    U    |    I    |    O    |    P    |  Bksp   |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * | Ctr/Esc |    A    |    S    |    D    |    F    |    G    |    H    |    J    |    K    |    L    |    ;    | Ctrl/'  |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * | Shift/( |    Z    |    X    |    C    |    V    |    B    |    N    |    M    |    ,    |    .    |    /    | Shift/) |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |    [    |   Alt   |   CMD   |   Nav   |   Num   |  Space  |  Enter  | Symbol  |   Nav   |   CMD   |   Alt   |    ]    |
 * `-----------------------------------------------------------------------------------------------------------------------'
 */
[_QWERTY] = LAYOUT_planck_grid(
    KC_TAB,   KC_Q,     KC_W,     KC_E,     KC_R,     KC_T,     KC_Y,     KC_U,     KC_I,     KC_O,     KC_P,     KC_BSPC,
    CTRL_ESC, KC_A,     KC_S,     KC_D,     KC_F,     KC_G,     KC_H,     KC_J,     KC_K,     KC_L,     KC_SCLN,  KC_QUOT,
    KC_LSPO,  KC_Z,     KC_X,     KC_C,     KC_V,     KC_B,     KC_N,     KC_M,     KC_COMM,  KC_DOT,   KC_SLSH,  KC_RSPC,
    GUI_L,    KC_LALT,  KC_LGUI,  NAVIGATE, NUMBER,   KC_SPC,   KC_ENTER, SYMBOL,   NAVIGATE, KC_RGUI,  KC_RALT,  GUI_R 
),

/* Number layer: number row replacement & F keys
 * ,-----------------------------------------------------------------------------------------------------------------------.
 * |         |   F1    |   F2    |   F3    |   F4    |   F5    |   F6    |   F7    |   F8    |   F9    |   F10   |   Del   |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |    1    |    2    |    3    |    4    |    5    |    6    |    7    |    8    |    9    |    0    |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |    -    |    =    |    `    |    \    |         |         |         |         |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |         |         |  Held   |         |         |         |         |         |         |         |
 * `-----------------------------------------------------------------------------------------------------------------------'
 */
[_NUMBER] = LAYOUT_planck_grid(
    _______,  KC_F1,    KC_F2,    KC_F3,    KC_F4,    KC_F5,    KC_F6,    KC_F7,    KC_F8,    KC_F9,    KC_F10,   KC_DEL,
    _______,  KC_1,     KC_2,     KC_3,     KC_4,     KC_5,     KC_6,     KC_7,     KC_8,     KC_9,     KC_0,     _______,
    _______,  KC_MINUS, KC_EQUAL, KC_GRAVE, KC_BSLS,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______
),

/* Symbol layer: shifted versions of number layer & extended F keys
 * ,-----------------------------------------------------------------------------------------------------------------------.
 * |         |   F11   |   F12   |   F13   |   F14   |   F15   |   F16   |   F17   |   F18   |   F19   |   F20   |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |    !    |    @    |    #    |    $    |    %    |    ^    |    &    |    *    |    (    |    )    |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |    _    |    +    |    ~    |    |    |         |         |         |         |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |         |         |         |         |         |  Held   |         |         |         |         |
 * `-----------------------------------------------------------------------------------------------------------------------'
 */
[_SYMBOL] = LAYOUT_planck_grid(
    _______,  KC_F11,   KC_F12,   KC_F13,   KC_F14,   KC_F15,   KC_F16,   KC_F17,   KC_F18,   KC_F19,   KC_F20,   _______,
    _______,  S(KC_1),  S(KC_2),  S(KC_3),  S(KC_4),  S(KC_5),  S(KC_6),  S(KC_7),  S(KC_8),  S(KC_9),  S(KC_0),  _______,
    _______,  KC_UNDS,  KC_PLUS,  KC_TILDE, KC_PIPE,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______
),

/* Adjust (Number + Symbol): keyboard settings and other keys that should not accidentally be hit
 * ,-----------------------------------------------------------------------------------------------------------------------.
 * |         |  Reset  |         |         |         |         |         | LockScr |         |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |         |         |         |         |         | Light-  | Light+  |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |         |         |         |         |         |         |         |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |         |         |  Held   |         |         |  Held   |         |         |         |         |
 * `-----------------------------------------------------------------------------------------------------------------------'
 */
[_ADJUST] = LAYOUT_planck_grid(
    _______,  RESET,    _______,  _______,  _______,  _______,  _______,  MACOS_LCK,_______,  _______,  _______,  _______,
    _______,  _______,  _______,  _______,  _______,  _______,  _______,  BL_DEC,   BL_INC,   _______,  _______,  _______,
    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______
),

/* Navigate: arrow keys and other navigation, either Nav key can be held for this layer
 * ,-----------------------------------------------------------------------------------------------------------------------.
 * |         |   <<    |    >|   |   >>    |         |         |  Mute   |  VolD   |  VolU   |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |  Home   |  PgDn   |  PgUp   |   End   |    ←    |    ↓    |    ↑    |    →    |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |    ⌘←   |   ⌘↓    |   ⌘↑    |    ⌘→   |   ⌥←    |   ⌥↓    |   ⌥↑    |   ⌥→    |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * |         |         |         | (Held)  |         |         |         |         | (Held)  |         |         |         |
 * `-----------------------------------------------------------------------------------------------------------------------'
 */
[_NAVIGATE] = LAYOUT_planck_grid(
    _______,  KC_MPRV,  KC_MPLY,  KC_MNXT,  _______,  _______,  KC_MUTE,  KC_VOLD,  KC_VOLU,  _______,  _______,  _______,
    _______,  _______,  KC_HOME,  KC_PGDN,  KC_PGUP,  KC_END,   KC_LEFT,  KC_DOWN,  KC_UP,    KC_RGHT, _______,  _______,
    _______,  _______,  CMD_LEFT, CMD_DOWN, CMD_UP,   CMD_RGHT,ALT_LEFT, ALT_DOWN, ALT_UP,  ALT_RGHT, _______,  _______,
    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______
),

/* GUI: window management, and mouse keys, either GUI key can be held for ths layer
 * ,-----------------------------------------------------------------------------------------------------------------------.
 * | LockScr | Ms Btn2 |  Ms Up  | Ms Btn1 |  Ms WU  | FullScr |   Mon1  |   Mon2  |   Mon3  |         |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|---------|
 * |         | Ms Left |  Ms Dn  | Ms Right|  Ms WD  |  Next   |  SwapW  |  SwapS  |  SwapN  |  SwapE  |         |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|---------|
 * |         |  Undo   |   Cut   |  Copy   |  Paste  |  Prev   |  Send1  |  Send2  |  Send3  |  Send4  |  Send5  |         |
 * |---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------+---------|
 * | (Held)  |         |         |         |         |         | Space1  | Space2  | Space3  | Space4  | Space5  | (Held)  |
 * `-----------------------------------------------------------------------------------------------------------------------'
 */

[_GUI_LAYER] = LAYOUT_planck_grid(
    MACOS_LCK,KC_BTN2,  KC_MS_U,  KC_BTN1,  KC_WH_U,  WM_FULL,  WM_MON1,  WM_MON2,  WM_MON3,  _______, _______,  _______,
    _______,  KC_MS_L,  KC_MS_D,  KC_MS_R,  KC_WH_D,  WM_NEXT,  WM_SWAPW, WM_SWAPS, WM_SWAPN, WM_SWAPE, _______, _______,
    _______,  KC_UNDO,  KC_CUT,   KC_COPY,  KC_PSTE,  WM_PREV,  WM_SND1,  WM_SND2,  WM_SND3,  WM_SND4,  WM_SND5, _______,
    _______,  _______,  _______,  _______,  _______,  _______,  WM_SPACE1,WM_SPACE2,WM_SPACE3,WM_SPACE4,WM_SPACE5,_______
)

};

layer_state_t layer_state_set_user(layer_state_t state) {
    return update_tri_layer_state(state, _NUMBER, _SYMBOL, _ADJUST);
}


