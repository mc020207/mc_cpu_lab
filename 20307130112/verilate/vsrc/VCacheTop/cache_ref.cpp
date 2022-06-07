#include "mycache.h"
#include "cache_ref.h"

CacheRefModel::CacheRefModel(MyCache *_top, size_t memory_size)
	: top(_top), scope(top->VCacheTop), mem(memory_size)
{
	mem.set_name("ref");
#ifdef REFERENCE_CACHE
	// REFERENCE_CACHE does nothing else
#else
	/**
	 * TODO (Lab3) setup reference model :)
	 */

#endif
}

void CacheRefModel::reset()
{
	log_debug("ref: reset()\n");
	mem.reset();
#ifdef REFERENCE_CACHE
	// REFERENCE_CACHE does nothing else
#else
	/**
	 * TODO (Lab3) reset reference model :)
	 */
	for (int i=0;i<8;i++){
		for(int j=0;j<2;j++){
			meta_valid[i][j]=0;
			meta_dirty[i][j]=0;
			meta_tag[i][j]=0;
		}
	}
	for (int i=0;i<16;i++){
		for (int j=0;j<16;j++){
			data_ram[i][j]=0;
		}
	}

#endif
}

auto CacheRefModel::load(addr_t addr, AXISize size) -> word_t
{
	log_debug("ref: load(0x%lx, %d)\n", addr, 1 << size);
#ifdef REFERENCE_CACHE
	addr_t start = addr / 128 * 128;
	for (int i = 0; i < 16; i++) {
		buffer[i] = mem.load(start + 8 * i);
	}

	return buffer[addr % 128 / 8];
#else
	/**
	 * TODO (Lab3) implement load operation for reference model :)
	 */
	//return mem.load(addr);
	addr_t tag=addr/1024;
	addr_t hash=(addr/128)%8;
	addr_t index=(addr%128)/8;
	auto mask1 = STROBE_TO_MASK[0xf];
	auto mask = (mask1 << 32) | mask1;// only use in writeback
	//if ((addr/2147483648)%2==0) return mem.load(addr);
	if (meta_valid[hash][0]&&meta_tag[hash][0]==tag) return data_ram[hash*2][index];
	if (meta_valid[hash][1]&&meta_tag[hash][1]==tag) return data_ram[hash*2+1][index];
	int replace;
	if (meta_valid[hash][0]==0) replace=0;
	else if (meta_valid[hash][0]==0) replace=1;
	else replace=cnt[hash];
	cnt[hash]=!cnt[hash];
	// log_debug("ref: load(0x%lx, %d)\n", addr, 1 << size);
	if (meta_dirty[hash][replace]){
		for (int i=0;i<16;i++){
			mem.store(meta_tag[hash][replace]*1024+hash*128+8*i,data_ram[hash*2+replace][i],mask);
		}
	}
	for (int i=0;i<16;i++){
		data_ram[hash*2+replace][i]=mem.load(tag*1024+hash*128+8*i);
	}
	meta_valid[hash][replace]=1;
	meta_dirty[hash][replace]=0;
	meta_tag[hash][replace]=tag;
	return data_ram[hash*2+replace][index];
#endif
}

void CacheRefModel::store(addr_t addr, AXISize size, word_t strobe, word_t data)
{

	log_debug("ref: store(0x%lx, %d, %x, \"%016x\")\n", addr, 1 << size, strobe, data);
#ifdef REFERENCE_CACHE
	addr_t start = addr / 128 * 128;
	for (int i = 0; i < 16; i++) {
		buffer[i] = mem.load(start + 8 * i);
	}

	auto mask1 = STROBE_TO_MASK[strobe & 0xf];
	auto mask2 = STROBE_TO_MASK[((strobe) >> 4) & 0xf];
	auto mask = (mask2 << 32) | mask1;
	auto &value = buffer[addr % 128 / 8];
	value = (data & mask) | (value & ~mask);
	mem.store(addr, data, mask);
	return;
#else
	/**
	 * TODO (Lab3) implement store operation for reference model :)
	 */
	
	addr_t tag=addr/1024;
	addr_t hash=(addr/128)%8;
	addr_t index=(addr%128)/8;
	auto mask1 = STROBE_TO_MASK[strobe & 0xf];
	auto mask2 = STROBE_TO_MASK[((strobe) >> 4) & 0xf];
	auto mask = (mask2 << 32) | mask1;
	//return mem.store(addr,data,mask);
	//if(addr/2147483648%2==0){mem.store(addr, data, mask);return ;}
	load(addr,MSIZE8);
	int replace;
	if (meta_valid[hash][0]&&meta_tag[hash][0]==tag) replace=0;
	if (meta_valid[hash][1]&&meta_tag[hash][1]==tag) replace=1;
	data_ram[hash*2+replace][index]=(data&mask)|(data_ram[hash*2+replace][index]&(~mask));
	meta_dirty[hash][replace]=1;
	return ;
	//mem.store(0x0, 0xdeadbeef, 0b1111);
#endif
}

void CacheRefModel::check_internal()
{
	log_debug("ref: check_internal()\n");
#ifdef REFERENCE_CACHE
	/**
	 * the following comes from StupidBuffer's reference model.
	 */
	for (int i = 0; i < 16; i++) {
		asserts(
			buffer[i] == scope->mem[i],
			"reference model's internal state is different from RTL model."
			" at mem[%x], expected = %016x, got = %016x",
			i, buffer[i], scope->mem[i]
		);
	}
#else
	/**
	 * TODO (Lab3) compare reference model's internal states to RTL model :)
	 *
	 * NOTE: you can use pointer top and scope to access internal signals
	 *       in your RTL model, e.g., top->clk, scope->mem.
	 */

#endif
}

void CacheRefModel::check_memory()
{
	log_debug("ref: check_memory()\n");
#ifdef REFERENCE_CACHE
	/**
	 * the following comes from StupidBuffer's reference model.
	 */
	asserts(mem.dump(0, mem.size()) == top->dump(), "reference model's memory content is different from RTL model");
#else
	/**
	 * TODO (Lab3) compare reference model's memory to RTL model :)
	 *
	 * NOTE: you can use pointer top and scope to access internal signals
	 *       in your RTL model, e.g., top->clk, scope->mem.
	 *       you can use mem.dump() and MyCache::dump() to get the full contents
	 *       of both memories.
	 */

#endif
}
