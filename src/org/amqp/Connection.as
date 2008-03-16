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
	import flash.net.Socket;
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import org.amqp.impl.SessionImpl;
		
	public class Connection
	{				
		private var sock:Socket;
		private var session0:Session;
		private var sessionManager:SessionManager;
		public var frameMax:int = 0;
		
		public function Connection(state:ConnectionState) {
			session0 = new SessionImpl(this, 0);
			sessionManager = new SessionManager(this);
			handshake(state);		
		}
		
		private function handshake(state:ConnectionState):void {			
			sock = new Socket(state.serverhost, state.port);
			sock.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
            sock.addEventListener(Event.CLOSE, onSocketClose);
            var header:ByteArray = AMQP.generateHeader();
            sock.writeBytes(header, 0, -1);	
		}
		
		public function onSocketClose(event:Event):void {
			trace("Socket closed, do something about this");
		}
		
		/**
		 * Socket timeout waiting for a frame. Maybe missed heartbeat.
		 **/
		public function handleSocketTimeout():void {
		}
		
		/**
		 * This parses frames from the network and hands them to be processed
		 * by a frame handler.
		 **/ 
		public function onSocketData(event:Event):void {
			while (sock.bytesAvailable > 0) {
				var frame:Frame = parseFrame(sock);
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
		
		private function parseFrame(sock:Socket):Frame {
        	var frame:Frame = new Frame();
        	return frame.readFrom(sock) ? frame : null;
        }
		
		public function sendFrame(frame:Frame):void {
            if (sock.connected) {
                trace("Writing frame: " + frame);
                frame.writeTo(sock);
                //lastActivityTime = new Date().valueOf();
            } else {
                throw new Error("AMQConnection main loop not running");
            }
        }
        
        private function maybeSendHeartbeat():void {}
	}
	
}