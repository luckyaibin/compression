--获取v(0~255)的低 low_bits_count 个bit的值(整数)
function __get_byte_lowbits(v,low_bits_count)
	local mul_factor = 2^(8-low_bits_count);
	local r = math.floor(( v*mul_factor % 255 ) / mul_factor);
	return r;
end
--获取v(0~255)的高 hi_bits_count 个bit的值(整数)
function __get_byte_hibits(v,hi_bits_count)
	local mul_factor = 2^(8-hi_bits_count);
	local r = math.floor( v / mul_factor);
	return r;
end

--dump int v's bit serial
function __dump_bits(v)
	local bits = '';
	local bit_count = 0;
	while(true) do
		local bit = v % 2;
		v = math.floor(v / 2);
		bit_count = bit_count + 1;
		bits =  bit .. bits;
		if bit_count % 4 == 0 then
			bits =  ' ' .. bits;
		end
		if v <=0 then
			break;
		end
	end
	--print('bit stream:',bits);
	return bits,bit_count;
end

luastream = {len = 0;data = ''};
luastream.__index = luastream;

function luastream:new(data)
	local self = {};
	setmetatable(self,luastream);
	self.data = data or '';
	self.len = string.len(self.data);
	return self;
end

function luastream:get_len()
	return self.len;
end

--以16进制输出stream
function luastream:dump_hex()
	local hex_stream = '';
	for i=1,self.len do
		hex_stream = hex_stream .. string.format("%0x",string.byte(self.data,i));
	end
	return hex_stream;
end

function luastream:dump_binary()
	return __dump_bits(self.data);
end

--start from 0 [ 0 1 2 3 4 5 6 7 , 8 9 10 ... ]
--获取stream里从[i,j]的bits构成的整数值，i，j都是从0开始
function luastream:get_bits_to_int(i,j)
	print(string.len(self.data)*8)
	if i<0 or j < 0 or i>j or j >= string.len(self.data)*8 then
		assert(nil,"invalid i or j");
	end

	local s = math.floor(i / 8) ;
	local s_low_bits = 8 - i % 8;
	local e = math.floor(j / 8);
	local e_hi_bits = j % 8 + 1;
	print(i,j,'param:',s,s_low_bits,e,e_hi_bits);
	local data = '';
	local int = __get_byte_lowbits(string.byte(self.data,s+1),s_low_bits);
	for i=s+2,e do
		int = int * 256 + string.byte(self.data,i);
	end
	if s==e then
		int = __get_byte_hibits(int,e_hi_bits);
	else
		int = int * (2^e_hi_bits) + __get_byte_hibits(string.byte(self.data,e+1),e_hi_bits);
	end
	return int
end

--68656c6c6f
local stream1 = luastream:new('hello');
--6869
local stream2 = luastream:new('hi');

--AB02B43AA
function lzw(data)
	print('original:',data);
	print(string.byte(data,1));
end

local data = "ABABABABBBABABAA";
--lzw(data);
