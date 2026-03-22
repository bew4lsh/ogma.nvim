local config = require("ogma.config")
local state = require("ogma.state")
local platform = require("ogma.platform")
local api = require("ogma.api")
local cache = require("ogma.cache")

local M = {}

local function close_handle(h)
  if h and not h:is_closing() then
    h:close()
  end
end

local function play_cached(path, on_done)
  local ipc = platform.ipc_path()
  local handle = vim.fn.jobstart({ "mpv", "--no-video", "--no-terminal", "--input-ipc-server=" .. ipc, path }, {
    on_exit = function(_, code)
      state.set("idle")
      if on_done then
        on_done(code)
      end
    end,
  })
  if handle <= 0 then
    vim.notify("[ogma.nvim] failed to start mpv", vim.log.levels.ERROR)
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
  local ipc = platform.ipc_path()
  local mpv_stdin = vim.uv.new_pipe(false)
  local cache_chunks = {}
  local errored = false
  local first_chunk = true

  local mpv_handle, mpv_pid = vim.uv.spawn("mpv", {
    args = { "--no-video", "--no-terminal", "--input-ipc-server=" .. ipc, "-" },
    stdio = { mpv_stdin, nil, nil },
  }, function(code)
    vim.schedule(function()
      close_handle(mpv_handle)
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
  end)

  if not mpv_handle then
    mpv_stdin:close()
    vim.notify("[ogma.nvim] failed to start mpv", vim.log.levels.ERROR)
    if on_done then
      on_done(-1)
    end
    return nil
  end

  state.set("playing")

  local curl = api.spawn(text)
  if not curl then
    vim.uv.shutdown(mpv_stdin, function()
      close_handle(mpv_stdin)
    end)
    mpv_handle:kill("sigterm")
    if on_done then
      on_done(-1)
    end
    return nil
  end

  vim.uv.read_start(curl.stdout, function(err, data)
    if err or not data then
      vim.uv.read_stop(curl.stdout)
      close_handle(curl.stdout)
      vim.uv.shutdown(mpv_stdin, function()
        close_handle(mpv_stdin)
      end)
      return
    end

    if first_chunk then
      first_chunk = false
      if data:sub(1, 1) == "{" then
        errored = true
        vim.schedule(function()
          local ok, parsed = pcall(vim.json.decode, data)
          local msg = ok and parsed.error and parsed.error.message or "API error"
          vim.notify("[ogma.nvim] " .. msg, vim.log.levels.ERROR)
        end)
        vim.uv.read_stop(curl.stdout)
        close_handle(curl.stdout)
        vim.uv.shutdown(mpv_stdin, function()
          close_handle(mpv_stdin)
        end)
        mpv_handle:kill("sigterm")
        return
      end
    end

    table.insert(cache_chunks, data)
    vim.uv.write(mpv_stdin, data)
  end)

  return { curl = curl.handle, mpv = mpv_handle }
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
