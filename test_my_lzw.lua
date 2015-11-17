

function fn_stringSplit(str,split_char)
	local sub_str_tab = {};
	if not (str and split_char) then
		return sub_str_tab;
	end

    while (true) do
        local pos = string.find(str, split_char);
        if not pos then
			if string.len(str) > 0 then
				sub_str_tab[#sub_str_tab + 1] = str;
			end
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end
    return sub_str_tab;
end

function get_next_int(text)
	g_curr_index = g_curr_index or 0;
	g_curr_index=g_curr_index + 1;
	local t = fn_stringSplit(text,',');
	local v = t[g_curr_index];
	--print(' v:::', v)
	if not v then
		g_curr_index = 0;
	end

	return tonumber(v);
end

function get_next_char(plain_text)
	g_curr_char_index = g_curr_char_index or 0;
	g_curr_char_index=g_curr_char_index + 1;
	local c = string.sub(plain_text,g_curr_char_index,g_curr_char_index)
	if c == '' then
		g_curr_char_index = 0;
		return nil;
	end
	return c;
end

function encode(plain_text)
	local codes = {};
	codes['A'] = 65;
	codes['B'] = 66;
	local codes_number = 257;
	local encoded_string = '';
	local pre_str = '';
	local c = get_next_char(plain_text)
	while( true ) do
		if( codes[pre_str .. c] == nil) then --需要添加新的字典元素
			codes[pre_str .. c] = codes_number;
			codes_number = codes_number + 1;

			encoded_string = encoded_string .. codes[pre_str] .. ',';--压缩
			pre_str = c;
		else
			pre_str = pre_str .. c;
		end
		c = get_next_char(plain_text)
		if not c then
			break;
		end
		--print('c::::',c);
	end
	encoded_string = encoded_string .. codes[pre_str]
	return encoded_string
end


function decode(encoded_string)
	local codes = {}
	codes[65] = 'A';
	codes[66] = 'B';
	local codes_number = 257;
	local plain_text = '';
	local pre_str = '';--注意，它保存上一次被解码的字符串
	local i = get_next_int(encoded_string)
	while(true) do
		--print('plain_text:::',plain_text);
		if not codes[i] then --不存在(codes_number 必定是等于i的)
			--添加新条目.这里是lzw的难点！在这里，我们需要做三件事：1是找到codes[i]对应的字符串Z，2是更新字典，3输出codes[i]对应的字符串
			--解码比编码慢一步。因为codes[i]不存在的话,那么codes[i]则刚好是上一步刚添加到字典里的,而上一步被解码(压缩)的字符串是pre_str.也就是当我们遇到Z的第一个字符z0的时候，
			--pre_str + z0 (就是codes[i])被添加到字典,而此后的 z0 + z1,z0 + z1 + z2 ...等都存在于字典里，直到Z后面的某个字符n，使得 Z + n不在字典里，
			--才输出codes[Z]，也就是codes[i]
			--就是说pre_str + z0 = z0 + z1 + ... + zn = Z，所以z0等于pre_str的第一个字符。所以codes[i] = pre_str + string.sub(pre_str,1,1);
			--1找到codes[i]对应的字符串Z，2更新字典，
			codes[codes_number] = pre_str .. string.sub(pre_str,1,1);
			assert(i == codes_number);

			--3输出
			plain_text = plain_text .. codes[codes_number];
			pre_str = codes[codes_number];
			codes_number = codes_number + 1;
		else	--存在
			if pre_str~='' then--前缀不为空，才能新加条目(因为前缀为空的时候是第一次进来,还没有值,需要特殊处理)
				codes[codes_number] = pre_str .. string.sub(codes[i],1,1);--也要添加新条目(为什么code[i]存在，还要添加一个新条目到字典呢？由压缩过程可知:每次输出一个string编码的code时候，都是已经发现了一个不存在的新串new_string=string+x.这里添加到字典里的是上一次生成的新条目)
				--print('添加字典',codes_number,codes[codes_number]);
				codes_number = codes_number + 1;
			end
			plain_text = plain_text .. codes[i];
			pre_str = codes[i];
		end

		i = get_next_int(encoded_string);
		if not i then
			break;
		end
	end
	return plain_text;
end


local data = "ABABABABAA";
local encoded = encode(data)
print(encoded);

local data2 = decode(encoded);
print(data2)

assert(data==data2);



