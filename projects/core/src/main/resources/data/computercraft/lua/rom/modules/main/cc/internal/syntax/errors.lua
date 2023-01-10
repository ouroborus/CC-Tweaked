--- Various parse errors for Lua code
--
-- @local

local pretty = require "cc.pretty"
local expect = require "cc.expect".expect

local colours = colours or {}

local function annotate(start_pos, end_pos, msg)
    if msg == nil and (type(end_pos) == "string" or type(end_pos) == "table") then
        end_pos, msg = start_pos, end_pos
    end

    expect(1, start_pos, "number")
    expect(2, end_pos, "number")
    expect(3, msg, "string", "table")

    return { tag = "annotate", start_pos = start_pos, end_pos = end_pos, msg = msg }
end

--- Format a string as a non-highlighted block of code.
--
-- @tparam string msg The code to format.
-- @treturn cc.pretty.Doc The formatted code.
local function code(msg) return pretty.text(msg, colours.lightGrey) end

local errors = {}

--[[- A string which ends without a closing quote.

@tparam number start_pos The start position of the string.
@tparam number end_pos The end position of the string.
@tparam string quote The kind of quote (`"` or `'`).
@return The resulting parse error.
]]
function errors.unfinished_string(start_pos, end_pos, quote)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")
    expect(3, quote, "string")

    return {
        "This string is not finished. Are you missing a closing quote (" .. code(quote) .. ")?",
        annotate(start_pos, "String started here."),
        annotate(end_pos, "and expected a closing quote here."),
    }
end

