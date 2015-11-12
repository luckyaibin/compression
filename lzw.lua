--获取v(0~255)的低 low_bits_count 个bit的值(整数)
max_safe_int = 9007199254740991;--1F FFFF FFFF FFFF(1 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111)大于这个数的整数在lua里很可能不能正确进行比较，比如 max_safe_int+1 == max_safe_int+2 为true
max_int = 	   9223372036854775807;--0x7FFF FFFF FFFF FFFF
--lua代码里初始化一个值，比如 int = 0x68656c6c6f，超过了32bit，int初始值则直接变成0xFFFFFFFF，而用448378203247 就可以
--在lua中，所有的数字都是转化成double来处理，所以对于 max_int 这个值，在lua里根本就不存在！也就是max_int里存的是 9223372036854775807 的浮点数近似值
--print(9223372036854775807 == 9223372036854775807-1) 也会返回true
function __get_byte_lowbits(v,low_bits_count)
	assert(v>=0 and v<=255 and low_bits_count >=0 and low_bits_count<=8);
	local mul_factor = 2^(8-low_bits_count);
	local r = math.floor(( v*mul_factor % 256 ) / mul_factor);
	return r;
end
--获取v(0~255)的高 hi_bits_count 个bit的值(整数)
function __get_byte_hibits(v,hi_bits_count)
	assert(v>=0 and v<=255 and hi_bits_count >=0 and hi_bits_count<=8);
	local mul_factor = 2^(8-hi_bits_count);
	local r = math.floor( v / mul_factor);
	return r;
end

--获取v （0-255）的 [h_index,l_index]  ∈ [0~7]
function __get_byte_bits(v,h_index,l_index)
	local mul_factor = 2^(h_index);
	local div_factor = 2^(7-l_index);
	local h = math.floor( (v*mul_factor % 256)/mul_factor);
	h = math.floor( h / div_factor);
	return h
end

--把 数值 v 放到string里，而不是直接转字符串
--比如16进制 68656c6c6f 放到字符串里构成'hello'，而不是'68656c6c6f'
function __number_to_string(v)
	assert(v <= max_safe_int);

end

--从 bit数量为 bit_count 的字符串 data 里，截取 bit i~ j 构成的int
--i，j都是从0开始  [ 0 1 2 3 4 5 6 7 , 8 9 10 ... ]
function __get_string_bits_to_int_helper(data,bit_count,i,j)
	--52是 max_safe_int的bit 长度
	assert(type(data) == "string"
	and i>=0 and j >= 0
	and i<=j
	and j < bit_count
	and (j-i)<=52,"invalid input,check parameter");
	local s = math.floor(i / 8) ;
	local s_low_bits = 8 - i % 8;
	local e = math.floor(j / 8);
	local e_hi_bits = j % 8 + 1;
	local int = __get_byte_lowbits(string.byte(data,s+1),s_low_bits);
	for i=s+2,e do
		int = int * 256 + string.byte(data,i);
	end
	if s==e then
		int = __get_byte_hibits(int,e_hi_bits);
	else
		int = int * (2^e_hi_bits) + __get_byte_hibits(string.byte(data,e+1),e_hi_bits);
	end
	return int
end

--从number里，截取 bit i~ j 构成的int
--0010 1010 1111 1100
--0123 4567 ...
--i是高位bit，j是低位bit.i、j∈0,1,2,3...
function __get_number_bits_to_int_helper(int,bit_count,i,j)
	assert(type(int) == "number"
	and int <= max_safe_int
	and i>=0 and j >= 0
	and i<=j
	and j < bit_count
	and (j-i)<=52,"invalid input,check parameter");
	--[[
	--最高位的1
	local msb = 0;
	local num = int;
	while(num>0) do
		num = math.floor(num/2);
		msb=msb+1;
	end
	if bit_count < msb then
		bit_count = msb;
	end
	--]]
	--strip higher bits than i
	local part_int = int % (2^(bit_count - i));
	--strip lower bits than j
	part_int = math.floor(part_int / (2^(bit_count - j - 1)));
	return part_int
end

--把int整数值添加到 data 后面，data_bit_count是data的bit数，int 是数值， int_bits_count 是数值的bit数，
--因为可能有前导0，单独用int无法表示出来
--比如 0010 1010 这种，int = 10 1010 ,而int_bits_count = 8,
function __append_bits_from_int(data,data_bit_count,int,int_bits_count)
	assert(type(int) == 'number',int .. 'not number');
	if int > max_safe_int then
		assert(nil,int .. 'int value too big');
	end
	--[ 0 1 2 3 4 5 6 7  8 9 10 11 12 13 14 15]
	local s_int = 0;--int的起始下标
	--appedn to data
	while( true ) do
		local left_bits = data_bit_count % 8;
		local s = math.floor(data_bit_count / 8) * 8;

		local e_int = math.min( s_int + (8-left_bits-1),int_bits_count-1) ;
		local full_byte;
		if left_bits > 0 then
			--取出data末尾的bits
			local str_sub  = __get_string_bits_to_int_helper(data,data_bit_count,s,s+left_bits-1);
			local int_sub = __get_number_bits_to_int_helper(int,int_bits_count,s_int,e_int);
			full_byte = str_sub * (2^(8-left_bits)) + int_sub*(2^(8-left_bits-(e_int-s_int+1)));
		else
			local int_sub = __get_number_bits_to_int_helper(int,int_bits_count,s_int,e_int);
			full_byte = int_sub*(2^(8-(e_int-s_int+1)));
		end
		--添加
		data = data .. string.char(full_byte);
		data_bit_count = data_bit_count + (e_int - s_int + 1);
		s_int = e_int + 1;
		if s_int == int_bits_count then --结束
			break;
		end
	end
	return data,data_bit_count;
