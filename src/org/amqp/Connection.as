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
package org.amqp
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import org.amqp.impl.ConnectionStateHandler;
	import org.amqp.impl.SessionImpl;
	import org.amqp.io.SocketDelegate;
	import org.amqp.io.TLSDelegate;
	import org.amqp.methods.connection.CloseOk;
		
	public class Connection
	{				
		private var shuttingDown:Boolean = false;
		private var delegate:IODelegate;
		private var session0:Session;
		private var connectionState:ConnectionState;
		public var sessionManager:SessionManager;
		public var frameMax:int = 0;
		
		public function Connection(state:ConnectionState) {
			connectionState = state;
			var stateHandler:ConnectionStateHandler = new ConnectionStateHandler(state);

			session0 = new SessionImpl(this, 0, stateHandler);
			session0.addEventListener(new CloseOk(), afterGracefulClose);			
			stateHandler.registerWithSession(session0);
			
			sessionManager = new SessionManager(this);
			
			if (state.useTLS) {
				delegate = new TLSDelegate;
			}
			else {
				delegate = new SocketDelegate();
			}
									
			delegate.addEventListener(Event.CONNECT, onSocketConnect);
			delegate.addEventListener(Event.CLOSE, onSocketClose);
			delegate.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
			delegate.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);		
		}
		
		public function get baseSession():Session {
			return session0;
		}
		
		public function start():void {
			delegate.open(connectionState);
		}				
        
        public function onSocketConnect(event:Event):void {
        	var header:ByteArray = AMQP.generateHeader();
            delegate.writeBytes(header, 0, header.length);
        }
        
        public function onSocketClose(event:Event):void {        	
			handleForcedShutdown();
		}
		
		public function onSocketError(event:IOErrorEvent):void {
			trace(event.text);
		}
        
        public function close(reason:Object = null):void {
        	if (!shuttingDown) {        	
	        	if (delegate.isConnected()) {
	        		handleGracefulShutdown();	        		
	        	}
	        	else {
	        		handleForcedShutdown();
	        	}
        	}
        }
        
        public function afterGracefulClose(event:Event):void {
        	delegate.close();
        }
				
		/**
		 * Socket timeout waiting for a frame. Maybe missed heartbeat.
		 **/
		public function handleSocketTimeout():void {
			handleForcedShutdown();
		}
		
		private function handleForcedShutdown():void {
			if (!shuttingDown) {
				shuttingDown = true;
				trace("Calling handleForcedShutdown from connection");
				sessionManager.forceClose();
				session0.forceClose();
			}
		}
		
		private function handleGracefulShutdown():void {
			if (!shuttingDown) {
				shuttingDown = true;
				trace("Calling handleGracefulShutdown from connection, so = " + delegate.isConnected());
				sessionManager.closeGracefully();
				session0.closeGracefully();
			}
		}
		
		/**
		 * This parses frames from the network and hands them to be processed
		 * by a frame handler.
		 **/ 
		public function onSocketData(event:Event):void {
			while (delegate.isConnected() && delegate.bytesAvailable > 0) {
				var frame:Frame = parseFrame(delegate);
				maybeSendHeartbeat();
				if (frame != null) {
                	// missedHeartbeats = 0;
                		if (frame.type == AMQP.FRAME_HEARTBEAT) {
                			// just ignore this for now
                		} else if (frame.channel == 0) {
                			session0.handleFrame(frame);                			
               			} else {
	               			var session:Session = sessionManager.lookup(frame.channel);
	               			session.handleFrame(frame);
               			}               			
    			} else {
    				handleSocketTimeout();
    			}					
			}
		}
		
		private function parseFrame(delegate:IODelegate):Frame {
        	var frame:Frame = new Frame();
        	return frame.readFrom(delegate) ? frame : null;
        }
		
		public function sendFrame(frame:Frame):void {
            if (delegate.isConnected()) {
                frame.writeTo(delegate);
                //lastActivityTime = new Date().valueOf();
            } else {
                throw new Error("Connection main loop not running");
            }
        }
        
        public function addSocketEventListener(type:String, listener:Function):void {
			delegate.addEventListener(type, listener);
		}
		
		public function removeSocketEventListener(type:String, listener:Function):void {
			delegate.removeEventListener(type, listener);
		}
        
        private function maybeSendHeartbeat():void {}
	}
	
}