Input = require('libraries.boipushy.Input')

-- There are different box sizes, number of boxes, and
-- life depending on the "board size" setting selected.
SMALLBOXSIZE  = 60 -- size is in pixels
MEDIUMBOXSIZE = 20
LARGEBOXSIZE  = 11

SMALLBOARDSIZE  = 6 -- size is in boxes
MEDIUMBOARDSIZE = 17
LARGEBOARDSIZE  = 30

SMALLMAXLIFE  = 10 -- number of turns
MEDIUMMAXLIFE = 30
LARGEMAXLIFE  = 64

FPS = 30
WINDOWWIDTH = 640
WINDOWHEIGHT = 480
boxSize = MEDIUMBOXSIZE
PALETTEGAPSIZE = 10
PALETTESIZE = 45
EASY = 0   -- arbitrary but unique value
MEDIUM = 1 -- arbitrary but unique value
HARD = 2   -- arbitrary but unique value

difficulty = MEDIUM -- game starts in "medium" mode
maxLife = MEDIUMMAXLIFE
boardWidth = MEDIUMBOARDSIZE
boardHeight = MEDIUMBOARDSIZE

--            R    G    B
WHITE    = {1.0, 1.0, 1.0} --(255, 255, 255)
DARKGRAY = {.27, .27, .27} --( 70,  70,  70)
BLACK    = { .0,  .0,  .0} --(  0,   0,   0)
RED      = {1.0,  .0,  .0} --(255,   0,   0)
GREEN    = {.0,  1.0,  .0} --(  0, 255,   0)
BLUE     = {.0,   .0, 1.0} --(  0,   0, 255)
YELLOW   = {1.0, 1.0,  .0} --(255, 255,   0)
ORANGE   = {1.0, 0.5,  .0} --(255, 128,   0)
PURPLE   = {1.0,  .0, 1.0} --(255,   0, 255)

-- The first color in each scheme is the background color, the next six are the palette colors.
COLORSCHEMES = {{ {.58, 0.78, 1.}, RED, GREEN, BLUE, YELLOW, ORANGE, PURPLE},
                { {0, .6, .4},  {.38, .84, .64},  {.89, 0, .27},  {0, .49, .19},   {.8, .96, .0},   {.58, .0, .17},    {.94, .42, .58}},
                { {.76, .7, 0},  {1.0, .93, .45}, {1.0, .88, .0}, {.57, .01, .65},  {.09, .14, .69},   {.65, .56, 0},   {.77, .38, .82}},
                { {.33, 0, 0},     {.60, .15, .4},  {0, .78, .05},  {1.0, .46, 0},  {.8, 0, .44},   {0, .5, .03},     {1.0, .7, .45}},
                { {.74, .62, .25}, {.71, .71, 208}, {4, 31, .81},  {.65, .72, .17}, {.47, .5, .83}, {.14, .8, .02},    {.34, .6, .83}},
                { {.78, .12, .8}, {.45, .98, .72}, {.26, .21, .21},  {.2, .93, .32},  {0.09, .58, .76},  {.87, 0.61, .89}, {.83, .33, .72}}}

