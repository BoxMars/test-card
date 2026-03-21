class_name CardDeck
extends RefCounted

const SUITS := ["♠", "♥", "♣", "♦"]
const RANKS := ["A", "2", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const EMPEROR_CARD := "皇帝牌"
const JOKERS := ["小王", "大王"]
const SPECIAL_THREES := ["♠3", "♥3", "♣3", "♦3", "♠3"]
const SPECIAL_FOUR := "♥4"


static func build_main_deck() -> Array[String]:
	var cards: Array[String] = []
	var emperor_added := false

	for _deck_index in range(4):
		for suit in SUITS:
			for rank in RANKS:
				cards.append("%s%s" % [suit, rank])

		cards.append("小王")
		if emperor_added:
			cards.append("大王")
		else:
			cards.append(EMPEROR_CARD)
			emperor_added = true

	cards.append(SPECIAL_FOUR)
	cards.shuffle()
	return cards


static func build_special_threes() -> Array[String]:
	var cards: Array[String] = []
	cards.assign(SPECIAL_THREES)
	cards.shuffle()
	return cards
