

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

	for k,v in pairs(codes) do
		print(k,v)
	end
	return encoded_string
end


function decode(encoded_string)
	local codes = {}
	codes[65] = 'A';
	codes[66] = 'B';
	local codes_number = 257;
	local plain_text = '';
	local pre_str = '';
	local i = get_next_int(encoded_string)
	while(true) do
		print('plain_text:::',plain_text);
		if not codes[i] then
			codes[codes_number] = pre_str .. string.sub(pre_str,1,1);--添加新条目

			plain_text = plain_text .. codes[codes_number];
			pre_str = codes[codes_number];
			codes_number = codes_number + 1;
		else
			print('codes[i]',i,codes[i]);
			if pre_str~='' then--前缀不为空，才能新加条目(因为前缀为空的时候是第一次进来,还没有值,需要特殊处理)
				codes[codes_number] = pre_str .. string.sub(codes[i],1,1);--也要添加新条目
				print('添加字典',codes_number,codes[codes_number]);
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
	for k,v in pairs(codes) do
		print(k,v)
	end
	return plain_text;
end


local data = "ABABABABAAAABABABAABAABABABBABABABABAABABABABABABABABABAAABBB";
local encoded = encode(data)
print(encoded);

local data2 = decode(encoded);
print(data2)

assert(data==data2);



