//Högen man lägger på
class Pile extends MovieClip {
	
	public var Cards:Array;
	public var TYPE = "Pile";
	
	public function Pile(){
		Cards = new Array();
	}
	
	public function AddCard(card:Card, x:Number, y:Number):Card {
		var newcard = attachMovie("Card", "Card"+Cards.length, this.getNextHighestDepth(), {
			_x: x,
			_y: y,
			_rotation: card._rotation
		});
		newcard.InitCard(card.Merged);
		Cards.push(newcard);
		_root.CurrentDepth.text = newcard.getDepth();
		return newcard;
	}
	
	public function RemoveCard(card:Card){
		//Tar bort ett kort på ett korrekt sätt
		for(var i = 0; i<=Cards.length; i++){
			if(Cards[i] == card){
				//Hittat kortet som ska tas bort!!
				card.removeMovieClip();
				//Byter namn på alla kort som kommer efter
				for(var j = i+1; j<=Cards.length;j++){
					Cards[j]._name = "Card" +j
				}
				Cards.splice(i, 1);
				break;
			}
		}
	}
	
	public function Clear() {
		var CardsCount = Cards.length;
		for(var i = 0;i<CardsCount;i++){
			RemoveCard(Cards[0]);
		}
	}
}