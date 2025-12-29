script_name = "Create Rounded Border"
script_description = "Creates rounded borders for selected subtitles"
script_version = "0.1.0"
script_author = "Jukizuka"

local haveDepCtrl, DependencyControl = pcall(require, "l0.DependencyControl")

if haveDepCtrl then
    local depCtrl = DependencyControl({
        feed = "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
        { "ILL.ILL" }
    })

    ILL = depCtrl:requireModules()
else
    ILL = require("ILL.ILL")
end


local Ass, Line, Path, Table = ILL.Ass, ILL.Line, ILL.Path, ILL.Table

function CreateRoundedBorders(bboxOffset, roundingRadius, transformY, borderColor, borderAlpha)
    local miterLimit, arcTolerance = 2, 0.25

    return function(sub, sel, activeLine)
        local ass = Ass(sub, sel, activeLine, true)

        for line, s, i, n in ass:iterSel() do
            ass:progressLine(s, i, n)
            Line.extend(ass, line)

            -- duplicate text as top layer
            local topLayer = Table.copy(line)
            topLayer.layer = topLayer.layer + 1
            ass:setLine(topLayer, s)

            -- keep a safe reference to the ORIGINAL subtitle line
            local originalLine = line

            -- build rounded box bottom layer
            Line.callBackExpand(ass, line, nil, function(line)
                local bottom = Table.copy(line)

                ------------------------------------------------------------------
                -- 1. SHAPERY: Bounding box of ASS-drawn text
                ------------------------------------------------------------------
                local bbox = Path(bottom.shape):boundingBox()["assDraw"]

                ------------------------------------------------------------------
                -- 2. SHAPERY: Expand = offset outward (stroke weight)
                --    GUI: Offsetting → Outside stroke, Miter
                ------------------------------------------------------------------
                local expanded =
                Path(bbox):offset(
                    bboxOffset,        -- stroke weight
                    "miter",           -- corner
                    "polygon",         -- stroke alignment / method
                    miterLimit,
                    arcTolerance
                )

                ------------------------------------------------------------------
                -- 3. SHAPERY: Rounded corners (Absolute)
                ------------------------------------------------------------------
                local rounded =
                Path.RoundingPath(
                    expanded:export(),
                                roundingRadius,
                                false,             -- false = ABSOLUTE radius
                                "Rounded",
                                "Absolute"
                )

                ------------------------------------------------------------------
                -- 4. SHAPERY: Transform (X=0, Y=transformY, scale 100%, angle 0)
                ------------------------------------------------------------------
                rounded = rounded:move(0, transformY)

                ------------------------------------------------------------------
                -- 5. RETAIN TEXT POSITION ON SCREEN
                ------------------------------------------------------------------
                local pos = line.tags.pos or { x = 0, y = 0 }
                rounded = rounded:move(pos.x, pos.y)

                ------------------------------------------------------------------
                -- 6. PRESERVE INLINE ALPHA TAGS
                --    Extract \alpha tags from original text and apply to background
                ------------------------------------------------------------------
                -- Keep the original text with its alpha tags for the background
                -- This ensures that parts marked as invisible remain invisible
                bottom.text_stripped = line.text_stripped


                -- Set the shape and styling
                bottom.shape = rounded:export()
                bottom.tags:insert({ { "c",  borderColor } })

                local tagString = bottom.tags.tags
                if string.match(tagString, "\\alpha") or string.match(tagString, "\\[1-4]a") then
                    bottom.tags:insert({ { "1a", "&HFF" } })
                else
                    bottom.tags:insert({ { "1a", borderAlpha } })
                end

                return ass:insertLine(bottom, s)
            end)
        end

        return ass:getNewSelection()
    end
end



function Gui(sub, sel, activeLine)
    local dialogConfig =
    {
        { x = 0, y = 0, width = 1, height = 1, class = "label",   label = "Offset: " },
        { x = 1, y = 0, width = 1, height = 1, class = "intedit", name = "offset" },
        { x = 0, y = 1, width = 1, height = 1, class = "label",   label = "Radius: " },
        { x = 1, y = 1, width = 1, height = 1, class = "intedit", name = "radius" },
        { x = 0, y = 2, width = 1, height = 1, class = "label",   label = "Transform Y: " },
        { x = 1, y = 2, width = 1, height = 1, class = "intedit", name = "transformY" },
        { x = 0, y = 3, width = 1, height = 1, class = "label",   label = "Border Color: " },
        { x = 1, y = 3, width = 1, height = 1, class = "textbox", name = "borderColor",    text = "&H000000&" },
        { x = 0, y = 4, width = 1, height = 1, class = "label",   label = "Border Alpha: " },
        { x = 1, y = 4, width = 1, height = 1, class = "textbox", name = "borderAlpha",    text = "&H00&" }

    }

    local pressed, res = aegisub.dialog.display(dialogConfig)
    if not pressed then aegisub.cancel() end

    return CreateRoundedBorders(res.offset, res.radius, res.transformY, res.borderColor, res.borderAlpha)(sub, sel, activeLine)
end

aegisub.register_macro(script_name, script_description, Gui)