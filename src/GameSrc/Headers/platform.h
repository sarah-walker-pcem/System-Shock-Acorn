#include <stdio.h>
#include "mouse.h"

typedef struct Plat_Palette
{
	unsigned char r, g, b, a;
} Plat_Palette;

void Plat_Init();

long Plat_GetTicks();
void Plat_Draw();
void Plat_InitVideo();
void Plat_CloseVideo();
void Plat_InitKeyboard();
void Plat_CloseKeyboard();
void Plat_PollMouse(void (*addMouseEvent)(const ss_mouse_event *ev));
void Plat_PollKeyboard(void (*addKBevent)(const kbs_event *ev));
void Plat_Set_Palette(Plat_Palette *palette);

FILE *plat_fopen(char *fn, char *mode);
