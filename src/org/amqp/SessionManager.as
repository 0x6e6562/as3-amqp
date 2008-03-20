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
	import de.polygonal.ds.HashMap;
	import de.polygonal.ds.Iterator;
	
	import org.amqp.impl.SessionImpl;
	import org.amqp.impl.SessionStateHandler;
	
	public class SessionManager
	{
		private var connection:Connection;
		private var sessions:HashMap = new HashMap();
		private var nextChannel:int = 1;
		
		public function SessionManager(con:Connection) {
			connection = con;	
		}
		
		public function lookup(channel:int):Session {
			return sessions.find(channel) as Session;
		}
		
		public function create(stateHandler:SessionStateHandler = null):SessionStateHandler {
			var channel:int = allocateChannelNumber();
			
			if (null == stateHandler) {
				stateHandler = new SessionStateHandler();
			}
			
			var session:Session = new SessionImpl(connection, channel, stateHandler);
			stateHandler.registerWithSession(session);
			sessions.insert(channel, session);
			
			var s:Session = sessions.find(channel);
			
			return stateHandler;		
		}
		
		private function allocateChannelNumber():int {
			return nextChannel++;	
		}
		
		public function closeGracefully():void {
        	var it:Iterator = sessions.getIterator();
			while (it.hasNext()) {
				var session:Session = it.next() as Session;
				session.closeGracefully();
			}
			sessions.clear();
        }
		
		public function forceClose():void {
			var it:Iterator = sessions.getIterator();
			while (it.hasNext()) {
				var session:Session = it.next() as Session;
				session.forceClose();
			}
			sessions.clear();
		}
	}
}