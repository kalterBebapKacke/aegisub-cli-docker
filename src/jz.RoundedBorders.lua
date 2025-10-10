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
            Line.extend(ass, line) -- Populate line table

            -- Create top subtitle layer (text)
            local topLayer = Table.copy(line)
            topLayer.layer = topLayer.layer + 1
            ass:setLine(topLayer, s)

            -- Create bottom subtitle layer (rounded border)
            Line.callBackExpand(ass, line, nil, function(line)
                local bottomLayer = Table.copy(line)

                -- Create bounding box
                local boundingBox = Path(bottomLayer.shape):boundingBox()["assDraw"]
                local extendedBoundingBox = Path(boundingBox):offset(bboxOffset, "miter", "polygon", miterLimit, arcTolerance)

                -- Round bounding box and move it downward
                local roundedPath = Path.RoundingPath(
                    extendedBoundingBox:export(), roundingRadius, false, "Rounded", "Absolute"
                ):move(0, transformY)

                -- Set shape and border color
                bottomLayer.shape = roundedPath:export()

                bottomLayer.tags:insert({ { "c", borderColor } })
                bottomLayer.tags:insert({ { "1a", borderAlpha } })

                return ass:insertLine(bottomLayer, s)
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