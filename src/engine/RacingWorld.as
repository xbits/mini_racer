package engine 
{
	import Box2D.Collision.*; // bounding box of our world
	import Box2D.Common.Math.*; // for vector(define gravity)
	import Box2D.Dynamics.*; // define bodies and define world
	import Box2D.Dynamics.Joints.*;
	import Box2D.Collision.Shapes.*; // define our shapes
	import engine.models.CarParams;
	import engine.models.Player;
	import engine.physics.PlayableCar;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flash.display.Sprite;
	/**
	 * ...
	 * @author João Costa
	 */
	public class RacingWorld 
	{
		public static const EVT_UPDATE:String = 'worldUpdate';
		public static const CAR_INSTANCE_NAME:String = "playerCar";//TODO this is for one player only
		public static const SCALE:Number = 10;
		
		public var world:b2World;
		public var oracleWorld:b2World;
		
		public var worldSprite:Sprite;
		
		public var cars:Vector.<PlayableCar> = new Vector.<PlayableCar>();
		public var oracleCars:Vector.<PlayableCar> = new Vector.<PlayableCar>();
		private var players:Vector.<Player>;
		public var activePlayerIndex:int = 0;
		
		public var checkPoints:Array = [];
		
		
		
		public function RacingWorld() {

		}
		
		public function predictLaunchFrom(fromPoint:Point):Array {
			
			
			var oracleCar:PlayableCar = activeOracleCar;
			var car:PlayableCar = activeCar;
			//---reset oracle and set its positions
			oracleCar.imitateStatus(car);
			
			var from:b2Vec2 = new b2Vec2(fromPoint.x / SCALE, fromPoint.y / SCALE);
			oracleCar.launchFrom(from);
			
			var path:Array = [];
			var curPos:b2Vec2;
			oracleWorld.ClearForces();
			while(oracleCar.body.IsAwake() && path.length < 6){
				oracleWorld.Step(1 /30, 8, 8);
				oracleWorld.ClearForces();
				oracleCar.onWorldUpdate();
				curPos = oracleCar.body.GetPosition();
				path.push(new Point(curPos.x * SCALE, curPos.y * SCALE));
			}
			//TODO launch and step on oracle 
			return path;
		}
		
		public function launchFrom(fromPoint:Point ):void {
			
			var car:PlayableCar = activeCar;
			trace('world builder .launch from',car);
			var from:b2Vec2 = new b2Vec2(fromPoint.x / SCALE, fromPoint.y / SCALE);
			car.launchFrom(from);
			
		}
		
		public function update():void {
			world.Step(1 / 30, 8, 8);
			world.ClearForces();
			//world.DrawDebugData();
			
			var curCar:PlayableCar;
			for (var i:int = 0; i < cars.length; i++) {
				curCar = cars[i];
				curCar.onWorldUpdate();
			}
			var body:b2Body = world.GetBodyList();
			var userData:Object;
		//	trace('body',body);
			//update all displayObjects with the position from physics world
			while (body) {
				userData = body.GetUserData();
				if (userData && userData.sprite) {
					userData.sprite.x = body.GetPosition().x * SCALE;
					userData.sprite.y = body.GetPosition().y * SCALE;
					userData.sprite.rotation = body.GetAngle() * (180 / Math.PI) ; //why -90º is this just for the car?	
				}
				body = body.GetNext();
			}
		}
		
		public function get activeCar():PlayableCar {
			return cars[activePlayerIndex];
		}
		public function get activeOracleCar():PlayableCar {
			return oracleCars[activePlayerIndex];
		}
		
		public function build(sourceTrack:Sprite,players:Vector.<Player>):void {
			this.players = players;
			this.worldSprite = sourceTrack;
			
			world = new b2World(new b2Vec2(0, 0.0), true);
			oracleWorld = new b2World(new b2Vec2(0, 0.0), true);
			
			var dispObj:DisplayObject
			var carIndex:int;
			var i:int;
			for (i = 0; i < worldSprite.numChildren; i++ ) {
				dispObj = worldSprite.getChildAt(i);
				
			}
			
			var boundingRec:Rectangle;
			var boxShape:b2PolygonShape = new b2PolygonShape();//boxDef factory-ish for use in all boxes def
			var fixtureDef:b2FixtureDef = new b2FixtureDef();//fixture factory-ish
			var circleShape:b2CircleShape;
			var body:b2Body;
			var bodyDef:b2BodyDef;
			
			var garbageFromBullet:Array = [];
			
			for (i = 0; i < worldSprite.numChildren; i++ ) {
				
				dispObj = worldSprite.getChildAt(i);
				
				if (dispObj.name== CAR_INSTANCE_NAME){
					buildCars(dispObj);
				}else if (dispObj.name.search("CP")==0){
					checkPoints.push(dispObj)
				}else if (dispObj.name.search("FINISH")==0){
					checkPoints.push(dispObj)
				}else if (dispObj.name == "moneyBox") {
					trace("TrackBuilder-- Found money box :", dispObj.name)
					//	moneyInstance.moneyBox = childObj;
						dispObj.visible=false;
					//moneyInstance.moneyBox.visible = false;
				}else if (dispObj.name == "SBmoney") {
					trace("TrackBuilder-- Found money drawing :", dispObj.name)
					//	moneyInstance.moneyMovie = childObj;
					MovieClip(dispObj).gotoAndStop(1)
				}else if (dispObj.name == "moneyArea") {
					trace("TrackBuilder-- Found money Area:", dispObj.name)
					//	moneyInstance.moneyArea = childObj;
				}else if (dispObj.name.search("SB") == 0) {
					trace("TrackBuilder-- Found static circle :", dispObj.name)
					
					boundingRec = getAlignedRect(dispObj);
					
					bodyDef = new b2BodyDef();
					//bodyDef.userData = { sprite: dispObj };
					bodyDef.position.Set(dispObj.x/SCALE, dispObj.y/SCALE);
					
					boxShape.SetAsBox(boundingRec.width/SCALE * .5,boundingRec.height/SCALE * .5);
					fixtureDef.shape = boxShape;
					fixtureDef.friction = 0.8;
					fixtureDef.restitution = 0.3;
					bodyDef.angle = (dispObj.rotation) * (Math.PI / 180);// + Math.PI * .5;
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);

				}else if (dispObj.name.search("DB") == 0 ||  (dispObj.name.search("TRcar") == 0) ) {//set moving traffic from bullet drive as dumb boxes
					trace("TrackBuilder-- Found dynamic box :", dispObj.name)
					
					boundingRec = getAlignedRect(dispObj);
					
					bodyDef = new b2BodyDef();
					bodyDef.userData = { sprite: dispObj };
					bodyDef.linearDamping = 0.9;
					bodyDef.angularDamping = 0.9;
					bodyDef.position.Set(dispObj.x/SCALE, dispObj.y/SCALE);
					bodyDef.allowSleep = true;
					bodyDef.type = b2Body.b2_dynamicBody;
					
					boxShape.SetAsBox(boundingRec.width/SCALE * .5,boundingRec.height/SCALE * .5);
					fixtureDef.shape = boxShape;
					fixtureDef.friction = 0.7;
					fixtureDef.density = 6;
					fixtureDef.restitution = 0.4;
					
					bodyDef.angle = (dispObj.rotation) * (Math.PI / 180);
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);
					
				}else if (dispObj.name.search("SC") == 0) {
					//STATIC CIRCLES
					trace("TrackBuilder-- Found static circle :", dispObj.name)
					
					bodyDef = new b2BodyDef();
					//bodyDef.userData = { sprite: dispObj };
					bodyDef.position.Set(dispObj.x / SCALE, dispObj.y / SCALE);
					
					circleShape = new b2CircleShape(dispObj.width/ SCALE*.5);
					fixtureDef.shape = circleShape;
					fixtureDef.friction = 0.7;
					fixtureDef.restitution = 0.3;
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);
					
					
				}else if (dispObj.name.search("DC") == 0) {
					//dynamic circle
					trace("TrackBuilder-- Found dynamic circle :", dispObj.name)

					bodyDef = new b2BodyDef();
					
					bodyDef.userData = { sprite: dispObj };
					bodyDef.linearDamping = 1;
					bodyDef.angularDamping = 0.9;
					bodyDef.position.Set(dispObj.x / SCALE, dispObj.y / SCALE);
					bodyDef.allowSleep = true;
					bodyDef.angle = (dispObj.rotation) * (Math.PI / 180);
					bodyDef.type = b2Body.b2_dynamicBody;
					
					circleShape = new b2CircleShape(dispObj.width/ SCALE*.5);
					fixtureDef.shape = circleShape;
					fixtureDef.friction = 1;
					fixtureDef.density = 6;
					fixtureDef.restitution = 0.4;
					
					body = world.CreateBody(bodyDef);
					body.CreateFixture(fixtureDef);
				}else if (dispObj.name.search("TRlane") == 0 || dispObj.name.search("TRcross") == 0) {//garbage from bulletdrive
					trace("TrackBuilder-- Found traffic stuff :", dispObj.name)
					garbageFromBullet.push(dispObj);
				}
			}
			
			//throw out the garbage
			for (var j:int = 0; j < garbageFromBullet.length; j++) {
				garbageFromBullet[j].parent.removeChild(garbageFromBullet[j]);
			}
		}
		
		
		private function buildCars(trashCar:DisplayObject):void {
			
			var radians:Number = (trashCar.rotation + 90) * (Math.PI / 180);
			var startLineAxis:b2Vec2 = new b2Vec2(Math.cos(radians), Math.sin(radians));
			var axisCenter:b2Vec2 = new b2Vec2(trashCar.x, trashCar.y);
			startLineAxis.Normalize();
			var carIndex:uint = worldSprite.getChildIndex(trashCar);
			var carsDistance:Number = 50;
			
			for (var i:int = 0; i < players.length; i++) {
				trace('adding car:', i);
				var carSprite:Sprite = players[i].carSprite;
				var carPos:b2Vec2 = axisCenter.Copy();
				var axisOffset:b2Vec2 = startLineAxis.Copy();
				axisOffset.Multiply(carsDistance * (i -  (players.length - players.length % 2) / 2 ));
				carPos.Add(axisOffset);
				carSprite.x = carPos.x;
				carSprite.y = carPos.y;
				carSprite.rotation = trashCar.rotation;
				worldSprite.addChild(carSprite);
				worldSprite.setChildIndex(carSprite, carIndex)
						
				cars.push(new PlayableCar(carSprite, new CarParams(), world));
				oracleCars.push(new PlayableCar(carSprite, new CarParams(), oracleWorld, true));
			}
			worldSprite.removeChild(trashCar);
			//trashCar.visible = false;//remove is better buth meh...we might need it for later
		}
		
		private function getAlignedRect(dObj:DisplayObject):Rectangle {
			var origRot:Number = dObj.rotation;
			dObj.rotation = 0;
			var rec:Rectangle = dObj.getBounds(worldSprite)
			dObj.rotation = origRot;
			return rec;
		}
		
	}

}