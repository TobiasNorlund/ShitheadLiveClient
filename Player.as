//Player
class Player extends MovieClip {
	
	public var Name:String;
	public var Cards:Array;
	public var CardsDragable:Boolean;
	public var Excluded:Boolean = false;
	
	public var Tablecards:Tablecards;
	public var TYPE = "Player";
	
	function Player(){
		Cards = new Array();
		CardsDragable = false;
		attachMovie("Arrow", "Arrow", this.getNextHighestDepth(), {_alpha: 0, _x: -15 });
	}
	
	public function Order(){
		//Ordnar korten...
		var totalAngle:Number = 45 //Hur många grader ska hela kortleken luta
		var anglePerCard = totalAngle / (Cards.length - 1)
		function CompareFunction(c1:Card, c2:Card){
			if(c1.Number==1){ return 1; }
			if(c2.Number==1){ return -1; }
			if(c1.Number < c2.Number){
				return -1;
			}else if(c1.Number == c2.Number){
				return 0;
			}else if(c1.Number > c2.Number){
				return 1;
			}else{ return 0; }
		}
		
		var CardsSorted:Array = Cards.sort(CompareFunction, Array.RETURNINDEXEDARRAY);
		//For som loopar igenom alla kort på handen
		for(var i = 0; i<CardsSorted.length; i++){
			Cards[CardsSorted[i]]._rotation = (totalAngle/2*-1)+anglePerCard*i
			Cards[CardsSorted[i]]._x = 20*i - 50
			Cards[CardsSorted[i]]._y = 0
			Cards[CardsSorted[i]].swapDepths(i+1);
		}
	}
	
	public function AddCard(Merged:String){
		//Lägger in ett nytt kort på handen
		var cardNo = this.Cards.length + 1
		var card = attachMovie("Card","Card"+cardNo, this.getNextHighestDepth());
		card.InitCard(Merged);
		Cards.push(card);
		Order();
	}
	
	public function RemoveCard(card:Card){
		//Tar bort ett kort från handen på ett korrekt sätt
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
		Order();
	}
	
	public function GotTurn(){
		//Det har blivit den här spelarens tur. Visar pilen
		new mx.transitions.Tween(this["Arrow"], "_y", mx.transitions.easing.Strong.easeOut, 20, -13, 40);
		new mx.transitions.Tween(this["Arrow"], "_alpha", mx.transitions.easing.Strong.easeOut, 0, 100, 50);
		//new mx.transitions.Tween(this, "_alpha", mx.transitions.easing.Strong.easeOut, this._alpha, 100, 40); 

	}
	public function LostTurn(){
		new mx.transitions.Tween(this["Arrow"], "_y", mx.transitions.easing.Strong.easeOut, -13, 20, 40);
		new mx.transitions.Tween(this["Arrow"], "_alpha", mx.transitions.easing.Strong.easeOut,100, 0, 50);
		//new mx.transitions.Tween(this, "_alpha", mx.transitions.easing.Strong.easeOut, this._alpha, 30, 40);
	}
}