for i = 1, #COLORSCHEMES do
    assert((#COLORSCHEMES[i] == 7), "Color scheme "..i.." does not have exactly 7 colors.")
    --assert len(COLORSCHEMES[i]) == 7, 'Color scheme %s does not have exactly 7 colors.' % (i)
end
bgColor = COLORSCHEMES[1][1]
paletteColors = {unpack(COLORSCHEMES[1], 2)}
BASCIC_FONT = love.graphics.newFont(23)
resultText = ""

function love.load() 
    RESETBUTTONIMAGE = love.graphics.newImage("assets/inkspillresetbutton.png")

    mousex = 0
    mousey = 0
    mainBoard = generateRandomBoard()
    life = maxLife
    lastPaletteClicked = nil

    paletteClicked = nil
    resetGame = false

    love.window.setTitle("LÖVE Ink Spill")
    love.window.setMode(WINDOWWIDTH, WINDOWHEIGHT)
    love.graphics.setBackgroundColor(bgColor)

    input = Input()
    input:bind('mouse1', 'leftButton')
end

function love.update(dt)
    
    if input:released('leftButton') then
        local x, y = love.mouse.getPosition()
        mousex = x
        mousey = y
        paletteClicked = getColorOfPaletteAt(mousex, mousey)


        local resetButtonRect = {x = WINDOWWIDTH - RESETBUTTONIMAGE:getWidth(), y = WINDOWHEIGHT - RESETBUTTONIMAGE:getHeight(),
                                 w = RESETBUTTONIMAGE:getWidth(), h = RESETBUTTONIMAGE:getHeight()}
        if mousex > resetButtonRect.x and mousex < resetButtonRect.x + resetButtonRect.w and mousey > resetButtonRect.y and mousey < resetButtonRect.x + resetButtonRect.h then
            resetGame = true
        end
    end

    if paletteClicked ~= None and paletteClicked ~= lastPaletteClicked then 
        if resultText == "" then
            lastPaletteClicked = paletteClicked
            floodFill(mainBoard[1][1], paletteClicked, 1, 1)
            life = life - 1
        end
        if hasWon() then
            resultText = "WIN"
        elseif life <= 0 then
            resultText = "LOST"
        end
    end

    if resetGame then 
        -- start a new game
        mainBoard = nil
        mainBoard = generateRandomBoard()
        life = maxLife
        lastPaletteClicked = nil
        resetGame = false
        resultText = ""
    end
end

function love.draw()
    drawResult()
    drawLogoAndButtons()
    drawBoard()
    drawLifeMeter()
    drawPalettes()
end

function generateRandomBoard()
--difficulty=MEDIUM
    local board = {}
    for x = 1, boardWidth do
        local column = {}
        for y = 1, boardHeight do
            table.insert(column, love.math.random(2, #paletteColors+1))
        end
        table.insert(board, column)
    end
    -- Make board easier by setting some boxes to same color as a neighbor.

    -- Determine how many boxes to change.
    if difficulty == EASY then 
        if boxSize == SMALLBOXSIZE then
            boxesToChange = 100
        else
            boxesToChange = 1500
        end
    elseif difficulty == MEDIUM then
        if boxSize == SMALLBOXSIZE then
            boxesToChange = 5
        else
            boxesToChange = 200
        end
    else
        boxesToChange = 0
    end

    for i = 1 , boxesToChange do 
        -- Randomly choose neighbors to change
        local x = love.math.random(2, boardWidth - 1)
        local y = love.math.random(2, boardHeight - 1)

        -- Randomly choose neighbors to change.
        local direction = love.math.random(0, 4)
        if direction == 0 then -- change left and up neighbor
            board[x-1][y] = board[x][y]
            board[x][y-1] = board[x][y]
        elseif direction == 1 then -- change right and down neighbor
            board[x+1][y] = board[x][y]
            board[x][y+1] = board[x][y]
        elseif direction == 2 then -- change right and up neighbor
            board[x][y-1] = board[x][y]
            board[x+1][y] = board[x][y]
        else -- change left and down neighbor
            board[x][y+1] = board[x][y]
            board[x-1][y] = board[x][y]
        end
    end

    return board
end

function drawLogoAndButtons()
    love.graphics.draw(RESETBUTTONIMAGE, WINDOWWIDTH - RESETBUTTONIMAGE:getWidth(), WINDOWHEIGHT - RESETBUTTONIMAGE:getHeight())    
end

function drawResult()
    love.graphics.setColor(RED)
    love.graphics.setFont(BASCIC_FONT)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(resultText)
    local textHeight = font:getHeight()
    love.graphics.print(resultText, WINDOWWIDTH / 2, 30, 0, 1, 1, textWidth / 2, textHeight / 2)
    --love.graphics.print(resultText, 0, 0)
    love.graphics.setColor(1, 1, 1)
end

function drawBoard()
    -- The colored squares are drawn to a temporary surface which is then
    -- drawn to the DISPLAYSURF surface. This is done so we can draw the
    -- squares with transparency on top of DISPLAYSURF as it currently is.
    if resetGame then
        return
    end 

    for x = 1, boardWidth do
        for y = 1, boardHeight do 
            local left, top = leftTopPixelCoordOfBox(x, y)
            local r, g, b = paletteColors[ mainBoard[x][y] ]
            love.graphics.setColor(COLORSCHEMES[1][mainBoard[x][y]])
            love.graphics.rectangle("fill", left, top, boxSize, boxSize)
            love.graphics.setColor(1,1,1)
        end
    end
end

function drawLifeMeter()
    local lifeBoxSize = math.floor((WINDOWHEIGHT - 40) / maxLife)
    -- Draw background color of life meter.
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", 20, 20, 20, 20 + ((maxLife - 1 ) * lifeBoxSize) - 5)
    for i = 0, maxLife - 1 do 
        if life >= (maxLife - i) then -- draw a solid red box
            love.graphics.setColor(RED)
            love.graphics.rectangle("fill", 20, 20 + (i * lifeBoxSize), 20, lifeBoxSize)
        end
        love.graphics.setColor(WHITE)
        love.graphics.rectangle("line", 20, 20 + (i * lifeBoxSize), 20, lifeBoxSize)
    end
    love.graphics.setColor(1, 1, 1)
end

function drawPalettes() 
    -- Draws the six color palettes at the bottom of the screen.
    local numColors = #paletteColors
    local xmargin = math.floor((WINDOWWIDTH - ((PALETTESIZE * numColors) + (PALETTEGAPSIZE * (numColors - 1)))) / 2)
    for i = 1, numColors do 
        local left = xmargin + ((i - 1) * PALETTESIZE) + ((i - 1) * PALETTEGAPSIZE)
        local top = WINDOWHEIGHT - PALETTESIZE - 10
        love.graphics.setColor(paletteColors[i])
        love.graphics.rectangle("fill", left, top, PALETTESIZE, PALETTESIZE)
        love.graphics.setColor(paletteColors[i])
        love.graphics.rectangle("line", left - 2, top - 2, PALETTESIZE + 4, PALETTESIZE + 4)
    end
    love.graphics.setColor(1, 1, 1)
end

function leftTopPixelCoordOfBox(boxx, boxy)
    -- Returns the x and y of the left-topmost pixel of the xth & yth box.
    local xmargin = math.floor( (WINDOWWIDTH -  (boardWidth * boxSize)) / 2 )
    local ymargin = math.floor( (WINDOWHEIGHT - (boardHeight * boxSize)) / 2 ) 
    return (boxx - 1) * boxSize + xmargin, (boxy - 1) * boxSize + ymargin
end

function floodFill(oldColor, newColor, x, y)
    -- This is the flood fill algorithm

    if oldColor == newColor or mainBoard[x][y] ~= oldColor then
        return
    end

    mainBoard[x][y] = newColor -- change the color of the current box
    -- Make the recursive call for any neighboring boxes:
    if x > 1 then 
        floodFill(oldColor, newColor, x - 1, y) -- on box to the left
    end
    if x < boardWidth then
        floodFill(oldColor, newColor, x + 1, y) -- on box to the right
    end
    if y > 1 then
        floodFill(oldColor, newColor, x, y - 1) -- on box to up
    end
    if y < boardHeight then 
        floodFill(oldColor, newColor, x, y + 1) -- on box to down
    end
end

function getColorOfPaletteAt(x, y)
    -- Returns the index of the color in paletteColors that the x and y parameters
    -- are over. Returns None if x and y are not over any palette.
    local numColors = #paletteColors
    local xmargin = math.floor((WINDOWWIDTH - ((PALETTESIZE * numColors) + (PALETTEGAPSIZE * (numColors - 1)))) / 2)
    local top = WINDOWHEIGHT - PALETTESIZE - 10
    for i = 0, numColors do 
        -- Find out if the mouse click is inside any of the palettes.
        local left = xmargin + (i * PALETTESIZE) + (i * PALETTEGAPSIZE)
        local r = {x = left, y = top, w = PALETTESIZE, h = PALETTESIZE}
        if x > r.x and x < r.x + r.w and y > r.y and y < r.y + r.h then 
            return i + 2
        end
    end

    return nil
end

function hasWon() 
    -- # if the entire board is the same color, player has won
    for x = 1, boardWidth do
        for y = 1, boardHeight do
            if mainBoard[x][y] ~= mainBoard[1][1] then
                return false -- found a different color, layer has not won
            end
        end
    end
    return true
end
