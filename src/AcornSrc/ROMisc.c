#include <stdint.h>
#include <swis.h>
#include <kernel.h>
#include <unixlib/local.h>
#include <signal.h>
#include "mouse.h"
#include "kb.h"
#include "keydefs.h"
#include "platform.h"
#include "Modding.h"
#include "tickcount.h"

char *modding_archive_override = NULL;

long Plat_GetTicks()
{
	uint32_t mono_time;

	_swi(OS_ReadMonotonicTime, _OUT(0), &mono_time);

	return mono_time * 10;
}

static char *shock_dir;

void Plat_Init()
{
	struct sigaction sigint_action;
	char riscos_shock_dir[256];

	if (!_kernel_getenv("SystemShock$Dir", riscos_shock_dir, sizeof(riscos_shock_dir)))
		shock_dir = __unixify_std(riscos_shock_dir, NULL, 0, __RISCOSIFY_FILETYPE_NOTSPECIFIED);

	// Disable SIGINT (Escape)
	sigint_action.sa_handler = SIG_IGN;
	sigaction(SIGINT, &sigint_action, NULL);
}

FILE *plat_fopen(char *fn, char *mode)
{
	char fn2[256];

	sprintf(fn2, "%s/%s", shock_dir, fn);

	return fopen(fn2, mode);
}