/*
** Character types.
** Separated from lj_char.h to allow modification of valid Lua indentifier characters.
** Public domain.
*/

#define lj_char_c
#define LUA_CORE

#include "lj_char_lua.h"

uint8_t lj_char_bits_lua[257] = {
    0,
    1,  1,  1,  1,  1,  1,  1,  1,  1,  3,  3,  3,  3,  3,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    2,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
  152,152,152,152,152,152,152,152,152,152,  4,  4,  4,  4,  4,  4,
    4,176,176,176,176,176,176,160,160,160,160,160,160,160,160,160,
  160,160,160,160,160,160,160,160,160,160,160,  4,  4,  4,  4,132,
    4,208,208,208,208,208,208,192,192,192,192,192,192,192,192,192,
  192,192,192,192,192,192,192,192,192,192,192,  4,  4,  4,  4,  1,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128
};

LUALIB_API uint8_t *lj_get_char_bits()
{
	return lj_char_bits_lua + 1;
}