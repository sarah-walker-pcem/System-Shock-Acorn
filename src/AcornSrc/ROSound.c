//#include "Xmi.h"
#include <swis.h>
#include <stdint.h>
#include <string.h>
#include "MusicDevice.h"

static snd_digi_parms digi_parms_by_channel[SND_MAX_SAMPLES];

// Sound stubs that do nothing, when SDL Mixer is not found

int snd_alog_play(int snd_ref, int len, uchar *smp, struct snd_digi_parms *dprm) { return OK; }
void snd_kill_all_samples(void) {}
int MacTuneLoadTheme(char *theme_base, int themeID) { return OK; }
void MacTuneKillCurrentTheme(void) {}
snd_digi_parms *snd_sample_parms(int hnd_id) { return &digi_parms_by_channel[0]; }
void snd_sample_reload_parms(snd_digi_parms *sdp) {}

// Unimplemented sound stubs

void snd_startup(void) {}

#define AUDIO_NUM_CHANNELS 4

struct MixerChunk {
	const uint8_t *data;
	uint32_t len;
	uint16_t loopPos;
	uint16_t loopLen;
};

struct MixerChannel {
	uint8_t active;
	uint8_t volume;
	struct MixerChunk chunk;
	uint32_t chunkPos;
	uint32_t chunkInc;
};

struct MixerChannel mixer_channels[AUDIO_NUM_CHANNELS];

extern void *mixer_arc_callback;
static uint32_t channel_handler_header[4];
uint32_t sound_config_data[5];

extern uint32_t *mixer_debug_1;
extern uint32_t *mixer_debug_2;
extern uint32_t *mixer_debug_3;
extern uint32_t *mixer_debug_4;
extern uint32_t *mixer_debug_5;
volatile int ___x;

int snd_start_digital(void)
{
	//printf("snd_start_digital\n");
	memset(mixer_channels, 0, sizeof(mixer_channels));

	channel_handler_header[0] = (uint32_t)&mixer_arc_callback;
	channel_handler_header[1] = 0;
	channel_handler_header[2] = 0;
	channel_handler_header[3] = 0;

	sound_config_data[0] = AUDIO_NUM_CHANNELS;
	sound_config_data[1] = 256;
	sound_config_data[2] = 48; // 48us, 20833 Hz
	sound_config_data[3] = (uint32_t)channel_handler_header;
	sound_config_data[4] = 0;

	_swi(Sound_Configure, _INR(0, 4) | _OUTR(0, 4),
	      sound_config_data[0],  sound_config_data[1],  sound_config_data[2],  sound_config_data[3],  sound_config_data[4],
	     &sound_config_data[0], &sound_config_data[1], &sound_config_data[2], &sound_config_data[3], &sound_config_data[4]);
	// Old sound config written to sound_config_data[]

	return OK;
}
int snd_stop_digital(void)
{
	_swi(Sound_Configure, _INR(0, 4),
	     sound_config_data[0], sound_config_data[1], sound_config_data[2], sound_config_data[3], sound_config_data[4]);

	return 1;
}

static uint8_t *load_sample(uchar *smp, int *freq, int *length)
{
	const char voc_header[] = "Creative Voice File";

	if (!strncmp(smp, voc_header, 19))
	{
//		printf(".VOC\n");
//		printf("start at %02x%02x\n", smp[0x15], smp[0x14]);

		int p = smp[0x14] | (smp[0x15] << 8);

		while (smp[p] != 0)
		{
			if (smp[p] == 7)
			{
//				printf("block 7\n");
				p++;
				continue;
			}
			int len = smp[p+1] | (smp[p+2] << 8) | (smp[p+3] << 16);
			p += 4;

//			printf("block %u: len %x\n", smp[p-4], len);

			if (smp[p-4] == 1) // Data
			{
				*freq = 1000000 / (256 - smp[p]);
//				printf("freq=%02x %u  %u  %02x\n", smp[p], *freq, 1000000 / smp[p], smp[p+1]);
				*length = len - 2;
				return &smp[p + 2];
			}
			p += len;
		}
	}

	return NULL;
}


int snd_sample_play(int snd_ref, int len, uchar *smp, struct snd_digi_parms *dprm)
{
	for (int channel = 0; channel < AUDIO_NUM_CHANNELS; channel++)
	{
		if (!mixer_channels[channel].active)
		{
//			printf("snd_sample_play: %p %02x %02x %02x %02x\n", smp, smp[0], smp[1], smp[2], smp[3]);
			int freq = 1;
			int length = 1;
			uchar *smp_data = load_sample(smp, &freq, &length);

			struct MixerChannel *ch = &mixer_channels[channel];

			ch->active = false;
			__asm__ volatile("": : :"memory");

//			printf("plat: vol=%x smp_data=%p length=%x freq=%u\n", dprm->vol, smp_data, length, freq);
			ch->volume = dprm->vol >> 2;
			ch->chunk.data = smp_data;
			ch->chunk.len = length;
			ch->chunk.loopPos = 0;
			ch->chunk.loopLen = 0;
			ch->chunkPos = 0;
			ch->chunkInc = (freq << 8) / 20833;

			__asm__ volatile("": : :"memory");
			ch->active = true;

			return channel + 1;
		}
	}
	return OK;
}

int snd_sample_play_raw(int snd_ref, int len, uchar *smp, int freq)
{
	for (int channel = 0; channel < AUDIO_NUM_CHANNELS; channel++)
	{
		if (!mixer_channels[channel].active)
		{
//			printf("snd_sample_play_raw: %p %02x %02x %02x %02x\n", smp, smp[0], smp[1], smp[2], smp[3]);

			struct MixerChannel *ch = &mixer_channels[channel];

			ch->active = false;
			__asm__ volatile("": : :"memory");

//			printf("plat: vol=%x smp_data=%p length=%u freq=%u\n", 0x3f, smp, len, freq);
			ch->volume = 0x3f;
			ch->chunk.data = smp;
			ch->chunk.len = len;
			ch->chunk.loopPos = 0;
			ch->chunk.loopLen = 0;
			ch->chunkPos = 0;
			ch->chunkInc = (freq << 8) / 20833;

			__asm__ volatile("": : :"memory");
			ch->active = true;

			return channel + 1;
		}
	}
	return OK;
}

void snd_end_sample(int hnd_id)
{
	if (hnd_id >= 1 && hnd_id <= AUDIO_NUM_CHANNELS)
		mixer_channels[hnd_id - 1].active = 0;
}

bool snd_sample_playing(int hnd_id)
{
	if (hnd_id >= 1 && hnd_id <= AUDIO_NUM_CHANNELS)
		return mixer_channels[hnd_id - 1].active;

	return false;
}
