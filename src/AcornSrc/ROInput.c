#include <stdint.h>
#include <swis.h>
#include <kernel.h>
#include <unixlib/local.h>
#include "mouse.h"
#include "kb.h"
#include "keydefs.h"
#include "platform.h"
#include "Modding.h"
#include "movekeys.h"
#include "RO.h"

/*
    short x; // position
    short y;
    uint16_t type; // Event mask, bits defined below
    uint32_t timestamp;
    uchar buttons;
    uchar modifiers; // Added for Mac version
    char pad[4];     // pad to sixteen bytes

                mouseEvent.x = MouseX;
                mouseEvent.y = MouseY;
                mouseEvent.timestamp = mouse_get_time();
                mouseEvent.modifiers = (shifted ? 1 : 0);
                addMouseEvent(&mouseEvent);
*/
extern void SetMouseXY(int mx, int my);
static uint32_t mouse_last_x = 0, mouse_last_y = 0, mouse_last_buttons = 0;
void Plat_PollMouse(void (*addMouseEvent)(const ss_mouse_event *ev))
{
	uint32_t mouse_new_x = 0;
	uint32_t mouse_new_y = 0;
	uint32_t mouse_new_buttons = 0;

	_swi(OS_Mouse, _OUTR(0,2), &mouse_new_x, &mouse_new_y, &mouse_new_buttons);

	if (mouse_new_x != mouse_last_x || mouse_new_y != mouse_last_y) {
		ss_mouse_event ev = {0};

		ev.x = mouse_new_x / 2;
#ifdef RO_DEBUG
		ev.y = 768 - (mouse_new_y / 2);
#else
		ev.y = screen_y - (mouse_new_y / screen_y_div);
		if (ev.y < 0)
			ev.y = 0;
		if (ev.y >= screen_y)
			ev.y = screen_y - 1;
#endif
		ev.type = MOUSE_MOTION;
		ev.buttons = (mouse_last_buttons & 4) ? (1 << MOUSE_LBUTTON) : 0;
		ev.buttons |= (mouse_last_buttons & 1) ? (1 << MOUSE_RBUTTON) : 0;
		ev.timestamp = TickCount(); //Plat_GetTicks();
//INFO("mouse: %u %u %u   %u", ev.x, ev.y, ev.buttons);
		addMouseEvent(&ev);
		SetMouseXY(ev.x, ev.y);

		mouse_last_x = mouse_new_x;
		mouse_last_y = mouse_new_y;
	}
	if ((mouse_new_buttons & 4) != (mouse_last_buttons & 4)) {
		ss_mouse_event ev = {0};

		ev.x = mouse_new_x / 2;
#ifdef RO_DEBUG
		ev.y = 768 - (mouse_new_y / 2);
#else
		ev.y = screen_y - (mouse_new_y / screen_y_div);
		if (ev.y < 0)
			ev.y = 0;
		if (ev.y >= screen_y)
			ev.y = screen_y - 1;
#endif
		ev.type = (mouse_new_buttons & 4) ? MOUSE_LDOWN : MOUSE_LUP;
		ev.buttons = (mouse_new_buttons & 4) ? (1 << MOUSE_LBUTTON) : 0;
		ev.timestamp = TickCount(); //Plat_GetTicks();
//INFO("mouse: lbutton %u %u %u   %u", ev.x, ev.y, ev.buttons, ev.timestamp);
		addMouseEvent(&ev);

		mouse_last_buttons = (mouse_new_buttons & 4) | (mouse_last_buttons & ~4);
	}
	if ((mouse_new_buttons & 1) != (mouse_last_buttons & 1)) {
		ss_mouse_event ev = {0};

		ev.x = mouse_new_x / 2;
#ifdef RO_DEBUG
		ev.y = 768 - (mouse_new_y / 2);
#else
		ev.y = screen_y - (mouse_new_y / screen_y_div);
		if (ev.y < 0)
			ev.y = 0;
		if (ev.y >= screen_y)
			ev.y = screen_y - 1;
#endif
		ev.type = (mouse_new_buttons & 1) ? MOUSE_RDOWN : MOUSE_RUP;
		ev.buttons = (mouse_new_buttons & 1) ? (1 << MOUSE_RBUTTON) : 0;
		ev.timestamp = TickCount(); //Plat_GetTicks();
//INFO("mouse: rbutton %u %u %u", ev.x, ev.y, ev.buttons);
		addMouseEvent(&ev);

		mouse_last_buttons = (mouse_new_buttons & 1) | (mouse_last_buttons & ~1);
	}
}

#define OSByte_DisableEvent 		13
#define OSByte_EnableEvent 		14
#define OSByte_KeyboardScan		129
#define InternalKey_C			82
#define InternalKey_Space		98
#define InternalKey_Up			57
#define InternalKey_Down		41
#define InternalKey_Left		25
#define InternalKey_Right		121
#define InternalKey_W			33
#define InternalKey_A			65
#define InternalKey_S			81
#define InternalKey_D			50
#define InternalKey_F12			29

#define CODE_ESCAPE  0x35

#define NR_KEYS 0x68

