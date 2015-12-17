//Tar hand om all kommunikation med servern
var socket = new XMLSocket();

socket.onConnect = function(success){
	if(success){
		socket.send("game=Vändtia");
	}else{
		_root.Error_txt = "Det gick inte att ansluta";
		_root.loading._visible = false;
		trace("Gick inte att ansluta :(");
	}
}

socket.onClose = function(){
	trace("Anslutningen avbröts...");
	_root.attachMovie("ConnectionError", "ConnectionError", _root.getNextHighestDepth(),{_x:Stage.width/2, _y:Stage.height/2});
}

XMLSocket.prototype.onData = function (src){
	var data = src.split("=");
	
	_root.recieve += "\n" + src;

	if(data[0] == "OK")
	{
		socket.send(_root.PersonName);
		_root.gotoAndPlay("Connected");
	}
	else if(data[0] == "wronggame")
	{
		_root.Error_txt = "Anslutningen lyckades men servern var avsedd för något annat spel";
		_root.loading._visible = false;
	}
	else if(data[0] == "sendagain")
	{
		socket.send(data.slice(1).join("="));
	}
	else if(data[0] == "newplayer")
	{
		//En ny spelare har anslutit sig
		_root.players.push(data[1]);
		_root.players_txt.text += data[1] + "\n";
	}
	else if(data[0] == "start")
	{
		//Spelet ska nu starta!!!
		_root.IntroductionVideo.unloadMovie();
		_root.gotoAndPlay("StartGame");
		DrawPlayers();
	}
	else if(data[0] == "yournewcard")
	{
		//Man har fått ett nytt kort
		if(data[2]=="hidden"){
			//Kortet är ett nedåtvänt kort
			_root["Player_"+PersonName].Tablecards.AddCard(data[1], true);
		}else{
			//Kortet är ett vanligt kort man har på handen
			_root["Player_" + PersonName].AddCard(data[1]);
		}
	}
	else if(data[0] == "tablecard"){
		//Någon har fått ett nytt, känt bordskort
		_root["Player_"+data[2]].Tablecards.AddCard(data[1], false);
	}
	else if(data[0] == "turn")
	{
		_root.SetTurn(_root["Player_" + data[1]]);
		if(data[1] == _root.PersonName){
			_root.Turn.CardsDragable = true;
			if(_root.Turn.Cards.length == 0){
				_root.Turn.Tablecards.CardsDragable = true;
			}
		}else{
			_root["Player_"+PersonName].CardsDragable = false;
			_root["Player_"+PersonName].Tablecards.CardsDragable = false;
		}
	}
	else if(data[0] == "layedcard")
	{
		//Någon har lagt ett kort
		if(_root.Turn.Name != _root.PersonName){
			var CommentText = _root.Turn.Name + " lägger ";
			var Cards:Array = data[1].split(",");
			for(var i = 0; i<Cards.length; i++){
				var CardData = Cards[i].split("&");
				var c = new Card();
				c.InitCard(CardData[0]);
				var newcard = _root.Pile.AddCard(c, Number(CardData[2]), Number(CardData[1]));
				newcard.onPress = undefined;
				newcard.onRelease = undefined;
				newcard._rotation = Number(CardData[3]);
				CommentText += newcard.Type + " " + newcard.Number;
				
				//Om spelaren inte chansat så ska ett kort tas bort från spelaren
				if(newcard.Merged != ChanceCard.Card.Merged){
					if(!CardData[4]){
						//Spelaren har lagt ett utav korten på sin hand
						_root.Turn.RemoveCard(_root.Turn.Cards[0]);
					}else{
						//Spelaren har lagt ett utav sina bordskort
						if(CardData[4]=="Hidden"){
							_root.Turn.Tablecards.RemoveCard(_root.Turn.Tablecards.Hidden[Number(CardData[5])-1]);
						}else if(CardData[4]=="Shown"){
							_root.Turn.Tablecards.RemoveCard(_root.Turn.Tablecards.Shown[Number(CardData[5])-1][Number(CardData[6])-1]);
						}
					}
				}else{
					//Spelaren har chansat och det gick bra. Tar bort kortet som skapats tidigare
					//då spelaren klickade på chans och initierar om ChanseCard-kortet
					_root.Pile.RemoveCard(_root.Pile.Cards[_root.Pile.Cards.length-2]);
					//_root.Pile.Cards[_root.Pile.Cards.length-1].onPress = undefined;
					//_root.Pile.Cards[_root.Pile.Cards.length-1].onRelease = undefined;
					_root.ChanceCard.Card.InitCard("");
				}
				
				//Om det är en 10:a eller 4 kort så ska högen vändas bort
				if(newcard.Number == 10 or (_root.Pile.Cards[_root.Pile.Cards.length-4].Number==_root.Pile.Cards[_root.Pile.Cards.length-3].Number && _root.Pile.Cards[_root.Pile.Cards.length-3].Number==_root.Pile.Cards[_root.Pile.Cards.length-2].Number && _root.Pile.Cards[_root.Pile.Cards.length-2].Number==_root.Pile.Cards[_root.Pile.Cards.length-1].Number && _root.Pile.Cards.length >=4)){
					_root.Pile.Clear();
				}
				
				if(i+1 < Cards.length){
					CommentText += ", ";
				}
			}
			_root.Comment.SetRollingText(CommentText);
		}
		
		if(data[3] == "win"){
			//Personen som la kortet har inga kvar
			_root.Turn.createTextField("Placement_Txt", _root.Turn.getNextHighestDepth(), -50, -50, 100, 100);
			_root.Turn.Placement_Txt.html = true;
			_root.Turn.Placement_Txt.htmlText = "<font size='55' face='Impact' color='#E0E0E0'>" + _root.Placement + ":a</font>";
			_root.Placement++
		}
		
	}
	else if(data[0] == "newcard")
	{
		_root["Player_"+data[1]].AddCard();
	}
	else if(data[0] == "switching")
	{
		if(data[1] == "start"){
			//Man kan börja byta
			_root.Comment.SetRollingText("Bytestiden har börjat!");
			_root.Timer.StartValue = Number(data[2]);
			_root.Timer.Start();
			_root.SwitchingEnabled = true;
			_root["Player_"+PersonName].CardsDragable = true;
			_root["Player_"+PersonName].Tablecards.CardsDragable = true;
		}else if(data[1] == "stop"){
			//Man kan inte längre byta
			_root.Comment.SetRollingText("Bytestiden är slut!");
			_root.Timer.Stop();
			_root.SwitchingEnabled = false;
			_root["Player_"+PersonName].CardsDragable = false;
			_root["Player_"+PersonName].Tablecards.CardsDragable = false;
		}
	}
	else if(data[0] == "laydown" && data[4] != PersonName)
	{
		//Lägger till kortet..
		_root["Player_"+data[3]].Tablecards.AddCard(data[1], false, Number(data[2]));
		//Tar bort ett kort från den som skickade
		_root["Player_"+data[4]].RemoveCard(_root["Player_"+data[4]].Cards[0]);
		
		//Kommentatorn
		var c = new Card();
		c.InitCard(data[1]);
		_root.Comment.SetRollingText(data[4] + " la ner "+c.Type+" "+c.Number+" på "+ ((data[3]==data[4])?"sig själv!":data[3]) );
		delete c;
	}
	else if(data[0] == "tookup" && data[3] != PersonName)
	{
		var c = _root["Player_"+data[3]].Tablecards.Shown[Number(data[1])-1][Number(data[2])-1]
		_root.Comment.SetRollingText(data[3] + " tog upp "+ c.Type +" "+c.Number);
		//Tar bort kortet från bordskorten
		_root["Player_"+data[3]].Tablecards.RemoveCard(c);
		//Lägger till ett kort i handen
		_root["Player_"+data[3]].AddCard();
	}
	else if(data[0] == "tookpile" && _root.Turn.Name != PersonName)
	{
		//Kollar om spelaren har lagt ett dolt kort och sedan fått lov att ta upp
		if(data[1]){
			var CardData = data[1].split("&");
			
			//Lägger till kortet i högen och tar bort bordskortet denne la
			var newcard = new Card();
			newcard.InitCard(CardData[0]);
			newcard = _root.Pile.AddCard(newcard, Number(CardData[2]), Number(CardData[1]));
			newcard._rotation = Number(CardData[3]);
			
			Turn.Tablecards.RemoveCard(Turn.Tablecards.Hidden[Number(CardData[5])-1]);
		}
		
		//Spelaren i tur tar upp så många kort som det ligger i högen
		for(var i = 0; i<_root.Pile.Cards.length; i++){
			Turn.AddCard();
		}
		_root.Pile.Clear();
		
		//Initierar om ChanseCard-kortet till ingenting så att ingen bugg uppstår
		//om spelaren skulle lägga det kortet innan nån chansat igen
		_root.ChanceCard.Card.InitCard("");
		
		_root.Comment.SetRollingText(_root.Turn.Name + " tog upp högen");
	}
	else if(data[0] == "chancecard")
	{
		_root.Comment.SetRollingText(_root.Turn.Name + " drog ett chanskort...");
		
		_root.ChanceCard.Card.InitCard(data[1]);
		_root.ChanceCard._visible = true;
		_root.ChanceCard.play();
		TakePileBtn.enabled = false;
		FinishedBtn.enabled = false;
		
		if(Turn.Name == PersonName){
			if(Control(ChanceCard.Card)){
				//Det är ok att lägga det kortet, låser "plocka-upp" knappen
				TakePileBtn._visible = false;
			}else{
				//Inte ok att lägga kortet, låser klar-knappen
				FinishedBtn._visible = false;
			}
			Turn.CardsDragable = false;
		}
	}
	else if(data[0] == "packofcards" && data[1] == "out")
	{
		PackOfCards.OutOfCards = true;
		PackOfCards._visible = false;
	}
	else if(data[0] == "excluded")
	{
		_root["Player_"+data[1]].Excluded = true;
		new mx.transitions.Tween(_root["Player_"+data[1]], "_alpha", mx.transitions.easing.Strong.easeOut, 100, 30, 50);
		new mx.transitions.Tween(_root["Player_"+data[1]].Tablecards, "_alpha", mx.transitions.easing.Strong.easeOut, 100, 30, 50);
		
		_root.Comment.SetRollingText(data[1] + " har avslutat spelet");
	}

}