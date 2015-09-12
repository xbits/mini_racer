package engine
{
	
	import Box2D.Collision.*; // bounding box of our world
	import Box2D.Common.Math.*; // for vector(define gravity)
	import Box2D.Dynamics.*; // define bodies and define world
	import Box2D.Dynamics.Joints.*;
	import Box2D.Collision.Shapes.*; // define our shapes
	import flash.display.*; // sprite class
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class RacerEngine extends Sprite
	{
		public const MAX_STEER_ANGLE:Number = Math.PI / 3;
		public const STEER_SPEED:Number = 1.5;
		public const SIDEWAYS_FRICTION_FORCE:Number = 10;
		public const HORSEPOWERS:Number = 180;
		public const CAR_STARTING_POS:b2Vec2 = new b2Vec2(10, 10);
		
		public const rearWheelPosition:b2Vec2 = new b2Vec2(0, 1.90);
		
		public const frontWheelPosition:b2Vec2 = new b2Vec2(0, -1.9);
		public const rightFrontWheelPosition:b2Vec2 = new b2Vec2(1.5, -1.9);
		
		public const DRAW_SCALE:int = 10;
		
		public var engineSpeed:Number = 0;
		public var steeringAngle:Number = 0
		
		public var myWorld:b2World;
		
		public var fixtureDef:b2FixtureDef = new b2FixtureDef();
		
		public var carBody:b2Body;
		public var frontWheel:b2Body;
		public var rearWheel:b2Body;
		public var frontJoint:b2RevoluteJoint;
		public var rightJoint:b2RevoluteJoint;
		
		private var debugText:TextField;
		
		public function RacerEngine():void{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		protected function init(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			debugText = new TextField();
			debugText.width = stage.stageWidth;
			stage.addChild(debugText);
			
			myWorld = new b2World(new b2Vec2(0, 0.0), true);
			
			var boxDef:b2PolygonShape = new b2PolygonShape();
			
			//Create some static stuff
			var staticDef:b2BodyDef = new b2BodyDef();
			staticDef.position.Set(5, 20);
			boxDef.SetAsBox(5, 5);
			fixtureDef.shape = boxDef;
			var body:b2Body = myWorld.CreateBody(staticDef);
			body.CreateFixture(fixtureDef);
			
			staticDef.position.x = 25;
			body = myWorld.CreateBody(staticDef);
			body.CreateFixture(fixtureDef);
			
			staticDef.position.Set(15, 24);
			body = myWorld.CreateBody(staticDef);
			body.CreateFixture(fixtureDef);
			
			
			var carHeight:Number = 2.5;
			var carWidth:Number = 1.5;
			// define our CAR body
			var carBodyDef:b2BodyDef = new b2BodyDef();
			
			boxDef.SetAsBox(carWidth, carHeight*.7);
			carBodyDef.linearDamping = 1;
			carBodyDef.angularDamping = 1;
			carBodyDef.position = CAR_STARTING_POS.Copy();
			carBodyDef.type = b2Body.b2_dynamicBody;
			carBody = myWorld.CreateBody(carBodyDef);
			
			
			//---chassis---
			fixtureDef.shape = boxDef;
			fixtureDef.friction = 1;
			fixtureDef.density = 1;
			fixtureDef.restitution = 0.3;
			carBody.CreateFixture(fixtureDef);
			
			//rear bumper
			var circleDef:b2CircleShape = new b2CircleShape(carWidth);
			circleDef.SetLocalPosition(new b2Vec2(0, carHeight*.7));
			fixtureDef.shape = circleDef;
			fixtureDef.friction = 1;
			fixtureDef.density = 0.1;
			fixtureDef.restitution = 0.3;
			carBody.CreateFixture(fixtureDef);
			//front bumper
			circleDef = new b2CircleShape(carWidth);
			circleDef.SetLocalPosition(new b2Vec2(0, -carHeight*.7));
			fixtureDef.shape = circleDef;
			fixtureDef.friction = 1;
			fixtureDef.density = 0.1;
			fixtureDef.restitution = 0.3;
			carBody.CreateFixture(fixtureDef);
			
			//---define front wheel---
			var frontWheelDef:b2BodyDef = new b2BodyDef();
			frontWheelDef.type = b2Body.b2_dynamicBody;
			frontWheelDef.position = CAR_STARTING_POS.Copy();
			frontWheelDef.position.Add(frontWheelPosition);
			
			boxDef.SetAsBox(0.2, 0.5);
			fixtureDef.shape = boxDef;
			fixtureDef.friction = 0.3;
			fixtureDef.density = 5;
			frontWheel = myWorld.CreateBody(frontWheelDef);
			frontWheel.CreateFixture(fixtureDef);
			
			var rearWheelDef:b2BodyDef = new b2BodyDef();
			rearWheelDef.type = b2Body.b2_dynamicBody;
			rearWheelDef.position = CAR_STARTING_POS.Copy();
			rearWheelDef.position.Add(rearWheelPosition);
			
			boxDef.SetAsBox(0.2, 0.5);
			fixtureDef.shape = boxDef;
			fixtureDef.friction = 0.4;
			fixtureDef.density = 5;
			rearWheel = myWorld.CreateBody(rearWheelDef);
			rearWheel.CreateFixture(fixtureDef);
			
			var fronJointDef:b2RevoluteJointDef = new b2RevoluteJointDef();
			fronJointDef.Initialize(carBody, frontWheel, frontWheel.GetWorldCenter());
			fronJointDef.enableMotor = true;
			fronJointDef.maxMotorTorque = 100;
			
			frontJoint = b2RevoluteJoint(myWorld.CreateJoint(fronJointDef));
			
			var leftRearJointDef:b2PrismaticJointDef = new b2PrismaticJointDef();
			leftRearJointDef.Initialize(carBody, rearWheel, rearWheel.GetWorldCenter(), new b2Vec2(1, 0));
			leftRearJointDef.enableLimit = true;
			leftRearJointDef.lowerTranslation = leftRearJointDef.upperTranslation = 0;
			
			myWorld.CreateJoint(leftRearJointDef);
			
			// debug draw
			debug_draw();
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed_handler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased_handler);
			stage.addEventListener(Event.ENTER_FRAME, Update, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, startLaunch);
			stage.addEventListener(MouseEvent.MOUSE_UP, endLaunch);
		
		}
		
		private function startLaunch(e:MouseEvent):void{
			trace('MOUSE UP');
			addEventListener(Event.ENTER_FRAME, updateLaunch);
		}
		
		private function endLaunch(e:MouseEvent):void{
			graphics.clear();
			
			var clickedPoint:b2Vec2 = new b2Vec2(mouseX / DRAW_SCALE, mouseY / DRAW_SCALE);
			clickedPoint.Subtract(carBody.GetWorldCenter().Copy());
			
			var desiredAngle:Number = Math.atan2(-clickedPoint.x, clickedPoint.y) - (carBody.GetAngle());
			var angleBefore:Number = normalizeAngle(desiredAngle); // (desiredAngle+Math.PI) % (Math.PI * 2) -Math.PI;
			
			desiredAngle = Math.max(-MAX_STEER_ANGLE, Math.min(MAX_STEER_ANGLE, angleBefore)) + carBody.GetAngle();
			
			clickedPoint= new b2Vec2(mouseX / DRAW_SCALE, mouseY / DRAW_SCALE);
			var dif:b2Vec2 = carBody.GetWorldCenter().Copy();
			dif.Subtract(clickedPoint);
			var distance:Number = dif.Length();
			var frontDirection:b2Vec2 = carBody.GetTransform().R.col2.Copy();
			frontDirection.Multiply(-HORSEPOWERS * .5 * distance);
			var pointToApply:b2Vec2 = carBody.GetPosition().Copy();
			var sidewaysAxis:b2Vec2 = carBody.GetTransform().R.col1.Copy();
			var curAngle:Number = frontWheel.GetAngle() - carBody.GetAngle();
			curAngle = normalizeAngle(desiredAngle);
			sidewaysAxis.Multiply(-curAngle * .1);
			sidewaysAxis.Add(carBody.GetPosition());
			carBody.ApplyImpulse(frontDirection, carBody.GetPosition());
			
			removeEventListener(Event.ENTER_FRAME, updateLaunch);
		}
		
		private function updateLaunch(e:Event):void{
			var carX:Number = carBody.GetWorldCenter().x * DRAW_SCALE;
			var carY:Number = carBody.GetWorldCenter().y * DRAW_SCALE;
			
			var gr:Graphics = graphics;
			gr.clear();
			gr.beginFill(0xff0000);
			gr.drawCircle(carX, carY, 10);
			gr.endFill();
			
			gr.lineStyle(3, 0xff0000, 1, true);
			gr.moveTo(carX, carY);
			gr.lineTo(mouseX, mouseY);
			
			var clickedPoint:b2Vec2 = new b2Vec2(mouseX / DRAW_SCALE, mouseY / DRAW_SCALE);
			var wheelAngle:Number = frontWheel.GetAngle();
			clickedPoint.Subtract(carBody.GetWorldCenter().Copy());
			var toTarget:b2Vec2 = clickedPoint; // clickedPoint - body->GetPosition();
			
			var desiredAngle:Number = Math.atan2(-toTarget.x, toTarget.y) - (carBody.GetAngle());
			var angleBefore:Number = normalizeAngle(desiredAngle); // (desiredAngle+Math.PI) % (Math.PI * 2) -Math.PI;
			
			desiredAngle = Math.max(-MAX_STEER_ANGLE, Math.min(MAX_STEER_ANGLE, angleBefore));
			debugText.text = "Des angle: " + desiredAngle + "   before: " + angleBefore;
			frontWheel.SetPositionAndAngle(frontWheel.GetPosition(), desiredAngle + carBody.GetAngle());
		
		}
		
		private function normalizeAngle(a:Number):Number{
			var TWO_PI:Number = Math.PI * 2;
			return a - TWO_PI * Math.floor((a + Math.PI) / TWO_PI);
		}
		
		public function debug_draw():void{
			var m_sprite:Sprite;
			m_sprite = new Sprite();
			addChild(m_sprite);
			var dbgDraw:b2DebugDraw = new b2DebugDraw();
			var dbgSprite:Sprite = new Sprite();
			m_sprite.addChild(dbgSprite);
			dbgDraw.SetSprite(m_sprite);
			dbgDraw.SetDrawScale(DRAW_SCALE);
			//dbgDraw.SetAlpha(1);
			dbgDraw.SetFillAlpha(0.5);
			dbgDraw.SetLineThickness(1);
			dbgDraw.SetFlags(b2DebugDraw.e_shapeBit);
			myWorld.SetDebugDraw(dbgDraw);
			
			var debugGrid:Sprite = new Sprite();
			debugGrid.cacheAsBitmap = true;
			var gr:Graphics = debugGrid.graphics;
			
			for (var i:int = -2000; i < 2000; i += 100)
			{
				gr.lineStyle(1, 0xeeeeee * Math.random());
				gr.moveTo(i, -2000);
				gr.lineTo(i, 2000);
				gr.moveTo(-2000, i);
				gr.lineTo(2000, i);
				
			}
			debugGrid.alpha = 0.5;
			addChild(debugGrid);
		}
		
		//This function applies a "friction" in a direction orthogonal to the body's axis.
		public function killOrthogonalVelocity(targetBody:b2Body):void
		{
			var localPoint:b2Vec2 = new b2Vec2(0, 0);
			var velocity:b2Vec2 = targetBody.GetLinearVelocityFromLocalPoint(localPoint);
			var sidewaysAxis:b2Vec2 = targetBody.GetTransform().R.col2.Copy();
			//var frontAxis:b2Vec2 = targetBody.GetTransform().R.col1.Copy();
			
			sidewaysAxis.Multiply(b2Math.Dot(velocity, sidewaysAxis));
			
			//var sideVel:Number = b2Math.Dot(velocity, frontAxis);
			//var multiplier:Number = 0;
			//if (sideVel > 6) {
			//trace("dot is:", sideVel);
			// multiplier = 0.2;
			
			//	 }
			//frontAxis.Multiply(sideVel*multiplier);
			// sidewaysAxis.Add(frontAxis);
			targetBody.SetLinearVelocity(sidewaysAxis); //targetBody.GetWorldPoint(localPoint));
		
		}
		
		public function keyPressed_handler(e:KeyboardEvent):void
		{
			//trace (e.keyCode);
			//trace (carBody.IsAwake());
			if (e.keyCode == 38)
			{ //UP
				engineSpeed = -HORSEPOWERS;
			}
			if (e.keyCode == 40)
			{ //DOWN
				engineSpeed = HORSEPOWERS;
			}
			if (e.keyCode == 39)
			{ //RIGHT
				steeringAngle = MAX_STEER_ANGLE;
			}
			if (e.keyCode == 37)
			{ //LEFT
				steeringAngle = -MAX_STEER_ANGLE;
			}
		}
		
		public function keyReleased_handler(e:KeyboardEvent):void
		{
			if (e.keyCode == 38 || e.keyCode == 40)
			{
				engineSpeed = 0;
			}
			if (e.keyCode == 37 || e.keyCode == 39)
			{
				steeringAngle = 0;
			}
		}
		
		public function Update(e:Event):void
		{
			myWorld.Step(1 / 30, 8, 8);
			// this is new!
			myWorld.ClearForces();
			// this is new!!
			myWorld.DrawDebugData();
			
			killOrthogonalVelocity(frontWheel);
			killOrthogonalVelocity(rearWheel);
			//killOrthogonalVelocity(carBody)
			//Driving
			var rearDirection:b2Vec2 = rearWheel.GetTransform().R.col2.Copy();
			rearDirection.Multiply(engineSpeed * 2);
			rearWheel.ApplyForce(rearDirection, rearWheel.GetPosition());
			
			var frontDirection:b2Vec2 = frontWheel.GetTransform().R.col2.Copy();
			frontDirection.Multiply(engineSpeed * 5);
			frontWheel.ApplyForce(frontDirection, frontWheel.GetPosition());
			
			//Steering
			var mspeed:Number;
			mspeed = steeringAngle - frontJoint.GetJointAngle();
			// trace (mspeed);
			frontJoint.SetMotorSpeed(mspeed * STEER_SPEED);
			
			//camera
			cameraFollow(carBody);
		
		}
		
		protected function cameraFollow(bodyToFollow:b2Body):void{
			
			var pos_x:Number = bodyToFollow.GetWorldCenter().x * DRAW_SCALE;
			var pos_y:Number = bodyToFollow.GetWorldCenter().y * DRAW_SCALE;
			
			x = stage.stageWidth / 2 - pos_x;
			y = stage.stageHeight / 2 - pos_y;
		}
	}
}