static const int ro_event_keys[][2] = {
	CODE_ESCAPE, KEY_ESC,  // Escape
	0x7a, KEY_F1,  // F1
	0x78, KEY_F2,  // F2
	0x63, KEY_F3,  // F3
	0x76, KEY_F4,  // F4
	0x60, KEY_F5,  // F5
	0x61, KEY_F6,  // F6
	0x62, KEY_F7,  // F7
	0x64, KEY_F8,  // F8
	0x65, KEY_F9,  // F9
	0x6d, KEY_F10,  // F10
	0x67, KEY_F11,  // F11
	0x6f, KEY_F12,  // F12
	-1, ' ',  // Print
	-1, ' ',  // Scroll Lock
	-1, KEY_PAUSE,  // Break,

	0x32, '`',
	0x12, '1',
	0x13, '2',
	0x14, '3',
	0x15, '4',
	0x17, '5',
	0x16, '6',
	0x1a, '7',
	0x1c, '8',
	0x19, '9',
	0x1d, '0',
	0x1b, '-',
	0x18, '=',
	-1, '$', // not actually $, but £ is multibyte
	0x33, KEY_BS, // backspace
	-1, ' ', // Insert

	0x73, KEY_HOME, // Home
	0x74, KEY_PGUP, // Page Up
	-1, ' ', // NumLock
	0x4b, '/',
	0x43, '*',
	-1, '#',
	0x30, KEY_TAB, // Tab
	CODE_Q, 'q',
	CODE_W, 'w',
	CODE_E, 'e',
	CODE_R, 'r',
	0x11, 't',
	0x10, 'y',
	0x20, 'u',
	0x22, 'i',
	0x1f, 'o',

	0x23, 'p',
	0x21, '[',
	0x1e, ']',
	0x2a, '\\',
	0x33, KEY_DEL, // Delete
	0x77, KEY_END, // Copy
	0x79, KEY_PGDN, // Page Down
	CODE_KP_HOME, '7',
	CODE_KP_UP, '8',
	CODE_KP_PGUP, '9',
	0x4e, '-',
	0x3b, ' ', // Left Ctrl
	CODE_A, 'a',
	CODE_S, 's',
	CODE_D, 'd',
	0x03, 'f',

	0x05, 'g',
	0x04, 'h',
	CODE_J, 'j',
	-1, 'k',
	0x25, 'l',
	0x29, ';',
	0x2a, '\"',
	CODE_ENTER, KEY_ENTER, // Return
	CODE_KP_LEFT, '4',
	CODE_KP_5, '5',
	CODE_KP_RIGHT, '6',
	0x45, '+',
	0x38, ' ', // Left Shift
	-1, ' ', // unused
	CODE_Z, 'z',
	CODE_X, 'x',

	CODE_C, 'c',
	CODE_V, 'v',
	0xb, 'b',
	0x2d, 'n',
	0x2e, 'm',
	0x2b, ',',
	0x2f, '.',
	0x2c, '/',
	0x3c, ' ', // Right Shift
	CODE_UP, KEY_UP,
	CODE_KP_END, '1',
	CODE_KP_DOWN, '2',
	CODE_KP_PGDN, '3',
	-1, ' ', // Caps Lock
	0x3a, ' ', // Left Alt
	CODE_SPACE, KEY_SPACE,

	0x3d, ' ', // Right Alt
	0x3e, ' ', // Right Ctrl
	CODE_LEFT, KEY_LEFT,
	CODE_DOWN, KEY_DOWN,
	CODE_RIGHT, KEY_RIGHT,
	0x52, '0',
	0x41, '.',
	0x4c, KEY_ENTER  // Enter
};

uint8_t key_state[128] = {0};
static uint8_t old_key_state[128] = {0};

void Plat_PollKeyboard(void (*addKBevent)(const kbs_event *ev))
{
	for (int i = 0; i < NR_KEYS; i++) {
		if (key_state[i] != old_key_state[i]) {
			old_key_state[i] = key_state[i];

			if (ro_event_keys[i][0] != -1)
			{
				kbs_event ev = {0};

	                	ev.code = ro_event_keys[i][0];
	                	ev.ascii = ro_event_keys[i][1];
	                	ev.modifiers = 0;
				ev.state = old_key_state[i] ? KBS_DOWN : KBS_UP;
INFO("Send key: code=%02x ascii=%02x status=%i  i=%u", ev.code, ev.ascii, old_key_state[i], i);
				addKBevent(&ev);

				sshockKeyStates[ev.code] = old_key_state[i] ? KB_MOD_PRESSED : 0;
			}
		}
	}
}

extern void *eventv_handler;
static int key_handler_installed = 0;

void Plat_InitKeyboard()
{
	_swi(OS_Claim, _INR(0, 2), 0x10, &eventv_handler, 0);
	_kernel_osbyte(OSByte_EnableEvent, 11, 0);
	key_handler_installed = 1;
	atexit(Plat_CloseKeyboard);
}

void Plat_CloseKeyboard()
{
	if (key_handler_installed)
	{
		key_handler_installed = 0;
		_kernel_osbyte(OSByte_DisableEvent, 11, 0);
		_swi(OS_Release, _INR(0, 2), 0x10, &eventv_handler, 0);
	}
}
