//Korten kom ligger på bordet, tre dolda och tre kända
class Tablecards extends MovieClip {
	
	public var Hidden:Array;
	public var Shown:Array;
	
	public var IsOpponent:Boolean = true;
	public var CardsDragable:Boolean = false;
	public var TYPE = "Tablecards";
	
	private var NextDepth:Number = 0;
	private function GetNextDepth():Number {
		NextDepth++
		return NextDepth;
	}
	
	function Tablecards(){
		Hidden = new Array();
		Shown = [new Array(),new Array(),new Array()];
	}
	
	public function AddCard(Merged:String, Hidden:Boolean, Place:Number):Boolean {
		var tempH = this.Hidden;
		if(Hidden){
			//Kortet är dolt
			if(this.Hidden.length<3){
				var card = attachMovie("Card","Hiddencard"+(this.Hidden.length+1), GetNextDepth());

				//Talar om för kortet vilken position den har
				card.Position = this.Hidden.length+1
				
				if(this.IsOpponent){
					card._x =  43*this.Hidden.length;
					card._y = 3;
					card._xscale = 55;
					card._yscale = 55;
				}else{
					card._x =  90*this.Hidden.length;
					card._y = 8;
				}
				card.Hidden = true;
				card.InitCard(Merged);
				this.Hidden.push(card);
				return true;
			}else{
				return false;
			}
		}else{
			// ## Kortet är uppåtvänt
			
			//Om man inte angett vart kortet ska ligga kollas det om det finns nån plats ledig
			if(Place==undefined){
				for(var i=0;i<3;i++){
					if(this.Shown[i].length==0){
						Place = i+1;
						break;
					}
				}
				if(Place==undefined)return false; //Om det inte fanns nån ledig så avslutas funktionen
			}
			var card = attachMovie("Card","Showncard"+Place+"-"+(this.Shown[Place-1].length+1), GetNextDepth());
			
			//Talar om för kortet vilken position den har mm
			card.Position = Place
			card.Depth = this.Shown[Place-1].length+1
			
			if(this.IsOpponent){
				card._x = 43*(Place-1)+1.05*this.Shown[Place-1].length+2;
				card._y = -1.5*this.Shown[Place-1].length
				card._xscale = 55;
				card._yscale = 55;
			}else{
				card._x = 90*(Place-1) + 3*this.Shown[Place-1].length + 5;
				card._y = -3*this.Shown[Place-1].length;
			}
			
			card.InitCard(Merged);
			this.Shown[Place-1].push(card);
			return true;
		}
	}
	
	public function RemoveCard(card:Card){
		//Tar bort kortet
		if(card.Hidden){
			this.Hidden[card.Position-1] = null //skriver över objektet
		}else{
			//Byter namn och flyttar de som kommer efter
			for(var i = card.Depth; i<this.Shown[card.Position-1].length; i++){
				this.Shown[card.Position-1][i]._x = (this.IsOpponent)?43*(card.Position-1)+1.05*(i-1)+2:90*(card.Position-1)+3*(i-1)+5;
				this.Shown[card.Position-1][i]._y = (this.IsOpponent)?-1.5*(i-1):-3*(i-1);
				this.Shown[card.Position-1][i].Depth = i;
				this.Shown[card.Position-1][i]._name = "Showncard"+card.Position+"-"+i;
			}
			//Tar bort referensen ur arrayen
			this.Shown[card.Position-1].splice(card.Depth-1,1);
		}
		card.removeMovieClip();
	}
}