--[[- A string which ends with an escape sequence (so a literal `"foo\`). This
is slightly different from @{unfinished_string}, as we don't want to suggest
adding a quote.

@tparam number start_pos The start position of the string.
@tparam number end_pos The end position of the string.
@tparam string quote The kind of quote (`"` or `'`).
@return The resulting parse error.
]]
function errors.unfinished_string_escape(start_pos, end_pos, quote)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")
    expect(3, quote, "string")

    return {
        "This string is not finished.",
        annotate(start_pos, "String started here."),
        annotate(end_pos, "an escape sequence was started here, but with nothing following it."),
    }
end


--[[- A long string was never finished.

@tparam number start_pos The start position of the long string delimiter.
@tparam number end_pos The end position of the long string delimiter.
@tparam number ;em The length of the long string delimiter, excluding the first `[`.
@return The resulting parse error.
]]
function errors.unfinished_long_string(start_pos, end_pos, len)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")
    expect(3, len, "number")

    return {
        "This string was never finished.",
        annotate(start_pos, end_pos, "String was started here."),
        "We expected a closing delimiter (" .. code("]" .. ("="):rep(len - 1) .. "]") .. ") somewhere after this string was started.",
    }
end

--[[- Malformed opening to a long string (i.e. `[=`).

@tparam number start_pos The start position of the long string delimiter.
@tparam number end_pos The end position of the long string delimiter.
@tparam number len The length of the long string delimiter, excluding the first `[`.
@return The resulting parse error.
]]
function errors.malformed_long_string(start_pos, end_pos, len)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")
    expect(3, len, "number")

    return {
        "Incorrect start of a long string.",
        annotate(start_pos, end_pos, "String was started here."),
        "Tip: If you wanted to start a long string here, add an extra " .. code("[") .. " here.",
    }
end

--[[- Malformed nesting of a long string.

@tparam number start_pos The start position of the long string delimiter.
@tparam number end_pos The end position of the long string delimiter.
@return The resulting parse error.
]]
function errors.nested_long_str(start_pos, end_pos)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")

    return {
        code("[[") .. " cannot be nested inside another " .. code("[[ ... ]]"),
        annotate(start_pos, end_pos, ""),
    }
end

--[[- A malformed numeric literal.

@tparam number start_pos The start position of the number.
@tparam number end_pos The end position of the number.
@return The resulting parse error.
]]
function errors.malformed_number(start_pos, end_pos)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")

    return {
        "This isn't a valid number.",
        annotate(start_pos, end_pos, ""),
        "Numbers must be in one of the following formats: " .. code("123") .. ", "
        .. code("3.14") .. ", " .. code("23e35") .. ", " .. code("0x01AF") .. ".",
    }
end

--[[- A long comment was never finished.

@tparam number start_pos The start position of the long string delimiter.
@tparam number end_pos The end position of the long string delimiter.
@tparam number len The length of the long string delimiter, excluding the first `[`.
@return The resulting parse error.
]]
function errors.unfinished_long_comment(start_pos, end_pos, len)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")
    expect(3, len, "number")

    return {
        "This comment was never finished.",
        annotate(start_pos, end_pos, "Comment was started here."),
        "We expected a closing delimiter (" .. code("]" .. ("="):rep(len - 1) .. "]") .. ") somewhere after this comment was started.",
    }
end

--[[- `&&` was used instead of `and`.

@tparam number start_pos The start position of the token.
@tparam number end_pos The end position of the token.
@return The resulting parse error.
]]
function errors.wrong_and(start_pos, end_pos)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")

    return {
        "Lua uses " .. code('and') ..  " instead of " .. code('&&') .. ".",
        annotate(start_pos, end_pos, "Tip: Replace this with " .. code("and")),
    }
end

--[[- `||` was used instead of `or`.

@tparam number start_pos The start position of the token.
@tparam number end_pos The end position of the token.
@return The resulting parse error.
]]
function errors.wrong_or(start_pos, end_pos)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")

    return {
        "Lua uses " .. code('or') ..  " instead of " .. code('||') .. ".",
        annotate(start_pos, end_pos, "Tip: Replace this with " .. code("or")),
    }
end

--[[- `!=` was used instead of `~=`.

@tparam number start_pos The start position of the token.
@tparam number end_pos The end position of the token.
@return The resulting parse error.
]]
function errors.wrong_ne(start_pos, end_pos)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")

    return {
        "Lua uses " .. code("~=") .. " to check if two values are not equal.",
        annotate(start_pos, end_pos, "Tip: Replace this with " .. code("~=")),
    }
end

--[[- An unexpected character was used.

@tparam number pos The position of this character.
@return The resulting parse error.
]]
function errors.unexpected_character(pos)
    expect(1, pos, "number")
    return {
        "Unexpected character.",
        annotate(pos, "This character isn't usable in Lua code."),
    }
end

--[[- An unexpected character was used.

@tparam number token The token id.
@tparam number start_pos The start position of the token.
@tparam number end_pos The end position of the token.
@return The resulting parse error.
]]
function errors.unexpected_token(token, start_pos, end_pos)
    expect(1, token, "number")
    expect(2, start_pos, "number")
    expect(3, end_pos, "number")

    local tokens = require "cc.internal.syntax.parser".tokens
    if token == tokens.EOF then
        return {
            "Unexpected end of file.",
            annotate(start_pos, end_pos, ""),
        }
    end

    -- TODO: Map token IDs to token names.
    return {
        "Unexpected token.",
        annotate(start_pos, end_pos, "This token wasn't expected at this point."),
    }
end

--[[- `=` was used in an expression context.

@tparam number start_pos The start position of the `=` token.
@tparam number end_pos The end position of the `=` token.
@return The resulting parse error.
]]
function errors.use_double_equals(start_pos, end_pos)
    expect(1, start_pos, "number")
    expect(2, end_pos, "number")

    return {
        "Unexpected " .. code("=") .. " in expression.",
        annotate(start_pos, end_pos, code("=") .. " appears here."),
        "Tip: " .. code("==") .. " is used to check two values are equal.",
    }
end

--[[- `local function` was used with a table identifier.

@tparam number local_start The start position of the `local` token.
@tparam number local_end The end position of the `local` token.
@tparam number dot_start The start position of the `.` token.
@tparam number dot_end The end position of the `.` token.
@return The resulting parse error.
]]
function errors.local_function_dot(local_start, local_end, dot_start, dot_end)
    expect(1, local_start, "number")
    expect(2, local_end, "number")
    expect(3, dot_start, "number")
    expect(4, dot_end, "number")

    return {
        "Cannot use " .. code("local function") .. " with tables.",
        annotate(dot_start, dot_end, code(".") .. " appears here."),
        annotate(local_start, local_end, "Tip: " .. "Try removing the " .. code("local") .. " keyword."), -- TODO: Include the position?
    }
end

--[[- A parenthesised expression was started but not closed.

@tparam number open_start The start position of the opening bracket.
@tparam number open_end The end position of the opening bracket.
@tparam number tok_start The start position of the opening bracket.
@return The resulting parse error.
]]
function errors.unclosed_parens(open_start, open_end, tok_start)
    expect(1, open_start, "number")
    expect(2, open_end, "number")
    expect(3, tok_start, "number")

    -- TODO: Do we want to be smarter here with where we report the error?
    return {
        "Parentheses were not closed.",
        annotate(open_start, open_end, "Parentheses were opened here."),
        annotate(tok_start, "Expected to be closed before here."),
    }
end

--[[- A statement of the form `x.y z`

@tparam number pos The position right after this name.
@return The resulting parse error.
]]
function errors.standalone_name(pos)
    expect(1, pos, "number")

    return {
        "Unexpected symbol after name.",
        annotate(pos, "Did you mean to assign this or call it as a function?"),
    }
end

--[[- A statement of the form `x.y`. This is similar to @{standalone_name}, but
when the next token is on another line.

@tparam number pos The position right after this name.
@return The resulting parse error.
]]
function errors.standalone_name_call(pos)
    expect(1, pos, "number")

    return {
        "Unexpected symbol after variable.",
        annotate(pos + 1, "Expected something before the end of the line."),
        "Tip: Use " .. code("()") .. " to call with no arguments.",
    }
end

return errors
