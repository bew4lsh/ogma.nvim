local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set({
  hooks = {
    pre_case = function()
      for key in pairs(package.loaded) do
        if key:match("^ogma%.") then
          package.loaded[key] = nil
        end
      end
    end,
  },
})

T["validate()"] = new_set()

T["validate()"]["accepts valid config"] = function()
  local config = require("ogma.config")
  eq(config.validate({ voice = "nova", model = "tts-1", format = "mp3", speed = 1.0, max_chars = 100 }), {})
end

T["validate()"]["rejects invalid voice"] = function()
  local config = require("ogma.config")
  local errors = config.validate({ voice = "nope" })
  eq(#errors, 1)
  eq(errors[1]:find("invalid voice") ~= nil, true)
end

T["validate()"]["rejects invalid model"] = function()
  local config = require("ogma.config")
  local errors = config.validate({ model = "gpt-4" })
  eq(#errors, 1)
  eq(errors[1]:find("invalid model") ~= nil, true)
end

T["validate()"]["rejects invalid format"] = function()
  local config = require("ogma.config")
  local errors = config.validate({ format = "wma" })
  eq(#errors, 1)
  eq(errors[1]:find("invalid format") ~= nil, true)
end

T["validate()"]["accepts boundary speeds"] = function()
  local config = require("ogma.config")
  eq(config.validate({ speed = 0.25 }), {})
  eq(config.validate({ speed = 4.0 }), {})
end

T["validate()"]["rejects speed out of range"] = function()
  local config = require("ogma.config")
  eq(#config.validate({ speed = 0.1 }), 1)
  eq(#config.validate({ speed = 5.0 }), 1)
end

T["validate()"]["rejects non-positive max_chars"] = function()
  local config = require("ogma.config")
  eq(#config.validate({ max_chars = 0 }), 1)
  eq(#config.validate({ max_chars = -1 }), 1)
end

T["validate()"]["collects multiple errors"] = function()
  local config = require("ogma.config")
  local errors = config.validate({ voice = "bad", model = "bad", speed = 0.0 })
  eq(#errors, 3)
end

T["setup()"] = new_set()

T["setup()"]["merges user opts with defaults"] = function()
  local config = require("ogma.config")
  config.setup({ voice = "echo", speed = 2.0 })
  local cfg = config.get()
  eq(cfg.voice, "echo")
  eq(cfg.speed, 2.0)
  eq(cfg.model, "tts-1")
  eq(cfg.format, "mp3")
end

T["setup()"]["notifies on invalid opts"] = function()
  local notified = {}
  local orig = vim.notify
  vim.notify = function(msg, level)
    table.insert(notified, { msg = msg, level = level })
  end

  local config = require("ogma.config")
  config.setup({ voice = "bad" })

  vim.notify = orig
  eq(#notified, 1)
  eq(notified[1].level, vim.log.levels.ERROR)
  eq(notified[1].msg:find("invalid voice") ~= nil, true)
end

T["get()"] = new_set()

T["get()"]["returns api_key from config"] = function()
  local config = require("ogma.config")
  config.setup({ api_key = "sk-test-123" })
  eq(config.get().api_key, "sk-test-123")
end

T["get()"]["falls back to OPENAI_API_KEY env var"] = function()
  local config = require("ogma.config")
  config.setup({})
  local orig = vim.env.OPENAI_API_KEY
  vim.env.OPENAI_API_KEY = "sk-env-456"
  local key = config.get().api_key
  vim.env.OPENAI_API_KEY = orig
  eq(key, "sk-env-456")
end

return T
