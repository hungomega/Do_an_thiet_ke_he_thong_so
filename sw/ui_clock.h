#ifndef UI_CLOCK_H
#define UI_CLOCK_H

// The parts that never change: the title bar, the rule under it and the foot.
// Kept out of the per-second redraw because nothing in them moves.
void ui_draw_frame(void);

void ui_show_time(const unsigned char *time);

// Drawn in place of the time when the registers do not hold valid BCD. Showing
// the digits anyway would present a fault as a reading.
void ui_show_unset(void);

// MQ-5 reading below the date: label, AO in millivolts, a status word and a bar
// of one pixel per 32 mV. level is MQ5_LEVEL_* from mq5_sensor.h.
void ui_show_gas(unsigned int mv, unsigned int level);

// Drawn when the ADS1115 does not acknowledge.
void ui_show_gas_fault(void);

#endif
