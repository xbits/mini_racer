=Megaclip Racing

==So here is the game!!

	Took a lot longer than I had anticipated. 
	I'm already late in delivery and late in workplace so I'll leave some needed polishing out.

	Sidenote: WTF is wrong with flashes newer stuff!! 
		Had lots of problems with preloader and the new textfields(TFT??) many hours lost in there.

==About Requirements

	- 'two player,'
	Two more included for extra flavor. The structure was there so couldn't help myself.
	
	-'The movement is made by clicking the car and dragging the mouse to the opposite direction of where you want to go'
	I may have overdone this. Used physics engine to make a car with turning wheels and all.
	Can't really figure how you expected the car to move, guess I should had asked.
	
	-'Each player should have a limited amount of time to make their move.'
	Not done, would be easy to add but I'm too late already and need to focus on work.
	
	-'The first to reach the finish line wins. Show the winner in the game.'
	Took the liberty to change this a bit. Its turn based so it would be unfair if the following player didn't had another chance.
	
	-'After the game ends the player should be presented with a popup with the options of Main Menu and Play again'
	Oh fuu..missed the popup part
	
	===Extra
		-'Physics car customization, change engine or wheels that will impact the way the car handles ingame'
		Sort of there. Numbers need to be tweaked for the values to have any meaning though.

		
	
==Technical details 

	Not too happy about the general structure of it. Comming from 2 years in MVC RoR most classes and methods feel bloated.

	All graphical assets are loaded at runtime. May have been a poor decision.
	A cleaner setup would had been to bundle them in an swc and compile with source code and load all with a preloader.
	Also current setup implies duplicate font definitions in imports.

	BulkLoader may also have been a bad choice GreenSocks loader looks much more powerfull, only found it at the end.
	
	Sound and Splash screen were added at the end without much care, out of time.
	
==Bugs
	- There's a bug in backwards launch angles calculation, it was fine at some point but messed in some refactorization.
	
	- Car parameters and the way they are used need to be tweaked.
	
	- Cars look too small, would. 
	
