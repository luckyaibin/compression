
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

--start from 0
function luastream:get_bits_to_int(i,j)
	local s = math.floor(i / 8) ;
	local s_low_bits = i % 8;
	local e = math.floor(j / 8);
	local data = '';
	local int = string.sub(self.data,s,s);

end


local stream1 = luastream:new('hello');
local stream2 = luastream:new('hi');

print(stream1:get_len())
print(stream2:get_len());



--AB02B43AA
function lzw(data)
	print('original:',data);
	print(string.byte(data,1));
end

local data = "ABABABABBBABABAA";
--lzw(data);
