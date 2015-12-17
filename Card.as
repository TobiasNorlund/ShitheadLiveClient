dynamic class Card extends MovieClip {
	
	public var Number:Number;
	public var Type:String;
	public var Merged:String;
	
	public var Dragable:Boolean;
	public var Hidden:Boolean = false;
	
	private var PrevX:Number;
	private var PrevY:Number;
	private var PervDepth:Number;
	private static var TOP_DEPTH = 1048575;
	
	function InitCard(typemerged:String,n:Number){
		if(arguments.length == 2){
			//Man har skickat med Type och Number
			Number = n;
			Type = typemerged;
			Merged = n + typemerged.substr(0,1);
			
			UpdateFrame();
		}else if(arguments.length == 1){
			//Man har skickat med Merged
			Merged = typemerged;
			switch (typemerged.substring(0,1)){
				case "H": Type = "Hjärter"; break;
				case "R": Type = "Ruter"; break;
				case "K": Type = "Klöver"; break;
				case "S": Type = "Spader"; break;
			}
			Number = parseInt(typemerged.substr(1));
			
			if(!this.Hidden)UpdateFrame();
		}
	}
	
	private function UpdateFrame(){
		//Ser till så att MC:n ligger på rätt frame
		var colorValue
		if(Type=="Ruter"){colorValue=1;}
		else if(Type=="Hjärter"){colorValue=2;}
		else if(Type=="Spader"){colorValue=3;}
		else if(Type=="Klöver"){colorValue=4;}
		
		var frame = 4*(Number-1)+colorValue+1;
		this.gotoAndStop(frame);
	}
	
	public function onPress(){
		//     Kort på handen och uppåtvända bordskort     -     ELLER       -    dolda bordskort
		if( ((_parent.CardsDragable || Dragable) && !this.Hidden) or (this.Hidden && _root.Pile.Cards[_root.Pile.Cards.length-1].onPress==undefined && _parent.Shown[0].length==0 && _parent.Shown[1].length==0 && _parent.Shown[2].length==0 && _root["Player_"+_root.PersonName].Cards.length==0 && _parent.CardsDragable)){
			this.startDrag()
			PrevX = this._x
			PrevY = this._y
			PrevDepth = this.getDepth();
			this.swapDepths(TOP_DEPTH);
		}
	}
	
	public function onRelease(){
		this.stopDrag();
		
		//Så att man inte kan lägga ner kort när det inte är tillåtet
		if(!_parent.CardsDragable && !Dragable){ return; }
		
		// ###################################################
		// #############   H Ö G E N   #######################
		
		if(this.hitTest(_root.Pile) && _root.Control(this) && _root.CheckCardLimit(this) && !this.Hidden && !_root.SwitchingEnabled && (_parent.TYPE=="Tablecards" or _parent.TYPE=="Player") or (this.Hidden && this.hitTest(_root.Pile))){
			trace("OK att lägga");
			var c = _root.Pile.AddCard(this, (_parent._x-_root.Pile._x)+this._x, (_parent._y-_root.Pile._y)+this._y);
			if(c._x<10 or c._y<30 or c._y>90 or c._x>120){c._x=50;c._y=65;}
			c.Dragable = true;
			_root.CheckSpecialCard(c);
			if(_parent.TYPE=="Tablecards"){
				c.ForeignPosition = [(this.Hidden)?"Hidden":"Shown", this.Position, this.Depth]
				if(this.Hidden){
					//Nedvända kort som man lagt upp ska man inte kunna dra tillbaka
					c.Dragable = false;
					if(_root.Control(_root.Pile.Cards[_root.Pile.Cards.length-1], _root.Pile.Cards[_root.Pile.Cards.length-2])){
						//Det var ok att lägga det kortet
						_root.TakePileBtn._visible = false;
					}else{
						_root.FinishedBtn._visible = false;
					}
				}
			}
			_parent.RemoveCard(this);
			return;
		}
		
		// ###################################################
		// #############   B O R D S K O R T   ###############
		
		if(_parent.TYPE=="Player" && !this.Hidden){
			for(var p = 0;p<_root.players.length;p++){
				var player = _root.players[p];
				for(var hc=0;hc<player.Tablecards.Hidden.length;hc++){
					var HiddenCard = player.Tablecards.Hidden[hc];
					if(this.hitTest(HiddenCard) && (_root.SwitchingEnabled or player.Name==_root.PersonName) ){
						//Man nuddar någons dolda kort. Kollar om det är ok att lägga kortet där..
						if( (player.Tablecards.Shown[HiddenCard.Position-1][0].Number == this.Number or player.Tablecards.Shown[HiddenCard.Position-1].length == 0) && this.Position != HiddenCard.Position && !player.Excluded){
							var text = "laydown="+(this.Merged)+"="+(HiddenCard.Position)+"="+(player.Name)+"="+(_root.PersonName)+"=";
							//Ser till så man har tre kort hela tiden
							if(3-(_root["Player_"+_root.PersonName].Cards.length-1) > 0){
								text += 3-(_root["Player_"+_root.PersonName].Cards.length-1);
							}
							_root.socket.send(text);
							trace(text);
							player.Tablecards.AddCard(this.Merged, false, HiddenCard.Position);
							_parent.RemoveCard(this);
							//Om man har lagt sista kortet ska bordskorten enablas
							if(_root.Turn.Cards.length == 0 && _root.PackOfCards.OutOfCards){
								_root.Turn.Tablecards.CardsDragable = true;
							}
							return;
						}
					}
				}
			}
		}
		
		// ###################################################
		// #############   H A N D E N   #####################
		
		if(this.hitTest(_root.Hand) && (_parent.TYPE=="Pile" or _parent.TYPE=="Tablecards")){
			var currentCardNumber:Number = Number(this._name.slice(4,6))
			if(_root.Pile["Card"+(currentCardNumber+1)]){
				//man fötsöker ta bort ett undre kort...
				if(_root.Control(_root.Pile["Card"+(currentCardNumber+1)], _root.Pile["Card"+(currentCardNumber-1)])){
					if(this.ForeignPosition){
						_root["Player_" + _root.PersonName].Tablecards.AddCard(this.Merged, false, this.ForeignPosition[1]);
					}else{
						_root["Player_" + _root.PersonName].AddCard(this.Merged);
					}
					_parent.RemoveCard(this);
					return;
				}
			}else{
				//Man vill ta bort det översta ur högen
				if(_parent.TYPE=="Tablecards"){
					//Man vill ta tillbaka ett kort från bordet
					if(_root.SwitchingEnabled){
						//Man får bara ta upp om det är byten...
						_root.socket.send("tookup="+this.Position+"="+this.Depth+"="+_root.PersonName);
					}else{ PlaceToPrevious(); return; }
				}
				if(this.ForeignPosition){
					_root["Player_" + _root.PersonName].Tablecards.AddCard(this.Merged, false, this.ForeignPosition[1]);
				}else{
					_root["Player_" + _root.PersonName].AddCard(this.Merged);
				}
				_parent.RemoveCard(this);
				return;
			}
		}
		
		//Om den kommer hit så sätts kortet bara tillbaka...om det nu var ett kort som man får dra i.
		if((_parent.CardsDragable || Dragable) && !this.Hidden){
			PlaceToPrevious();
		}
	}
	
	private function PlaceToPrevious(){
		this._x = PrevX;
		this._y = PrevY;
		this.swapDepths(PrevDepth);
	}
		
	public function onReleaseOutside(){
		onRelease();
	}
}