end

function __append_bits_from_string(data,data_bit_count,str,str_bits_count)
	assert(type(str) == 'string',str .. 'not string');
	--[ 0 1 2 3 4 5 6 7  8 9 10 11 12 13 14 15]
	local s_int = 0;--int的起始下标
	--appedn to data
	while( true ) do
		local left_bits = data_bit_count % 8;
		local s = math.floor(data_bit_count / 8) * 8;

		local e_int = math.min( s_int + (8-left_bits-1),str_bits_count-1) ;
		local full_byte;
		if left_bits > 0 then
			--取出data末尾的bits
			local str_sub  = __get_string_bits_to_int_helper(data,data_bit_count,s,s+left_bits-1);
			local str_sub2 = __get_string_bits_to_int_helper(str,str_bits_count,s_int,e_int);
			full_byte = str_sub * (2^(8-left_bits)) + str_sub2*(2^(8-left_bits-(e_int-s_int+1)));
		else
			local str_sub2 = __get_string_bits_to_int_helper(str,str_bits_count,s_int,e_int);
			full_byte = str_sub2*(2^(8-(e_int-s_int+1)));
		end
		--添加
		data = data .. string.char(full_byte);
		data_bit_count = data_bit_count + (e_int - s_int + 1);
		s_int = e_int + 1;
		if s_int == str_bits_count then --结束
			break;
		end
	end
	return data,data_bit_count;
end

--dump int v's bit serial
function __dump_binary(v,width)
	assert(type(v)=="number",v ..'not number');
	width = width or 8;--数据的宽度，默认为1字节也就是8bit
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
	--添加前缀的0来保证二进制数据的宽度
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
	print('initial data:',data);
	self.bit_count = bit_count or 8 * string.len(self.data);
	return self;
end

function luastream:get_bit_count()
	return self.bit_count;
end

--以16进制输出stream
function luastream:dump_hex()
	local hex_stream = '';
	local bytes = math.floor(self.bit_count / 8);
	local left_bits = self.bit_count % 8;
	for i=bytes,1,-1 do
		local start = left_bits + (i-1)*8
		local int = __get_string_bits_to_int_helper(self.data,self.bit_count,start,start+7);
		hex_stream =  string.format("%0X",int) .. ' ' .. hex_stream ;
	end
	if left_bits>0 then
		local int = __get_string_bits_to_int_helper(self.data,self.bit_count,0,left_bits-1);
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
		local int = __get_string_bits_to_int_helper(self.data,self.bit_count,start,start+7);
		binary_stream = __dump_binary(int) .. ' ' ..  binary_stream;
	end
	if left_bits>0 then
		local int = __get_string_bits_to_int_helper(self.data,self.bit_count,0,left_bits-1);
		binary_stream =__dump_binary(int,left_bits) .. ' ' .. binary_stream;
	end
	return binary_stream;
end

--从 start(从0开始) 取出 bit_count 个bit，返回这段数据的构成的int值
function luastream:fetch(start,bit_count)
	assert(start >= 0 and bit_count > 0 and bit_count <= 53 and start + bit_count-1 < self.bit_count);
	return __get_string_bits_to_int_helper(self.data,self.bit_count,start,start+bit_count-1);
end

function luastream:put(data,data_bit_len)
	if type(data) == 'number' then
		self.data,self.bit_count = __append_bits_from_int(self.data,self.bit_count,data,data_bit_len);
	elseif type(data) == 'string' then
		self.data,self.bit_count = __append_bits_from_string(self.data,self.bit_count,data,data_bit_len);
	end
end


--68656c6c6f
local stream1 = luastream:new('hello');
--print('hex:',stream1:dump_hex());
--print('binary:',stream1:dump_binary());

--stream1:put(string.char(0x6f),8)
--stream1:put(0x6f,8)
--print('hex:',stream1:dump_hex());
--print('binary:',stream1:dump_binary());


--print('1 binary::::', __dump_binary(0x6f));
--print('2 binary::::', __dump_binary(__get_number_bits_to_int_helper(0x6f,6,0,5)));
--AB02B43AA
function lzw(data)
	local codes = {};
	codes['A'] = 65;
	codes['B'] = 66;
	--codes['C'] = 3;
	codes_num = 256;
	local out = '';
	local stream1 = luastream:new(data);
	local bc = stream1:get_bit_count();--ACABCA 
	--A curr_string A 
	--C curr_string AC -> codes['AC'] = 4 curr_string = C
	--A curr_string CA -> codes['CA'] = 5 curr_string = A 
	--B curr_string AB -> codes['AB'] = 6 curr_string = B
	--C curr_string BC -> codes['BC']
	local curr_bc = 0;
	local curr_string = '';
	while(curr_bc < bc) do
		local read_cnt = 8;
		
		local data = stream1:fetch(curr_bc,read_cnt)
		data = string.char(data);

		curr_string = curr_string .. data;
		print('data		111 :::',data)
		print('curr_string	111:::',curr_string,codes[curr_string])
		
		if( not codes[curr_string] ) then--不存在
			
			codes_num = codes_num + 1;
			codes[curr_string] = codes_num;
			
			print('curr_string 22222:::',curr_string)
			 
		 
			out = out .. ',' .. codes[string.sub(curr_string,1,string.len(curr_string)-1)];
			curr_string = data;
		end
		
		curr_bc = curr_bc + read_cnt;
	end
	out = out .. ':' .. codes[curr_string]
	
	print(out)
	
	for k,v in pairs(codes) do 
		print(k,v)
	end
end
local data = "ABBABBBABBA";

lzw(data);
