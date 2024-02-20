local export = {}

local function format_audio_file(filename, qualifiers, count, caption)
	local function repl(key)
		if key == "file" then
			return filename
		elseif key == "caption" then
			if not caption then return "" end
			return "<td rowspan=" .. count .. ">" .. caption .. ":</td>"
		elseif key == "qualifiers" then
			if not qualifiers or not qualifiers[1] then return "" end
			return "<td>" .. require("qualifier").format_qualifier(qualifiers) .. "</td>"
		end
	end
	local template = [=[
<tr>{{{caption}}}
<td class="audiofile">[[File:{{{file}}}|noicon|175px]]</td>
<td class="audiometa" style="font-size: 80%;">([[:File:{{{file}}}|file]])</td>
{{{qualifiers}}}</tr>]=]
	return (mw.ustring.gsub(template, "{{{([a-z0-9_:]+)}}}", repl))
end

--[=[
Meant to be called from a module. `data` is a table containing the following fields:

{
  lang = LANGUAGE_OBJECT,
  audios = {{file = "FILENAME", qualifiers = nil or {"QUALIFIER", "QUALIFIER", ...}}, ...},
  caption = nil or "CAPTION"
}

Here:

* `lang` is a language object.
* `audios` is the list of audio files to display. FILENAME is the name of the audio file without a namespace.
  QUALIFIER is a qualifier string to display after the specific audio file in question, formatted
  using format_qualifier() in [[Module:qualifier]].
* `caption`, if specified, adds a caption before the audio file.
]=]
function export.format_audios(data)
	local audiocats = { data.lang:getCanonicalName() .. " terms with audio links" }
	local rows = { }
	local caption = data.caption

	for _, audio in ipairs(data.audios) do
		local text = format_audio_file(audio.file, audio.qualifiers, #data.audios, caption)
		table.insert(rows, text)
		caption = nil
	end
	
	local function repl(key)
		if key == "rows" then
			return table.concat(rows, "\n")
		end
	end

	local template = [=[
<table class="audiotable" style="vertical-align: middle; display:inline-block; list-style:none;line-height: 1em; border-collapse:collapse;">
{{{rows}}}
</table>
]=]

	local stylesheet = require("TemplateStyles")("audio/styles.css")
	local text = mw.ustring.gsub(template, "{{{([a-z0-9_:]+)}}}", repl)
	local categories = #audiocats > 0 and require("utilities").format_categories(audiocats, data.lang) or ""
	-- remove newlines due to HTML generator bug in MediaWiki(?) - newlines in tables cause list items to not end correctly
	text = mw.ustring.gsub(text, "\n", "")
	return stylesheet .. text .. categories
end

return export