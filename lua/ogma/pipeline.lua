local config = require("ogma.config")
local state = require("ogma.state")
local player = require("ogma.player")
local api = require("ogma.api")
local cache = require("ogma.cache")

local M = {}

local function play_cached(path, on_done)
  local handle = vim.fn.jobstart({ "mpv", "--no-video", "--no-terminal", path }, {
    on_exit = function(_, code)
      state.set("idle")
      if on_done then
        on_done(code)
      end
    end,
  })
  if handle <= 0 then
    vim.notify("[ogma.nvim] failed to start mpv for cached file", vim.log.levels.ERROR)
    state.set("idle")
    if on_done then
      on_done(-1)
    end
    return nil
  end
  state.set("playing")
  return handle
end

local function stream_and_play(text, bufnr, on_done)
  local first_chunk = true
  local errored = false
  local cache_chunks = {}
  local mpv_handle = nil

  mpv_handle = player.start(function(code)
    state.set("idle")
    if not errored then
      local audio_data = table.concat(cache_chunks)
      if #audio_data > 0 then
        cache.put(text, bufnr, audio_data)
      end
    end
    if on_done then
      on_done(code)
    end
  end)

  if not mpv_handle then
    state.set("idle")
    if on_done then
      on_done(-1)
    end
    return nil
  end

  state.set("playing")

  local curl_handle = api.stream(text, {
    on_stdout = function(data)
      for _, chunk in ipairs(data) do
        if chunk == "" then
          goto continue
        end

        if first_chunk then
          first_chunk = false
          if chunk:sub(1, 1) == "{" then
            errored = true
            vim.schedule(function()
              local ok, parsed = pcall(vim.json.decode, chunk)
              local msg = ok and parsed.error and parsed.error.message or "API error"
              vim.notify("[ogma.nvim] " .. msg, vim.log.levels.ERROR)
            end)
            player.stop(mpv_handle)
            return
          end
        end

        table.insert(cache_chunks, chunk)
        player.write(mpv_handle, chunk)
        ::continue::
      end
    end,
    on_exit = function()
      if not errored and mpv_handle then
        player.close_stdin(mpv_handle)
      end
    end,
  })

  if not curl_handle then
    player.stop(mpv_handle)
    if on_done then
      on_done(-1)
    end
    return nil
  end

  return { mpv = mpv_handle, curl = curl_handle }
end

function M.speak(text, bufnr, on_done)
  if not text or text == "" then
    if on_done then
      on_done(0)
    end
    return nil
  end

  local cfg = config.get()

  if #text > cfg.max_chars then
    vim.ui.select({ "Yes", "No" }, {
      prompt = string.format("[ogma.nvim] Text is %d chars (limit: %d). Send anyway?", #text, cfg.max_chars),
    }, function(choice)
      if choice == "Yes" then
        M._do_speak(text, bufnr, on_done)
      elseif on_done then
        on_done(0)
      end
    end)
    return nil
  end

  return M._do_speak(text, bufnr, on_done)
end

function M._do_speak(text, bufnr, on_done)
  local cached_path = cache.get(text)
  if cached_path then
    local handle = play_cached(cached_path, on_done)
    return handle and { mpv = handle } or nil
  end
  return stream_and_play(text, bufnr, on_done)
end

return M
