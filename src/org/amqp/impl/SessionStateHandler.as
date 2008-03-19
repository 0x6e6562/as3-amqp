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
	import de.polygonal.ds.Iterator;
	import de.polygonal.ds.PriorityQueue;
	
	import org.amqp.BaseCommandReceiver;
	import org.amqp.Command;
	import org.amqp.CommandDispatcher;
	import org.amqp.Method;
	import org.amqp.error.IllegalStateError;
	import org.amqp.headers.AccessProperties;
	import org.amqp.headers.ChannelProperties;
	import org.amqp.headers.ConnectionProperties;
	import org.amqp.methods.access.Request;
	import org.amqp.methods.access.RequestOk;

	public class SessionStateHandler extends BaseCommandReceiver implements CommandDispatcher
	{		
		private static const STATE_CLOSED:int = 0;
		
		private static const STATE_CONNECTION:int = new ConnectionProperties().getClassId();
		private static const STATE_CHANNEL:int = new ChannelProperties().getClassId();
		private static const STATE_ACCESS:int = new AccessProperties().getClassId();
		
		
		//protected var realm:String;
		protected var ticket:int;		
		protected var state:int = STATE_CONNECTION;
		protected var queueSize:int = 100;
		protected var queue:PriorityQueue = new PriorityQueue(queueSize);
		
		public function SessionStateHandler(){
		}
		
		override public function forceClose():void{
			trace("forceClose called");
			transition(STATE_CLOSED);
		}
		
		override public function closeGracefully():void{
			trace("closeGracefully called");
			transition(STATE_CLOSED);
		}
		
		public function dispatch(cmd:Command):void {			
			switch(state) {
				case STATE_CLOSED: { stateError(cmd.method.getClassId()); }
				case STATE_CONNECTION: {
					if (cmd.method.getClassId() > STATE_CHANNEL) {
						enqueueCommand(cmd);
					}
				}
				case STATE_CHANNEL: {
					if (cmd.method.getClassId() > STATE_ACCESS) {
						enqueueCommand(cmd);
					}
				}
				default: {
					flushQueue();
					session.sendCommand(cmd);
				}
			}										
		}
		
		override public function onChannelOpenOk(cmd:Command):void {
			transition(STATE_CHANNEL);			
			var accessRequest:Request = new Request();			
			var it:Iterator = queue.getIterator();
			while (it.hasNext()) {
				var c:Command = it.next() as Command;		
				var method:Method = c.method;		
				if (method.getMethodId() == accessRequest.getMethodId() &&
					method.getClassId() == accessRequest.getClassId()) {
					if (queue.remove(c)) {
						dispatch(cmd);
					}		
					else {
						throw new Error("Could not remove " + method.getMethodId() + " from q");
					}
				}
				
			}			
		}
		
		override public function onAccessRequestOk(cmd:Command):void {
			var accessRequestOk:RequestOk = cmd.method as RequestOk;
			ticket = accessRequestOk._ticket;
			transition(STATE_ACCESS);	
		}
		
		/**
		 *  This frees up any resources associated with this session.
		 **/
		override public function onChannelCloseOk(cmd:Command):void {
			ticket = -1;
			transition(STATE_CONNECTION);
		}
		
		/**
		 * Enqueues a command in order of ascending class id.
		 **/
		private function enqueueCommand(cmd:Command):void {
			if ( !queue.enqueue(cmd) ) {
				throw new Error("Priority queue size exhausted, maybe you should reallocate?");
			}
		}
		
		private function flushQueue():void {
			while (!queue.isEmpty()) {
				var cmd:Command = queue.dequeue() as Command;
				
			}
		}
		
		/**
		 * Cheap hack of an FSM
		 **/
		private function transition(newState:int):void {
			switch (state) {				
				case STATE_CLOSED: { stateError(newState); }				
				case STATE_CONNECTION: {
					if (newState == STATE_ACCESS) {
						stateError(newState);
					}
					else {
						state = newState;
					}
				}
				case STATE_ACCESS: {
					if (newState == STATE_CHANNEL) {
						stateError(newState);
					}
					else {
						state = newState;
					}
				}
				default: state = newState;
			}
		}
		
		/**
		 * Renders an error according to the attempted transition.
		 **/
		private function stateError(newState:int):void {
			throw new IllegalStateError(state + " ---> " + newState)	
		}
	}
}