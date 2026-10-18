#
# map.c: register, macro and environment names to indices
#

MAPBEG:	con 256;	# the entries reserved for ".x" names

mapdict: ref Dict;
map2 := array[128 * 128] of {* => 0};	# two-character names' indices, 0 if not yet looked up

map(s: string): int
{
	if(s == nil)
		return 0;
	if(len s == 2 && s[0] == '.' && s[1] < 16r80)	# ".x" is 'x'
		return s[1];
	# names of two ASCII characters (eqn's registers and strings, the
	# commonest) kept in a table, not hashed each time
	two := -1;
	if(len s == 2 && s[0] < 16r80 && s[1] < 16r80){
		two = (s[0] << 7) | s[1];
		if(map2[two])
			return map2[two];
	}
	if(mapdict == nil)
		mapdict = dict_make(4096);
	i := dict_idx(mapdict, s);
	if(i < 0){
		dict_put(mapdict, s, 0);
		i = dict_idx(mapdict, s);
		if(MAPBEG + i >= NREGS)
			errdie("troff: increase NREGS\n");
	}
	if(two >= 0)
		map2[two] = MAPBEG + i;
	return MAPBEG + i;
}

map_name(id: int): string
{
	if(id >= MAPBEG)
		return dict_key(mapdict, id - MAPBEG);
	return "." + chr(id);
}
