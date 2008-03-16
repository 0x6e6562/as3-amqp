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
	import com.ericfeminella.utils.Map;
	import com.ericfeminella.utils.HashMap;
	import org.amqp.impl.SessionImpl;
	
	public class SessionManager
	{
		private var connection:Connection;
		private var sessions:Map = new HashMap();
		private var nextChannel:int = 1;
		
		public function SessionManager(con:Connection) {
			connection = con;	
		}
		
		public function lookup(channel:int):Session {
			// TODO look into to not being to use an int as a key
			return sessions.getValue(channel+"") as Session;
		}
		
		public function create():Session {
			var channel:int = allocateChannelNumber();
			var session:Session = new SessionImpl(connection, channel);
			// TODO look into to not being to use an int as a key
			sessions.put(channel +"", session);
			return session;		
		}
		
		private function allocateChannelNumber():int {
			return nextChannel++;	
		}
	}
}