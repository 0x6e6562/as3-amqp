/**
 * ---------------------------------------------------------------------------
 *   Copyright (C) 2008 0x6e6562
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 * ---------------------------------------------------------------------------
 **/
package org.amqp.impl
{
	import com.ericfeminella.utils.HashMap;
	import com.ericfeminella.utils.Map;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import org.amqp.Command;
	import org.amqp.ConnectionState;
	import org.amqp.GeneratedCommandReceiver;
	import org.amqp.methods.connection.Close;
	import org.amqp.methods.connection.CloseOk;
	import org.amqp.methods.connection.Open;
	import org.amqp.methods.connection.OpenOk;
	import org.amqp.methods.connection.Start;
	import org.amqp.methods.connection.StartOk;
	import org.amqp.methods.connection.Tune;
	import org.amqp.methods.connection.TuneOk;
	import org.amqp.util.BinaryGenerator;
	import org.amqp.util.LongStringHelper;

	/**
	 * This is a very simple state machine that performs the connection
	 * initialization part of the protocol.
	 * 
	 * These are it's interactions with the server:
	 * 
	 * 1. Receive connection.Start
	 * 2. Send connection.StartOk
	 * 3. Receive connection.Tune
	 * 4. Send connection.TuneOk
	 * 5. Send connection.Open
	 * 6. Receive connection.OpenOk
	 **/
	public class ConnectionStateHandler extends GeneratedCommandReceiver
	{
		private static const STATE_CLOSED:int = 0;
		private static const STATE_OPEN:int = 1;
		private static const STATE_CLOSE_REQUESTED:int = 2;
		
		private static const CLOSED_EVENT:String = "connection-closed";
		private static const OPENED_EVENT:String = "connection-opened";
		
		private var connectionState:ConnectionState;
		private var state:int;
		private var dispatcher:EventDispatcher = new EventDispatcher();
		
		public function ConnectionStateHandler(constate:ConnectionState){
			connectionState = constate;
		}
		/*
		override public function addAfterOpenEventListener(callback:Function):void {
			dispatcher.addEventListener(OPENED_EVENT,callback);
		}
		
		override public function removeAfterOpenEventListener(callback:Function):void {
			dispatcher.removeEventListener(OPENED_EVENT,callback);
		}
		
		override public function addAfterCloseEventListener(callback:Function):void {
			dispatcher.addEventListener(CLOSED_EVENT,callback);
		}
		
		override public function removeAfterCloseEventListener(callback:Function):void {
			dispatcher.removeEventListener(CLOSED_EVENT,callback);
		}
		*/
		
		
		override public function forceClose():void {
			trace("forceClose called");
		}
		
		override public function closeGracefully():void {			
			if (state == STATE_OPEN) {			
				close();	
			}
			else {
				state = STATE_CLOSE_REQUESTED;
			}			
		}
		
		override public function onConnectionCloseOk(cmd:Command):void {
			var closeOk:CloseOk = cmd.method as CloseOk;
			dispatchAfterCloseEvent();
			state = STATE_CLOSED;
		}
		
		////////////////////////////////////////////////////////////////
		// EVENT HANDLING FOR CONNECTION START
		////////////////////////////////////////////////////////////////
		
		override public function onConnectionStart(cmd:Command):void {
			var start:Start = cmd.method as Start;
			// Doesn't do anything fancy with the properties from Start yet
			var startOk:StartOk = new StartOk();
			var props:Map = new HashMap();
		    
		    props.put("product", LongStringHelper.asLongString("AS-AMQC"));
		    props.put("version", LongStringHelper.asLongString("0.1"));
		    props.put("platform", LongStringHelper.asLongString("AS3"));
		    
		    startOk._clientproperties = props;
		    startOk._mechanism = "AMQPLAIN";
		    
		    var credentials:Map = new HashMap();
		    credentials.put("LOGIN", LongStringHelper.asLongString(connectionState.username));
		    credentials.put("PASSWORD", LongStringHelper.asLongString(connectionState.password));
		    var buf:ByteArray = new ByteArray();
		    var generator:BinaryGenerator = new BinaryGenerator(buf);
		    generator.writeTable(credentials, false);
		    startOk._response = new ByteArrayLongString(buf);
		    startOk._locale = "en_US";
			
			send(new Command(startOk));	
		}
		
		override public function onConnectionTune(cmd:Command):void {
			var tune:Tune = cmd.method as Tune;
			var tuneOk:TuneOk = new TuneOk();
			tuneOk._channelmax = tune._channelmax;
			tuneOk._framemax = tune._framemax;
			tuneOk._heartbeat = tune._heartbeat;
			send(new Command(tuneOk));
			var open:Open = new Open();
			open._virtualhost = connectionState.vhostpath;
			open._capabilities = "";
			open._insist = false;
			send(new Command(open));	
		}
		
		override public function onConnectionOpenOk(cmd:Command):void {
			var openOk:OpenOk = cmd.method as OpenOk;
			// Maybe do something with the knownhosts?
			//openOk._knownhosts;	
			if (state == STATE_CLOSE_REQUESTED) {
				close();
			}		
			else {
				state = STATE_OPEN;
				dispatchAfterOpenEvent();
			}						
		}
		
		private function close():void {
			var close:Close = new Close();
			close._replycode = 200;
			close._replytext = "Goodbye";
			close._classid = 0;
			close._methodid = 0;
			send(new Command(close));
		}
		
		private function send(cmd:Command):void {
			session.sendCommand(cmd);
		}
		/*
		private function dispatchAfterOpenEvent():void {
			dispatcher.dispatchEvent(new Event(OPENED_EVENT));
		}
		
		private function dispatchAfterCloseEvent():void {
			dispatcher.dispatchEvent(new Event(CLOSED_EVENT));
		}
		*/
	}
}