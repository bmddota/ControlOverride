package {
	import flash.display.MovieClip;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.gfx.MouseEventEx;
	import flash.events.Event;
	import flash.ui.Keyboard;
	
	public class ControlOverride extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var keysOn:Boolean = false;
		private var clicksOn:Boolean = false;
		private var streamMovement:Boolean = false;
		private var selectionReport:Boolean = false;
		private var allowChat:Boolean = true;
		private var curSelection:Number = -1;
		
		private var keysDown:Object = {};
		
		private var chatting:Boolean = false;
		
		private var keyFilter:Object = null;
		private var selectFilter:Object = null;
		private var mouseFilter:Object = null;
		
		private var oldChatSay;
		
		//constructor, you usually will use onLoaded() instead
		public function ControlOverride() : void {
			trace("[ControlOverride] ControlOverride UI Constructed!");
		}
		
		
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {			
			trace("[ControlOverride] OnLoaded");
			
			this.visible = true;
			this.clickStage.visible = false;
			this.clickStage.x = -10;
			this.clickStage.y = -50;
			this.clickStage.addEventListener(MouseEvent.MOUSE_DOWN, stageDown);
			this.clickStage.addEventListener(MouseEvent.MOUSE_UP, stageUp);
			this.gameAPI.SubscribeToGameEvent("control_override_config", this.onControlOverrideConfig);
			this.gameAPI.SubscribeToGameEvent("control_override_keyfilter", this.onKeyFilter);
			this.gameAPI.SubscribeToGameEvent("control_override_selectfilter", this.onSelectFilter);
			this.gameAPI.SubscribeToGameEvent("control_override_mousefilter", this.onMouseFilter);
			this.gameAPI.SubscribeToGameEvent("control_override_cvar", this.onCvar);
			
			oldChatSay = globals.Loader_hud_chat.movieClip.gameAPI.ChatSay;
			globals.Loader_hud_chat.movieClip.gameAPI.ChatSay = function(obj:Object, bool:Boolean){
				var type:int = globals.Loader_hud_chat.movieClip.m_nLastMessageMode
				if (bool)
					type = 4
				
				trace("type: " + type);
				if (type != 1)
					oldChatSay(obj, bool);
				else{
					gameAPI.SendServerCommand( "co_say_turnaround " + obj.toString());
					oldChatSay("", bool);
				}
			};
		}
		
		public function onUnloaded() : void {
			trace("[ControlOverride] Unloaded");
			if (clicksOn){
				this.clickStage.visible = false;
				clicksOn = false;
			}
			
			if (keysOn){
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
				keysOn = false;
				globals.GameInterface.RemoveKeyInputConsumer();
			}
			
			if (streamMovement){
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
				streamMovement = false;
			}
			
			if (selectionReport){
				stage.removeEventListener(Event.ENTER_FRAME, frameEnter);
				selectionReport = false;
			}
			
			this.clickStage.removeEventListener(MouseEvent.MOUSE_DOWN, stageDown);
			this.clickStage.removeEventListener(MouseEvent.MOUSE_UP, stageUp);
			
			globals.Loader_hud_chat.movieClip.gameAPI.ChatSay = oldChatSay;
			oldChatSay = null;
		}
		
		public function stageDown(e:MouseEventEx){
			if (mouseFilter && !mouseFilter[e.buttonIdx])
				return;
				
			var arr = globals.Game.ScreenXYToWorld(e.stageX, e.stageY);
			gameAPI.SendServerCommand( "co_mouse_down " + e.buttonIdx + " " + e.stageX + " " + e.stageY + " " + arr[0] + " " + arr[1] + " " + arr[2]);
		}
		
		public function stageUp(e:MouseEventEx){
			if (mouseFilter && !mouseFilter[e.buttonIdx])
				return;
				
			var arr = globals.Game.ScreenXYToWorld(e.stageX, e.stageY);
			gameAPI.SendServerCommand( "co_mouse_up " + e.buttonIdx + " " + e.stageX + " " + e.stageY + " " + arr[0] + " " + arr[1] + " " + arr[2]);
		}
		
		public function mouseMoved(e:MouseEvent){
			var arr = globals.Game.ScreenXYToWorld(e.stageX, e.stageY);
			gameAPI.SendServerCommand( "co_mouse_move " + arr[0] + " " + arr[1] + " " + arr[2]);
		}
		
		public function keyDown(e:KeyboardEvent){
			if (allowChat && e.keyCode == Keyboard.ENTER){
				if (chatting){
					chatting = false;
					return;
				}
				
				chatting = true;
				globals.Loader_hud_chat.movieClip.startMessageMode(e.shiftKey ? 1 : 2, false, "", false, false);
				return;
			}
			if (chatting)
				return;
			
			if ((keyFilter && !keyFilter[e.keyCode]) || keysDown[e.keyCode])
				return;
			
			keysDown[e.keyCode] = true;
			gameAPI.SendServerCommand( "co_key_down " + e.keyCode + " " + e.ctrlKey + " " + e.shiftKey + " " + e.altKey);
		}
		
		public function keyUp(e:KeyboardEvent){
			if (chatting && !keysDown[e.keyCode])
				return;
			
			delete keysDown[e.keyCode];
			if (keyFilter && !keyFilter[e.keyCode])
				return;
			
			gameAPI.SendServerCommand( "co_key_up " + e.keyCode + " " + e.ctrlKey + " " + e.shiftKey + " " + e.altKey);
		}
		
		public function frameEnter(e:Event){
			var local = globals.Players.GetLocalPlayer();
			var arr = globals.Players.GetSelectedEntities(local);
			var select = -1;
			if (arr.length != 0)
				select = arr[0];
				
			if (curSelection != select){
				if (selectFilter == null || selectFilter[select])
					gameAPI.SendServerCommand( "co_select " + select);
					
				curSelection = select;
			}
		}
		
		public function onCvar(obj:Object){
			var pID = obj.pid;
			var cvar = obj.cvar;
			var val = obj.value;
			
			trace("cvar");
			globals.TraceObject(obj, "");
			
			var local = globals.Players.GetLocalPlayer();
			if (local == pID || pID == -1){
				globals.GameInterface.SetConvar(cvar, val);
			}
		}
		
		public function onKeyFilter(obj:Object){
			var pID = obj.pid;
			var filter = obj.filter;
			
			trace("keyfilter");
			globals.TraceObject(obj, "");
			
			var local = globals.Players.GetLocalPlayer();
			if (local == pID || pID == -1){
				if (filter == ""){
					keyFilter = null;
				}
				else{
					var arr:Array = filter.split(',');
					keyFilter = {};
					for (var i=0; i<arr.length; i++){
						keyFilter[arr[i]] = true;
					}
				}
			}
		}
		
		public function onSelectFilter(obj:Object){
			var pID = obj.pid;
			var filter = obj.filter;
			
			trace("selectfilter");
			globals.TraceObject(obj, "");
			
			var local = globals.Players.GetLocalPlayer();
			if (local == pID || pID == -1){
				if (filter == ""){
					selectFilter = null;
				}
				else{
					var arr:Array = filter.split(',');
					selectFilter = {};
					for (var i=0; i<arr.length; i++){
						selectFilter[arr[i]] = true;
					}
				}
			}
		}
		
		public function onMouseFilter(obj:Object){
			var pID = obj.pid;
			var filter = obj.filter;
			
			trace("mousefilter");
			globals.TraceObject(obj, "");
			
			var local = globals.Players.GetLocalPlayer();
			if (local == pID || pID == -1){
				if (filter == ""){
					mouseFilter = null;
				}
				else{
					var arr:Array = filter.split(',');
					mouseFilter = {};
					for (var i=0; i<arr.length; i++){
						mouseFilter[arr[i]] = true;
					}
				}
			}
		}
		
		public function onControlOverrideConfig(obj:Object){
			var pID = obj.pid;
			var clicks = obj.clicks;
			var keys = obj.keys;
			var movement = obj.movement;
			var selection = obj.selection;
			
			globals.TraceObject(obj, "");
			trace(clicksOn + " -- " + keysOn + " -- " + streamMovement + " -- " + selectionReport);
			
			var local = globals.Players.GetLocalPlayer();
			if (local == pID || pID == -1){
				if (clicks && !clicksOn){
					this.clickStage.visible = true;
					clicksOn = true;
				}
				if (!clicks && clicksOn){
					this.clickStage.visible = false;
					clicksOn = false;
				}
				
				if (keys && !keysOn){
					stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
					stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
					globals.GameInterface.AddKeyInputConsumer();
					keysOn = true;
				}
				if (!keys && keysOn){
					stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
					stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
					globals.GameInterface.RemoveKeyInputConsumer();
					keysOn = false;
				}
				
				if (movement && !streamMovement){
					stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
					streamMovement = true;
				}
				if (!movement && streamMovement){
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
					streamMovement = false;
				}
				
				if (selection && !selectionReport){
					stage.addEventListener(Event.ENTER_FRAME, frameEnter);
					selectionReport = true;
					var arr = globals.Players.GetSelectedEntities(local);
					if (arr.length == 0)
						curSelection = -1;
					else
						curSelection = arr[0];
					
				}
				if (!selection && selectionReport){
					stage.removeEventListener(Event.ENTER_FRAME, frameEnter);
					selectionReport = false;
				}
				
			}
			
			trace(clicksOn + " -- " + keysOn + " -- " + streamMovement + " -- " + selectionReport);
		}
		
		public function onResize(re:ResizeManager) : * {
			var currentRatio:Number =  re.ScreenWidth / re.ScreenHeight;
			var divided:Number;
			var originalHeight:Number = 900;
					
			if(currentRatio < 1.5)
			{
				// 4:3
				divided = currentRatio * 3 / 4.0;
			}
			else if(re.Is16by9()){
				// 16:9
				divided = currentRatio * 9 / 16.0;
			} else {
				// 16:10
				divided = currentRatio * 10 / 16.0;
			}
							
			var correctedRatio:Number =  re.ScreenHeight / originalHeight * divided;
			
			this.clickStage.scaleX = correctedRatio * 1.5;
			this.clickStage.scaleY = correctedRatio * 1.5;
		}
	}
}