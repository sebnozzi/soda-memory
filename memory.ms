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

color = {}
color.rgba = function(r, g, b, a)
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


loadCardBackImg = function()
	img = file.loadImage(file.child("card_images","Back_Card.png"))
	return img
end function

cards = []

CardSprite = new Sprite
CardSprite.fileName = "UNDEFINED"
CardSprite.variant = "A/B"
CardSprite.otherPair = null
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

createCardSprite = function(variant,fileName,cardImg)
	cardSprite = new CardSprite
	cardSprite.variant = variant
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
	cardImg = file.loadImage(file.child("card_images", fileName))
	// We now have the image of the card, let's create sprites
	cardSpriteA = createCardSprite("A",fileName,cardImg)
	cardSpriteB = createCardSprite("B",fileName,cardImg)
	cardSpriteA.otherPair = cardSpriteB
	cardSpriteB.otherPair = cardSpriteA
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
			tintColor = color.rgba(255,255,255,transparency)
			for card in cardsToGlow
				card.tint = tintColor
			end for
			wait 0.01
			yield
		end for
		for transparency in range(80,255,40)
			tintColor = color.rgba(255,255,255,transparency)
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

attemptedCards = []
pairedCards = []

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
	
	if isButtonDown and not wasButtonDown then
		if len(attemptedCards) >= 2 then
			// Bypass user clicks if already showing 2 attempted cards
			break
		end if
		for card in cards
			if card.contains(mouse) and not card.showingFront then
				attemptedCards.push card
				card.showFront	
			end if
		end for
	end if
	
	wasButtonDown = isButtonDown
	
	if len(attemptedCards) == 2 then
		cardA = attemptedCards[0]
		cardB = attemptedCards[1]
		if cardA.otherPair == cardB then
			// Match found!
			matchedCards = [cardA, cardB]
			pairedCards = pairedCards + matchedCards
			attemptedCards = []
			hideCardsTimeout = 0
			glowCards(matchedCards)
		else
			// No match - hide the pair after a while
			wait(SECONDS_TO_PEEK)
			for s in attemptedCards
				s.showBack
			end for
			attemptedCards = []
			attempts = attempts + 1
		end if
	end if	
	
	if len(pairedCards) == len(cards) then
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
