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
// Game properties

// How long can you look at cards before hiding them again
// In seconds
SECONDS_TO_PEEK=1

// ------------------------------------------------
// Display properties

window.backColor = "#000000"

// The grid size should reflect the amount of images
countRows=4
countCols=5

// Dimensions and visual properties of the cards
boxWidth=120
boxHeight=120

// Margin between cards in the board
margin=20
// Dimensions and coordinates of the board
boardWidth=(boxWidth+margin)*countCols-margin
boardHeight=(boxHeight+margin)*countRows-margin
// Make the board centered
boardOriginX=window.width/2-(boardWidth/2)
boardOriginY=window.height/2-(boardHeight/2)

// ------------------------------------------------
// Image loading

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
backCardFileName = "Back_Card.png"

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

// ------------------------------------------------
// CardSprite class declaration

CardSprite = new Sprite
CardSprite.fileName = "UNDEFINED"
CardSprite.frontImg = null
CardSprite.backImg = loadImg(backCardFileName)

CardSprite.showingFront = function()
  return self.image == self.frontImg
end function
CardSprite.showBack = function()
  self.image = self.backImg
end function
CardSprite.showFront = function()
  self.image = self.frontImg
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

// ------------------------------------------------
// Cards building

cards = []

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

// ------------------------------------------------
// Attempted pair logic

pair = {}
pair.firstCard = null
pair.secondCard = null
pair.reset = function()
  self.firstCard = null
  self.secondCard = null
end function
pair.isMatched = function()
  return self.firstCard.isPairOf(self.secondCard)
end function
pair.showBack = function()
  self.firstCard.showBack
  self.secondCard.showBack
end function 
pair.glowCards = function()
  cardsToGlow = [self.firstCard, self.secondCard]
  for i in range(0,1)
    for transparency in range(255,80,-40)
      tintColor = rgba(255,255,255,transparency)
      self.firstCard.tint = tintColor
      self.secondCard.tint = tintColor
      wait 0.01
      yield
    end for
    for transparency in range(80,255,40)
      tintColor = rgba(255,255,255,transparency)
      self.firstCard.tint = tintColor
      self.secondCard.tint = tintColor
      wait 0.01
      yield
    end for
  end for
end function

// ------------------------------------------------
// Game logic - properties

// Used to handle single mouse clicks
wasButtonDown = false
isButtonDown = false

// Used to track game progress
pairedCardsCount = 0

// Used for game statistics
attempts = 0
startTime = time

// ------------------------------------------------
// Game logic - main loop

while true
  isButtonDown = mouse.button  

  // Find clicked card
  clickedCard = null
  if isButtonDown and not wasButtonDown then
    for card in cards
      if card.contains(mouse) and not card.showingFront then 
        clickedCard = card
        break
      end if 
    end for
  end if
  // Prevent processing further mouse-clicks in next loop
  wasButtonDown = isButtonDown

  // Process clicked card, if any
  if clickedCard != null then
    clickedCard.showFront
    if pair.firstCard == null then
      pair.firstCard = clickedCard
    else if pair.secondCard == null then
      pair.secondCard = clickedCard
      if pair.isMatched then
        // Match found!
        pairedCardsCount = pairedCardsCount + 2
        pair.glowCards
      else
        // No match - hide the pair after a while
        wait SECONDS_TO_PEEK
        pair.showBack
        attempts = attempts + 1
      end if
      pair.reset
    end if
  end if
    
  // Check if the game is won
  if pairedCardsCount == len(cards) then
    endTime = time
    timeTaken = round(endTime-startTime,0)
    print "Solved! (in "+attempts+" attempts and "+timeTaken+" seconds)"
    print("Press Q or ESC to exit ...")
    // Wait for user to exit
    while true
      if key.pressed("q") or key.pressed("escape") then exit
      yield
    end while
  end if

  // Give user chance to exit game
  if key.pressed("q") or key.pressed("escape") then exit
  
  yield
end while
