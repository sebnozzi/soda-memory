// This is a very simple game of "memory" using Mini Micro assets.
// It is intended as a solitaire game.

// ------------------------------------------------
// Game properties

// How long can you look at cards before hiding them again
// (in seconds)
SECONDS_TO_PEEK=1

// The grid size should reflect the amount of images
countCols=5
countRows=4

// Dimensions and visual properties of the cards
boxWidth=120
boxHeight=120

// Margin between cards in the board
margin=20

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

// ------------------------------------------------
// Display properties

window.backColor = "#000000"

// ------------------------------------------------
// Calculated (derived) properties

// Dimensions and coordinates of the board
boardWidth = (boxWidth+margin)*countCols-margin
boardHeight = (boxHeight+margin)*countRows-margin
// Make the board centered
boardBottomLeftX = window.width/2-(boardWidth/2)
boardBottomLeftY = window.height/2-(boardHeight/2)

// ------------------------------------------------
// Helper functions

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

// Convert a 0-255 number to a 2-digit hex string
// (borrowed from Mini Micro)
hex2 = function(val)
  result = 0
  digits = "0123456789ABCDEF"
  val = floor(val)
  if val < 0 then return "00"
  if val >= 255 then return "FF"
  return digits[val / 16] + digits[val % 16]
end function

// Constructs a RGBA (w/ transparency) color hex-string
// (borrowed from Mini Micro)
rgba = function(r, g, b, a)
  return "#" + hex2(r) + hex2(g) + hex2(b) + hex2(a)
end function

// Glows a pair of cards for a while
glowPair = function(card1, card2)
  for i in range(0,1)
    for transparency in range(255,80,-40)
      tintColor = rgba(255,255,255,transparency)
      card1.tint = tintColor
      card2.tint = tintColor
      wait 0.01
      yield
    end for
    for transparency in range(80,255,40)
      tintColor = rgba(255,255,255,transparency)
      card1.tint = tintColor
      card2.tint = tintColor
      wait 0.01
      yield
    end for
  end for
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
  cardSpriteA = createCardSprite(fileName,cardImg)
  cardSpriteB = createCardSprite(fileName,cardImg)
  cards.push cardSpriteA
  cards.push cardSpriteB
end for

// Mix all the cards!
cards.shuffle

// Place cards on the board / screen
cardIdx = 0
for row in range(0,countRows-1)
  for col in range(0,countCols-1)
    card = cards[cardIdx]
    // Calculate card's bottom-left coordinates
    cardBottomLeftX = boardBottomLeftX+(col*(boxWidth+margin))
    cardBottomLeftY = boardBottomLeftY+(row*(boxHeight+margin))
    // Adjust sprite placement because coordinates
    // refer to the *center* of it, not its bottom-left corner.
    // Shift it by half its size.
    card.x = cardBottomLeftX+boxWidth/2
    card.y = cardBottomLeftY+boxHeight/2
    // Place sprite on screen
    sprites.push card
    // Take next card
    cardIdx = cardIdx + 1
  end for
end for

// ------------------------------------------------
// Game logic - properties

// Used to be able to detect *individual* mouse clicks
wasButtonDown = false
isButtonDown = false

// Used to keep track of the game
firstCard = null
secondCard = null
pairedCardsTotal = 0

// Used for game statistics
attempts = 0
startTime = time

// ------------------------------------------------
// Game logic - main loop

while true
  // Find a clicked card
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
  wasButtonDown = isButtonDown

  // Process clicked card, if any
  if clickedCard != null then
    clickedCard.showFront
    if firstCard == null then
      firstCard = clickedCard
    else if secondCard == null then
      secondCard = clickedCard
      if firstCard.isPairOf(secondCard) then
        // Match found!
        pairedCardsTotal = pairedCardsTotal + 2
        glowPair(firstCard, secondCard)
      else
        // No match - hide the pair after a while
        wait SECONDS_TO_PEEK
        firstCard.showBack
        secondCard.showBack
        attempts = attempts + 1
      end if
      // Make a next try possible
      firstCard = null
      secondCard = null
    end if
  end if
    
  // Check if the game is won
  if pairedCardsTotal == len(cards) then
    // Print statistics
    endTime = time
    timeTaken = round(endTime-startTime,0)
    print "Solved! (in "+attempts+" attempts and "+timeTaken+" seconds)"
    // Wait for user to exit
    print("Press Q or ESC to exit ...")
    while true
      if key.pressed("q") or key.pressed("escape") then exit
      yield
    end while
  end if

  // Give user chance to exit game while playing
  if key.pressed("q") or key.pressed("escape") then exit
  
  yield
end while
