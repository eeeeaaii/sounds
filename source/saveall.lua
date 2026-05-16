local project = 0
local project_path = reaper.GetProjectPath("")
local output_dir = project_path .. "/../../"

reaper.ShowMessageBox(output_dir, "output dir", 0);
-- Calculate 4 bars duration from project tempo + time sig
local bpm, bpi = reaper.GetProjectTimeSignature2(project)
local four_bars = (4 * bpi / bpm) * 60  -- seconds
reaper.GetSet_LoopTimeRange(true, false, 0, four_bars, false)

-- Set render bounds to exactly 4 bars from 0
reaper.GetSetProjectInfo(project, "RENDER_STARTPOS", 0, true)
reaper.GetSetProjectInfo(project, "RENDER_ENDPOS", four_bars, true)

-- Render settings
reaper.GetSetProjectInfo_String(project, "RENDER_FILE", output_dir, true)
reaper.GetSetProjectInfo(project, "RENDER_FMT", 0x20000, true)   -- WAV
reaper.GetSetProjectInfo(project, "RENDER_SRATE", 48000, true)
reaper.GetSetProjectInfo(project, "RENDER_STEMS", 1, true)

-- Collect track names and render each
local track_names = {}
local track_count = reaper.CountTracks(project)

for i = 0, track_count - 1 do
  local track = reaper.GetTrack(project, i)
  local _, name = reaper.GetTrackName(track)

  -- Sanitize name for filename
  local safe_name = name:gsub('[^%w_-]', '_'):lower()
  table.insert(track_names, safe_name)

  reaper.SetOnlyTrackSelected(track)
  reaper.GetSetProjectInfo_String(project, "RENDER_PATTERN", safe_name, true)
  reaper.Main_OnCommand(41824, 0)  -- Render (no dialog)
end

-- Build Strudel JSON
local entries = {}
for _, name in ipairs(track_names) do
  table.insert(entries, '  "' .. name .. '": ["' .. name .. '.wav"]')
end

local json = "{\n" .. table.concat(entries, ",\n") .. "\n}"

local f = io.open(output_dir .. "samples.json", "w")
if f then
  f:write(json)
  f:close()
end

reaper.ShowMessageBox(
  "Exported " .. #track_names .. " tracks @ " .. bpm .. "bpm\n4 bars = " .. string.format("%.3f", four_bars) .. "s",
  "Done", 0
)
