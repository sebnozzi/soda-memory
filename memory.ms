// This is a very simple game of "memory" using Mini Micro assets.
// It is intended as a solitaire game.

// ------------------------------------------------
// Declare helper functions we need from Mini Micro

// Convert a 0-255 number to a 2-digit hex string
hex2 = function(val)
  result = 0
  digits = "0123456789ABCDEF"
  val = floor(val)
  if val < 0 then return "00"
  if val >= 255 then return "FF"
  return digits[val / 16] + digits[val % 16]
end function

rgba = function(r, g, b, a)
  return "#" + hex2(r) + hex2(g) + hex2(b) + hex2(a)
end function

// ------------------------------------------------
// Program

window.backColor = "#000000"

// How long can you look at cards before hiding them again
// In seconds
SECONDS_TO_PEEK=1

// These are the images to be used.
foodFileNames = [
  "Apple_Card.png",
  "Bananas_Card.png",
  "Burger_Card.png",
  "Cake_Card.png",
  "Cheese_Card.png",
  "Cookie_Card.png",
  "Donut_Card.png",
  "Muffin_Card.png",
  "Pizza_Card.png",
  "Sushi_Card.png"]

// We may not forget about "Back_Card.png!"

// The grid size should reflect the amount of images
countRows=4
countCols=5

// Dimensions and visual properties of the cards
boxWidth=120
boxHeight=120
boxBorder=10
cardColor="#008BFFFF"

// Margin between cards in the board
margin=20
// Dimensions and coordinates of the board
boardWidth=(boxWidth+margin)*countCols-margin
boardHeight=(boxHeight+margin)*countRows-margin
// Make the board centered
boardOriginX=960/2-(boardWidth/2)
boardOriginY=640/2-(boardHeight/2)

loadImg = function(imgName)
  img = file.loadImage(file.child("card_images", imgName))
  if img == null then
    print "Image could not be loaded: ./card_images/" + imgName
    print "Be sure to execute this program from the directory of the main script file"
    print "(cd / move to the directory with the main script first)"
    exit
  end if
  return img
end function

loadCardBackImg = function()
  img = loadImg("Back_Card.png")
  return img
end function

cards = []

CardSprite = new Sprite
CardSprite.fileName = "UNDEFINED"
CardSprite.backImg = loadCardBackImg
CardSprite.showingFront = false
CardSprite.showBack = function()
  self.image = self.backImg
  self.showingFront = false
end function
CardSprite.showFront = function()
  self.image = self.frontImg
  self.showingFront = true
end function
CardSprite.isPairOf = function(otherCard)
  return self.fileName == otherCard.fileName
end function

createCardSprite = function(fileName,cardImg)
  cardSprite = new CardSprite
  cardSprite.frontImg = cardImg
  cardSprite.fileName = fileName
  // Setting the localBounds is necessary to later being
  // able to ask wether the sprite was clicked or not
  cardSprite.localBounds = new Bounds
  cardSprite.localBounds.width = cardImg.width
  cardSprite.localBounds.height = cardImg.height
  cardSprite.showBack
  return cardSprite
end function

// Create card sprites from file-names
for fileName in foodFileNames
  cardImg = loadImg(fileName)
  // We now have the image of the card, let's create sprites
  cardSpriteA = createCardSprite(fileName,cardImg)
  cardSpriteB = createCardSprite(fileName,cardImg)
  cards.push cardSpriteA
  cards.push cardSpriteB
end for

// Mix all the cards!
cards.shuffle

// Place cards on the board / screen
cardIdx = 0
for y in range(0,countRows-1)
  for x in range(0,countCols-1)
    cardOriginX = boardOriginX+(x*(boxWidth+margin))
    cardOriginY = boardOriginY+(y*(boxHeight+margin))
    card = cards[cardIdx]
    // Adjust sprite placement because coordinates
    // refer to the center of it, not its leftBottom corner.
    // Move it by half its size.
    card.x = cardOriginX+boxWidth/2
    card.y = cardOriginY+boxHeight/2
    sprites.push card
    // Take next card
    cardIdx = cardIdx + 1
  end for
end for

// Used to signalize the user that something special
// happened with these cards. Usually that a pair was found.
glowCards = function(cardsToGlow)
  for i in range(0,1)
    for transparency in range(255,80,-40)
      tintColor = rgba(255,255,255,transparency)
      for card in cardsToGlow
        card.tint = tintColor
      end for
      wait 0.01
      yield
    end for
    for transparency in range(80,255,40)
      tintColor = rgba(255,255,255,transparency)
      for card in cardsToGlow
        card.tint = tintColor
      end for
      wait 0.01
      yield
    end for
  end for
end function

// -- MAIN PROGRAM --

wasButtonDown = false
isButtonDown = false

cardA = null
cardB = null
pairedCardsCount = 0

attempts = 0
startTime = time

exitIfRequested = function()
  // No `key.available` and `key.get` - only `key.pressed`
  if key.pressed("q") or key.pressed("escape") then
    exit
  end if
end function

while true
  isButtonDown = mouse.button  
  
  clickedCard = null
  if isButtonDown and not wasButtonDown then
    for card in cards
      if card.contains(mouse) and not card.showingFront then 
        clickedCard = card
        break
      end if 
    end for
  end if

  if clickedCard != null then
    if cardA == null then
      cardA = clickedCard
      cardA.showFront
    else if cardB == null then
      cardB = clickedCard
      cardB.showFront
      if cardB.isPairOf(cardA) then
        // Match found!
        pairedCardsCount = pairedCardsCount + 2
        glowCards([cardA, cardB])
      else
        // No match - hide the pair after a while
        wait(SECONDS_TO_PEEK)
        cardA.showBack
        cardB.showBack
        attempts = attempts + 1
      end if
      // Reset attempted cards
      cardA = null
      cardB = null
    end if
  end if
  
  wasButtonDown = isButtonDown
  
  if pairedCardsCount == len(cards) then
    // Game is won
    endTime = time
    timeTaken = round(endTime-startTime,0)
    print "Solved! (in "+attempts+" attempts and "+timeTaken+" seconds)"
    print("Press Q or ESC to exit ...")
    while true
      exitIfRequested
      yield
    end while
  end if

  exitIfRequested
    
  yield
end while
