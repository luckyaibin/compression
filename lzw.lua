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
function __dump_binary(v)
	local bits = '';
	local bit_count = 0;
	while(true) do
		local bit = v % 2;
		v = math.floor(v / 2);
		bits =  bit .. bits;
		bit_count = bit_count + 1;
		if v <=0 then
			break;
		end
	end
	--print('bit stream:',bits);
	return bits,bit_count;
end

luastream = {bit_count = 0;data = ''};
luastream.__index = luastream;

function luastream:new(data,bit_count)
	local self = {};
	setmetatable(self,luastream);
	self.data = data or '';
	self.bit_count = bit_count or 8 * string.len(self.data);
	return self;
end

function luastream:get_len()
	return self.bit_count;
end

--以16进制输出stream
function luastream:dump_hex()
	local hex_stream = '';
	local bytes = math.floor(self.bit_count / 8);
	local left_bits = self.bit_count % 8;
	for i=1,bytes do
		hex_stream = hex_stream .. string.format("%0x",string.byte(self.data,i));
	end
	if left_bits>0 then
		local int = self:get_bits_to_int(self.bit_count - left_bits,self.bit_count-1)
		hex_stream = hex_stream .. string.format("%0x",int);
	end
	return hex_stream;
end

function luastream:dump_binary()
	local binary_stream = '';
	local bytes = math.floor(self.bit_count / 8);
	local left_bits = self.bit_count % 8;
	for i=1,bytes do
		binary_stream = binary_stream .. __dump_binary(string.byte(self.data,i));
	end
	if left_bits>0 then
		local int = self:get_bits_to_int(self.bit_count - left_bits,self.bit_count-1)
		binary_stream = binary_stream .. __dump_binary(int);
	end
	local splited_stream = '';
	local cnt = 0;
	for i=string.len(binary_stream),1,-1 do
		splited_stream = string.sub(binary_stream,i,i) .. splited_stream;
		cnt = cnt + 1;
		if cnt % 4 == 0 then
			splited_stream = ' ' .. splited_stream;
		end
	end
	return splited_stream,cnt;
end

--start from 0 [ 0 1 2 3 4 5 6 7 , 8 9 10 ... ]
--获取stream里从[i,j]的bits构成的整数值，i，j都是从0开始
function luastream:get_bits_to_int(i,j)

	if i<0 or j < 0 or i>j or j >= self.bit_count then
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
local stream1 = luastream:new('hello',40);
print('hex:',stream1:dump_hex());
print('binary:',stream1:dump_binary());
--6869
local stream2 = luastream:new('hi');

--AB02B43AA
function lzw(data)
	print('original:',data);
	print(string.byte(data,1));
end

local data = "ABABABABBBABABAA";
--lzw(data);
