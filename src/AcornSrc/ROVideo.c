#include <stdint.h>
#include <swis.h>
#include <kernel.h>
#include "platform.h"
#include "ShockBitmap.h"
#include "RO.h"

extern short mode_id;

int screen_y = 480;
int screen_y_div = 2;

extern void video_copy_double(uint8_t *dest, uint8_t *src);
extern void video_copy_640x480(uint8_t *dest, uint8_t *src);

void Plat_Draw()
{
	const uint32_t vdu_variables_in[] = {148, -1};
	uint8_t *screen_addr = 0;

	if (!drawSurface)
		return;

	_swi(OS_ReadVduVariables, _IN(0) | _IN(1), &vdu_variables_in, &screen_addr);

#ifdef RO_DEBUG
//#error debug
	for (int y = 0; y < drawSurface->h; y++)
		memcpy(screen_addr + y*1280, drawSurface->pixels + y*drawSurface->w, drawSurface->w);
#else
	switch (mode_id)
	{
		case 0:
		video_copy_double(screen_addr, drawSurface->pixels);

		break;

		case 1:
		for (int y = 0; y < drawSurface->h; y++)
			memcpy(screen_addr + y*320, drawSurface->pixels + y*drawSurface->w, drawSurface->w);
		break;

		case 2:
		for (int y = 0; y < drawSurface->h; y++)
			memcpy(screen_addr + y*640, drawSurface->pixels + y*drawSurface->w, drawSurface->w);
		break;

		case 3:
		video_copy_640x480(screen_addr, drawSurface->pixels);
		break;

		case 4:
		for (int y = 0; y < drawSurface->h; y++)
			memcpy(screen_addr + y*1024, drawSurface->pixels + y*drawSurface->w, drawSurface->w);
		break;
	}
#endif
//	memcpy(screen_addr, drawSurface->pixels, drawSurface->w * drawSurface->h);
}

void Plat_Set_Palette(Plat_Palette *palette)
{
	uint32_t ro_pal[256];
	for (int i = 0; i < 256; i++)
		ro_pal[i] = (palette[i].r << 8) | (palette[i].g << 16) | (palette[i].b << 24);

	_swi(ColourTrans_WritePalette, _INR(0, 4), -1, -1, ro_pal, 0, 0);
}

void Plat_InitVideo()
{
	const uint8_t cursor_off_string[] = {23, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0};

#ifdef RO_DEBUG
	const int32_t mode_1024x768x8[] = {
		1,
//		1024, 768, 3, -1,
		1280, 960, 3, -1,
		0, 128, //ModeFlags
		3, 255, //256 colours
		-1
	};

	_swi(OS_ScreenMode, _INR(0,1), 0, mode_1024x768x8);
//	_kernel_oswrch(22);
	//_kernel_oswrch(28);

	// Text window
	_kernel_oswrch(28);
	_kernel_oswrch(80);
	_kernel_oswrch(119);
	_kernel_oswrch(159);
	_kernel_oswrch(0);
/*	_kernel_oswrch(0);
	_kernel_oswrch(119);
	_kernel_oswrch(127);
	_kernel_oswrch(60);*/

	_kernel_oswrch(17);
	_kernel_oswrch(7);
//	_swi(OS_SetColour, _OUT(0) | _OUT(1), 0, 7);
#else
	const int32_t mode_320x480x8[] = {
		1,
		320, 480, 3, -1,
		0, 128, //ModeFlags
		3, 255, //256 colours
		-1
	};
	const int32_t mode_640x400x8[] = {
		1,
		640, 400, 3, -1,
		0, 128, //ModeFlags
		3, 255, //256 colours
		-1
	};
	const int32_t mode_640x480x8[] = {
		1,
		640, 480, 3, -1,
		0, 128, //ModeFlags
		3, 255, //256 colours
		-1
	};
	const int32_t mode_1024x768x8[] = {
		1,
		1024, 768, 3, -1,
		0, 128, //ModeFlags
		3, 255, //256 colours
		-1
	};

	switch (mode_id)
	{
		case 0:
		_swi(OS_ScreenMode, _INR(0,1), 0, mode_320x480x8);
		screen_y = 200;
		screen_y_div = 4;
		break;
		case 1:
		_swi(OS_ScreenMode, _INR(0,1), 0, mode_320x480x8);
		screen_y = 400;
		screen_y_div = 2;
		break;
		case 2:
		_swi(OS_ScreenMode, _INR(0,1), 0, mode_640x400x8);
		screen_y = 400;
		screen_y_div = 2;
		break;
		case 3:
		_swi(OS_ScreenMode, _INR(0,1), 0, mode_640x480x8);
		screen_y = 480;
		screen_y_div = 2;
		break;
		case 4:
		_swi(OS_ScreenMode, _INR(0,1), 0, mode_1024x768x8);
		screen_y = 768;
		screen_y_div = 1;
		break;
	}
#endif

	for (int i = 0; i < sizeof(cursor_off_string); i++)
		_kernel_oswrch(cursor_off_string[i]);
}

void Plat_CloseVideo()
{
	const int32_t mode_640x480x8[] = {
		1,
		640, 480, 3, -1,
		0, 128, //ModeFlags
		3, 255, //256 colours
		-1
	};

	_swi(OS_ScreenMode, _INR(0,1), 0, mode_640x480x8);
}
