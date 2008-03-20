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
	import flash.events.EventDispatcher;
	
	public class BaseCommandReceiver implements CommandReceiver
	{
		private static const CLOSED_EVENT:String = "close-event";
		private static const OPENED_EVENT:String = "open-event";
		
		private var dispatcher:EventDispatcher = new EventDispatcher();
    	
        protected var session:Session;

        public function registerWithSession(s:Session):void {
			session = s;
		}

        public function forceClose():void{}

        public function closeGracefully():void{}

        public function addAfterOpenEventListener(callback:Function):void {
			dispatcher.addEventListener(OPENED_EVENT,callback);
		}
		
		public function removeAfterOpenEventListener(callback:Function):void {
			dispatcher.removeEventListener(OPENED_EVENT,callback);
		}
		
		public function addAfterCloseEventListener(callback:Function):void {
			dispatcher.addEventListener(CLOSED_EVENT,callback);
		}
		
		public function removeAfterCloseEventListener(callback:Function):void {
			dispatcher.removeEventListener(CLOSED_EVENT,callback);
		}
		
		public function receive(cmd:Command):void {}
		
		protected function dispatchAfterOpenEvent():void {
			dispatcher.dispatchEvent(new Event(OPENED_EVENT));
		}
		
		protected function dispatchAfterCloseEvent():void {
			dispatcher.dispatchEvent(new Event(CLOSED_EVENT));
		}
		

	}
}