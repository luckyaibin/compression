--��ȡv(0~255)�ĵ� low_bits_count ��bit��ֵ(����)
max_safe_int = 9007199254740991;--1F FFFF FFFF FFFF(1 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111)�����������������lua��ܿ��ܲ�����ȷ���бȽϣ����� max_safe_int+1 == max_safe_int+2 Ϊtrue
max_int = 	   9223372036854775807;--0x7FFF FFFF FFFF FFFF
--lua�������ʼ��һ��ֵ������ int = 0x68656c6c6f��������32bit��int��ʼֵ��ֱ�ӱ��0xFFFFFFFF������448378203247 �Ϳ���
--��lua�У����е����ֶ���ת����double���������Զ��� max_int ���ֵ����lua������Ͳ����ڣ�Ҳ����max_int������ 9223372036854775807 �ĸ���������ֵ
--print(9223372036854775807 == 9223372036854775807-1) Ҳ�᷵��true
function __get_byte_lowbits(v,low_bits_count)
	assert(v>=0 and v<=255 and low_bits_count >=0 and low_bits_count<=8);
	local mul_factor = 2^(8-low_bits_count);
	local r = math.floor(( v*mul_factor % 256 ) / mul_factor);
	return r;
end
--��ȡv(0~255)�ĸ� hi_bits_count ��bit��ֵ(����)
function __get_byte_hibits(v,hi_bits_count)
	assert(v>=0 and v<=255 and hi_bits_count >=0 and hi_bits_count<=8);
	local mul_factor = 2^(8-hi_bits_count);
	local r = math.floor( v / mul_factor);
	return r;
end

--��ȡv ��0-255���� [h_index,l_index]  �� [0~7]
function __get_byte_bits(v,h_index,l_index)
	local mul_factor = 2^(h_index);
	local div_factor = 2^(7-l_index);
	local h = math.floor( (v*mul_factor % 256)/mul_factor);
	h = math.floor( h / div_factor);
	return h
end

--�� ��ֵ v �ŵ�string�������ֱ��ת�ַ���
--����16���� 68656c6c6f �ŵ��ַ����ﹹ��'hello'��������'68656c6c6f'
function __number_to_string(v)
	assert(v <= max_safe_int);

end

--�� bit����Ϊ bit_count ���ַ��� data ���ȡ bit i~ j ���ɵ�int
--i��j���Ǵ�0��ʼ  [ 0 1 2 3 4 5 6 7 , 8 9 10 ... ]
function __get_string_bits_to_int_helper(data,bit_count,i,j)
	--52�� max_safe_int��bit ����
	assert(type(data) == "string" 
	and i>=0 andj >= 0 
	and i<j 
	and j < bit_count 
	and (j-i)<=52,"invalid input,check parameter");
	local s = math.floor(i / 8) ;
	local s_low_bits = 8 - i % 8;
	local e = math.floor(j / 8);
	local e_hi_bits = j % 8 + 1;

	--print(s,s_low_bits,e,e_hi_bits,string.byte(data,s+1))
	local int = __get_byte_lowbits(string.byte(data,s+1),s_low_bits);
	for i=s+2,e do
		int = int * 256 + string.byte(data,i);
	end
	if s==e then
		--print('-------',e_hi_bits,int)
		int = __get_byte_hibits(int,e_hi_bits);
	else
		int = int * (2^e_hi_bits) + __get_byte_hibits(string.byte(data,e+1),e_hi_bits);
	end
	--print('int:',int,'bit_count:',bit_count,'i:',i,'j:',j)
	return int
end

--��number���ȡ bit i~ j ���ɵ�int 
--0010 1010 1111 1100
--0123 4567 ...
--i�Ǹ�λbit��j�ǵ�λbit.i��j��0,1,2,3...
function __get_number_bits_to_int_helper(int,bit_count,i,j)
	assert(type(int) == "number" 
	and int <= max_safe_int 
	and i>=0 and j >= 0 
	and i<=j 
	and j < bit_count 
	and (j-i)<=52,"invalid input,check parameter");
	--[[
	--���λ��1
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
	part_int = part_int / (2^(bit_count - j - 1));
	return part_int
end

--dump int v's bit serial
function __dump_binary(v,width)
	assert(type(v)=="number",v ..'not number');
	--print('dump binary:',v);
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
	print('initial data:',data);
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
		local int = __get_string_bits_to_int_helper(self.data,self.bit_count,start,start+7);
		hex_stream =  string.format("%0X",int) .. ' ' .. hex_stream ;
	end
	if left_bits>0 then
		local int = __get_string_bits_to_int_helper(self.data,self.bit_count,0,left_bits-1);
		--print('.........',string.format("%0x",int))
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

--��int����ֵ��ӵ�stream���棬int����ֵ��int_bits_count ����ֵ��bit������Ϊ������ǰ��0��������int�޷���ʾ����
--���� 0010 1010 ���֣�int = 10 1010 ,int_bits_count = 8,
function luastream:__push_bits_from_int(int,int_bits_count)
	assert(type(v) == 'number',v .. 'not number');
	if int > max_safe_int then
		assert(nil,int .. 'int value too big');
	end
	--[ 0 1 2 3 4 5 6 7  8 9 10 11 12 13 14 15]
	local s_int = 0;--int����ʼ�±�
	--appedn to self.data
	while( true ) do 
		local left_bits = self.bit_count % 8;--(8 - self.bit_count % 8)%8;
		local s = math.floor(self.bit_count / 8)) * 8;
	
		local e_int = math.min( s_int + (8-left_bits-1),s_int + int_bits_count-1) ;
		local full_byte;
		if left_bits > 0 then
			--ȡ��dataĩβ��bits
			local str_sub  = __get_string_bits_to_int_helper(self.data,self.bit_count,s,s+left_bits-1);
			local int_sub = __get_number_bits_to_int_helper(int,int_bits_count,s_int,e_int);
			full_byte = str_sub * (2^(8-left_bits)) + int_sub*(2^(8-left_bits-(e_int-s_int+1)));			
		else
			local int_sub = __get_number_bits_to_int_helper(int,int_bits_count,s_int,e_int);
			full_byte = int_sub*(2^(8-(e_int-s_int+1)));
		end
		--���
		self.data = self.data .. string.char(full_byte);
		self.bit_count = self.bit_count + (e_int - s_int + 1);
		s_int = e_int + 1;
		
		if s_int == int_bits_count then --����
			break;
		end
	end
end
	
	

end
--�� start(��0��ʼ) ȡ�� bit_count ��bit������������ݵĹ��ɵ�intֵ
function luastream:fetch(start,bit_count)
	return __get_string_bits_to_int_helper(self.data,self.bit_count,start,start+bit_count-1);
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

print(9007199254740991/256)
--lzw(data);
