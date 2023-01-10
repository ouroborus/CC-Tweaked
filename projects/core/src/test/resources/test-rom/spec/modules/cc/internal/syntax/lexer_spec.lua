describe("cc.internal.syntax.lexer", function()
    local lex_one = require "cc.internal.syntax.lexer".lex_one
    local parser = require "cc.internal.syntax.parser"
    local syntax_helpers = require "modules.cc.internal.syntax.syntax_helpers"

    local function get_name(token)
        for name, tok in pairs(parser.tokens) do
            if tok == token then return name end
        end

        return "?"
    end

    local function tokens(input)
        local pos = 1
        local out = {}

        local context = syntax_helpers.make_context(input)
        context.report = function(msg) out[#out + 1] = msg end
        syntax_helpers.stub_errors(stub)

        while true do
            local token, start, finish = lex_one(context, input, pos)
            if not token then break end

            local start_line, start_col = context.get_pos(start)
            out[#out + 1] = {
                token = get_name(token),
                start = start, start_l = start_line, start_c = start_col,
                finish = finish,
            }
            pos = finish + 1
        end

        return out
    end

    local function dedent(input)
        local indent, rest = input:match("^( *)(.*)")
        return (rest:gsub("\n" .. indent, "\n"))
    end

    describe("comments", function()
        it("lexes basic comments", function()
            expect(tokens(dedent[[
                -- A basic singleline comment comment
                --[ Not a multiline comment
                --[= Also not a multiline comment!
            ]])):same {
                { token = "COMMENT", start  = 1, start_l = 1, start_c = 1, finish = 37 },
                { token = "COMMENT", start = 39, start_l = 2, start_c = 1, finish = 65 },
                { token = "COMMENT", start = 67, start_l = 3, start_c = 1, finish = 100 },
            }
        end)

        it("lexes a comment with no trailing newline", function()
            expect(tokens("--")):same {
                { token = "COMMENT", start = 1, start_l = 1, start_c = 1, finish = 2 },
            }
        end)

        it("lexes multiline comments", function()
            expect(tokens(dedent([===[
                --[[
                    A
                    multiline
                    comment
                ]]
                --[=[  ]==] ]] ]=]
                --[[ ]=]]
            ]===]))):same {
                { token = "COMMENT", start =  1, start_l = 1, start_c = 1, finish = 39 },
                { token = "COMMENT", start = 41, start_l = 6, start_c = 1, finish = 58 },
                { token = "COMMENT", start = 60, start_l = 7, start_c = 1, finish = 68 },
            }
        end)

        it("fails on unfinished comments", function()
            expect(tokens("--[=[\n")):same {
                { "unfinished_long_comment", 1, 5, 2 }, -- We report the error
                { token = "ERROR", start = 1, start_l = 1, start_c = 1, finish = 6 }, -- And return an error token
            }
        end)
    end)
end)
