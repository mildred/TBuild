#! /usr/bin/env lua
-- See copyright notice at end of file

local args = {...}

-- for k, v in ipairs(args) do
--   print(("%%ARG%d%%\t%s"):format(k, v))
-- end

l = io.read('*l')
while l do
  l = l:gsub("(%%(%u+)(%d+)%%)", function(whole, type, num, arg)
    i = tonumber(num)
    if type == "FILE" then
      local f = assert(io.open(args[i]))
      local content = f:read('*a')
      f:close()
      return content
    elseif type == "FILECENCODE" then
      local f = assert(io.open(args[i]))
      local content = f:read('*a')
      f:close()
      return content:gsub('.', function(char)
	local code = char:byte()
	if char == '\r' then
	  return '\\r'
	elseif char == '\n' then
	  return '\\n"\n"'
	elseif char == '\t' then
	  return '\t'
	elseif char == '"' then
	  return '\\"'
	elseif char == "'" then
	  return "\\'"
	elseif char == "\\" then
	  return "\\\\"
	elseif code < 32 or code > 128 then
	  return ("\\%d"):format(code)
	else
	  return char
	end
      end)
    elseif type == "ARG" then
      return args[i]
    else
      return whole
    end
  end)
  io.write(l, '\n')
  l = io.read('*l')
end

-----------------------------------------------------------------------
-- Copyright (c) 2008 Mildred Ki'Lya <mildred593(at)online.fr>
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
-----------------------------------------------------------------------
-- kate: hl Lua 5.1 Core; indent-width 2; space-indent on; replace-tabs off;
-- kate: tab-width 8; remove-trailing-space on;
