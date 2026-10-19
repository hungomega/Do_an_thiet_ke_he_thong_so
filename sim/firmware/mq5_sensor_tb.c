#include <stdio.h>
#include <stdlib.h>

#include "i2c_bus.h"
#include "mq5_sensor.h"

// Behavioural ADS1115 behind i2c_frame: address match, register pointer,
// 16-bit config write and a conversion register that returns model_raw.
static int model_present = 1;
static unsigned short model_raw;
static unsigned int ptr, wr_index, rd_index, reading;
static unsigned char cfg[2];
static unsigned int config_writes, release_calls, stops;
static unsigned int last_read_nack;
static unsigned char last_byte;

int i2c_frame(unsigned int value) {
  unsigned int data = value & 0xffu;

  if (value & I2C_STOP) stops++;

  if (value & I2C_READ) {
    last_byte = (unsigned char) (rd_index == 0 ? (model_raw >> 8) : model_raw);
    rd_index++;
    last_read_nack = (value & I2C_NACK) != 0;
    return 1;
  }
  if (value & I2C_START) {
    if (!model_present || (data & 0xfeu) != 0x90u) return 0;
    reading = data & 1u;
    wr_index = 0;
    rd_index = 0;
    return 1;
  }
  if (!model_present || reading) return 0;

  wr_index++;
  if (wr_index == 1) ptr = data;
  if (ptr == 1 && wr_index == 2) cfg[0] = (unsigned char) data;
  if (ptr == 1 && wr_index == 3) {
    cfg[1] = (unsigned char) data;
    config_writes++;
  }
  return 1;
}

void i2c_release(void) { release_calls++; }
unsigned char i2c_last_byte(void) { return last_byte; }
void delay_loop(unsigned int iterations) { (void) iterations; }

static void expect(int condition, const char *label) {
  if (!condition) {
    fprintf(stderr, "%s failed\n", label);
    exit(1);
  }
}

int main(void) {
  unsigned int mv = 0;

  // Conversion maths, including the edges that matter.
  expect(mq5_raw_to_mv(-5) == 0, "negative code clamps to zero");
  expect(mq5_raw_to_mv(0) == 0, "zero code");
  expect(mq5_raw_to_mv(8000) == 1500, "1.0 V at pin is 1.5 V at AO");
  expect(mq5_raw_to_mv(26664) == 4999, "full scale AO about 5 V");

  expect(mq5_level_of(1499) == MQ5_LEVEL_CLEAN, "below warn");
  expect(mq5_level_of(1500) == MQ5_LEVEL_WARN, "at warn");
  expect(mq5_level_of(2499) == MQ5_LEVEL_WARN, "below danger");
  expect(mq5_level_of(2500) == MQ5_LEVEL_DANGER, "at danger");

  // Full transaction against the model.
  model_raw = 8000;
  expect(mq5_read_mv(&mv) == 1, "read acknowledged");
  expect(mv == 1500, "read value");
  expect(config_writes == 1, "config written once");
  expect(cfg[0] == 0xc3 && cfg[1] == 0x83, "config is 0xC383");
  expect(last_read_nack == 1, "last byte NACKed");
  expect(stops == 2, "config and read each end in STOP");
  expect(release_calls == 0, "no release on success");

  model_raw = 0;
  expect(mq5_read_mv(&mv) == 1 && mv == 0, "zero reading");

  // Sensor board absent: no ACK, bus released, output untouched.
  model_present = 0;
  mv = 1234;
  expect(mq5_read_mv(&mv) == 0, "NACK reported");
  expect(mv == 1234, "output untouched on NACK");
  expect(release_calls == 1, "bus released on NACK");

  puts("mq5_sensor_tb: PASS");
  return 0;
}
