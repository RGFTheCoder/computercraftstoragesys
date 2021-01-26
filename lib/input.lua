return function(_sCensor, _tHistory, _fnAutocomp, _sDefault, _nMaxlen,
                _bPrintAfter, _nStartPos, _fnColorizer)
    local nStartX, nStartY = term.getCursorPos()
    nStartX = nStartX - 1
    nStartY = nStartY - 1
    _sCensor = _sCensor and _sCensor:sub(1, 1) or nil
    _tHistory = _tHistory or {}
    _fnAutocomp = _fnAutocomp or function() end
    _nMaxlen = _nMaxlen or term.getSize() - nStartX
    _bPrintAfter = _bPrintAfter or true
    _fnColorizer = _fnColorizer or
                       function(_sLine, _nPos, _nScroll, _bLast, _sCompletion)
            if _sCompletion then
                return ('0'):rep(#_sLine) .. ('f'):rep(#_sCompletion),
                       ('f'):rep(#_sLine) .. ('7'):rep(#_sCompletion)
            else
                return ('0'):rep(#_sLine), ('f'):rep(#_sLine)
            end
        end

    local sLine = _sDefault or ''
    local nPos = _nStartPos and math.max(1, math.min(#sLine, _nStartPos)) or
                     #sLine
    local nScroll = math.max(0, nPos - _nMaxlen + 1)
    local nMark = nPos
    local bShift = false
    local tCompletions = nil
    local nCompletion = nil
    local nHistoryPos = nil

    local function getMarks()
        local nMarkStart, nMarkEnd

        if nMark ~= nPos then
            if nMark < nPos then
                nMarkStart = nMark
                nMarkEnd = nPos
            else
                nMarkStart = nPos
                nMarkEnd = nMark
            end
        end

        return nMarkStart, nMarkEnd
    end

    local function draw(_bLast)
        local nStartIndex = nScroll + 1
        local nEndIndex = nScroll + _nMaxlen

        local sCensored = _sCensor and _sCensor:rep(#sLine) or sLine
        local sCompletion = ''

        if not _bLast then
            sCompletion = nCompletion and tCompletions[nCompletion] or ''
        end

        sCensored = sCensored .. sCompletion

        if nScroll < nPos - _nMaxlen + math.max(1, sCompletion:len()) then
            nScroll = nPos - _nMaxlen + math.max(1, sCompletion:len())
        end

        local sClippedText = sCensored:sub(nStartIndex, nEndIndex)
        sClippedText = sClippedText ..
                           string.rep(' ', math.max(0, _nMaxlen - #sClippedText))

        local sFg, sBg = _fnColorizer(sLine, nPos, nScroll, _bLast, sCompletion)
        local nMarkStart, nMarkEnd = getMarks()

        if nMarkStart then
            local sOldFg, sOldBg = sFg, sBg

            sFg = sOldFg:sub(1, nMarkStart) ..
                      sOldBg:sub(nMarkStart + 1, nMarkEnd) ..
                      sOldFg:sub(nMarkEnd + 1)
            sBg = sOldBg:sub(1, nMarkStart) ..
                      sOldFg:sub(nMarkStart + 1, nMarkEnd) ..
                      sOldBg:sub(nMarkEnd + 1)
        end

        local sClippedFg = sFg:sub(nStartIndex, nEndIndex)
        local sClippedBg = sBg:sub(nStartIndex, nEndIndex)
        sClippedFg = sClippedFg ..
                         string.rep('0', math.max(0, _nMaxlen - #sClippedFg))
        sClippedBg = sClippedBg ..
                         string.rep('f', math.max(0, _nMaxlen - #sClippedBg))

        term.setCursorPos(nStartX + 1, nStartY + 1)
        term.blit(sClippedText, sClippedFg, sClippedBg)
        term.setCursorPos(nStartX + nPos - nScroll + 1, nStartY + 1)
    end

    local function setCursor(_nX, _bSetMark)
        nPos = math.max(0, math.min(#sLine, _nX))

        if _bSetMark then nMark = nPos end
    end

    local function deleteMarked()
        local nMarkStart, nMarkEnd = getMarks()

        if nMarkStart then
            sLine = sLine:sub(1, nMarkStart) .. sLine:sub(nMarkEnd + 1)

            setCursor(nMarkStart, true)
        end
    end

    local function recomplete()
        if nPos == #sLine then
            tCompletions = _fnAutocomp(sLine)

            if tCompletions then
                nCompletion = 1
            else
                nCompletion = nil
            end
        else
            tCompletions = nil
            nCompletion = nil
        end
    end

    term.setCursorBlink(true)

    local bRecomplete = true

    while true do
        if bRecomplete then recomplete() end

        bRecomplete = true

        draw(false)

        local sEvent, vArg, vArg2, vArg3 = os.pullEvent()

        if sEvent == 'char' or sEvent == 'paste' then
            deleteMarked()
            sLine = sLine:sub(1, nPos) .. vArg .. sLine:sub(nPos + 1)
            setCursor(nPos + 1, true)
        elseif sEvent == 'key' then
            if vArg == keys.enter then
                break
            elseif vArg == keys.left then
                if nPos > 0 then setCursor(nPos - 1, not bShift) end
            elseif vArg == keys.right then
                if nPos < #sLine then
                    setCursor(nPos + 1, not bShift)
                end
            elseif vArg == keys.up then
                if nCompletion then
                    if nCompletion == 1 then
                        nCompletion = #tCompletions
                    else
                        nCompletion = nCompletion - 1
                    end
                elseif _tHistory and #_tHistory > 0 then
                    if nHistoryPos == nil then
                        nHistoryPos = #_tHistory
                    elseif nHistoryPos > 1 then
                        nHistoryPos = nHistoryPos - 1
                    end

                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        setCursor(#sLine, true)
                    end
                end

                bRecomplete = false
            elseif vArg == keys.down then
                if nCompletion then
                    if nCompletion == #tCompletions then
                        nCompletion = 1
                    else
                        nCompletion = nCompletion + 1
                    end
                elseif _tHistory and #_tHistory > 0 then
                    if nHistoryPos == #_tHistory then
                        nHistoryPos = nil
                    elseif nHistoryPos ~= nil then
                        nHistoryPos = nHistoryPos + 1
                    end

                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        setCursor(#sLine, true)
                    end
                end

                bRecomplete = false
            elseif vArg == keys.tab then
                if nCompletion and tCompletions[nCompletion] then
                    sLine = sLine .. tCompletions[nCompletion]
                    setCursor(#sLine, not bShift)
                end
            elseif vArg == keys.backspace then
                if getMarks() then
                    deleteMarked()
                else
                    if nPos > 0 then
                        sLine = sLine:sub(1, nPos - 1) .. sLine:sub(nPos + 1)
                        setCursor(nPos - 1, not bShift)
                    end
                end
            elseif vArg == keys.delete then
                if getMarks() then
                    deleteMarked()
                else
                    if nPos < #sLine then
                        sLine = sLine:sub(1, nPos) .. sLine:sub(nPos + 2)
                    end
                end
            elseif vArg == keys.home then
                setCursor(0, not bShift)
            elseif vArg == keys['end'] then
                setCursor(#sLine, not bShift)
            elseif vArg == keys.leftShift then
                bShift = true
            end
        elseif sEvent == 'key_up' then
            if vArg == keys.leftShift then
                bShift = false
            else
                bRecomplete = false
            end
        elseif sEvent == 'mouse_click' then
            if vArg == 1 then
                local nX, nY = vArg2 - 1, vArg3 - 1

                if nY == nStartY then
                    if nX >= nStartX and nX < nStartX + _nMaxlen then
                        setCursor(nScroll + (nX - nStartX), not bShift)
                    end
                end
            end
        elseif sEvent == 'mouse_drag' then
            if vArg == 1 then
                local nX, nY = vArg2 - 1, vArg3 - 1

                if nY == nStartY then
                    if nX >= nStartX and nX < nStartX + _nMaxlen then
                        setCursor(nScroll + (nX - nStartX), false)
                    end
                end
            end
        end

        if nScroll < nPos - _nMaxlen + 1 then
            nScroll = nPos - _nMaxlen + 1
        elseif nScroll > nPos - 2 then
            nScroll = math.max(0, nPos - 2)
        end
    end

    draw(true)
    term.setCursorBlink(false)
    term.setCursorPos(nStartX + _nMaxlen + 1, nStartY + 1)

    if _bPrintAfter then print() end

    return sLine
end
