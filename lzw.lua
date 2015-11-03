--��ȡv(0~255)�ĵ� low_bits_count ��bit��ֵ(����)
function __get_byte_lowbits(v,low_bits_count)
	local mul_factor = 2^(8-low_bits_count);
	local r = math.floor(( v*mul_factor % 255 ) / mul_factor);
	return r;
end
--��ȡv(0~255)�ĸ� hi_bits_count ��bit��ֵ(����)
function __get_byte_hibits(v,hi_bits_count)
	local mul_factor = 2^(8-hi_bits_count);
	local r = math.floor( v / mul_factor);
	return r;
end

--dump int v's bit serial
function __dump_binary(v,width)
	width = width or 8;--���ݵĿ�ȣ�Ĭ��Ϊ1�ֽ�Ҳ����8bit
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
	--���ǰ׺��0����֤���������ݵĿ��
	for i=bit_count,width-1 do
		bits =  '0' .. bits;
	end
	return bits;
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

function luastream:get_bit_count()
	return self.bit_count;
end

--��16�������stream
function luastream:dump_hex()
	local hex_stream = '';
	local bytes = math.floor(self.bit_count / 8);
	local left_bits = self.bit_count % 8;
	for i=bytes,1,-1 do
		local start = left_bits + (i-1)*8
		local int = self:__get_bits_to_int(start,start+7);
		hex_stream =  string.format("%0X",int) .. ' ' .. hex_stream ;
	end
	if left_bits>0 then
		local int = self:__get_bits_to_int(0,left_bits-1)
		print('.........',string.format("%0x",int))
		hex_stream = string.format("%0X",int).. ' ' ..hex_stream  ;
	end
	return hex_stream;
end

function luastream:dump_binary()
	local binary_stream = '';
	local bytes = math.floor(self.bit_count / 8);
	local left_bits = self.bit_count % 8;
	for i=bytes,1,-1 do
		local start = left_bits + (i-1)*8
		local int = self:__get_bits_to_int(start,start+7);
		binary_stream = __dump_binary(int) .. ' ' ..  binary_stream;
	end
	if left_bits>0 then
		local int = self:__get_bits_to_int(0,left_bits-1)
		binary_stream =__dump_binary(int,left_bits) .. ' ' .. binary_stream;
	end
	return binary_stream;
end

--start from 0 [ 0 1 2 3 4 5 6 7 , 8 9 10 ... ]
--��ȡstream���[i,j]��bits���ɵ�����ֵ��i��j���Ǵ�0��ʼ
function luastream:__get_bits_to_int(i,j)
	if i<0 or j < 0 or i>j or j >= self.bit_count then
		assert(nil,"invalid i or j");
	end
	local s = math.floor(i / 8) ;
	local s_low_bits = 8 - i % 8;
	local e = math.floor(j / 8);
	local e_hi_bits = j % 8 + 1;
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

--��int����ֵ��ӵ�stream���棬i
function luastream:__push_bits_from_int(int,i,j)
	
end
--�� start(��0��ʼ) ȡ�� bit_count ��bit������������ݵĹ��ɵ�intֵ
function luastream:fetch(start,bit_count)
	return self:__get_bits_to_int(start,start+bit_count-1);
end



--68656c6c6f
local stream1 = luastream:new('hello');
print('hex:',stream1:dump_hex());
print('binary:',stream1:dump_binary());


--AB02B43AA
function lzw(data)
	print('original:',data);
	print(string.byte(data,1));
end

local data = "ABABABABBBABABAA";
--lzw(data);
