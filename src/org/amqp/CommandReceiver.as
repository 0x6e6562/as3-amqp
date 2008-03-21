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
	/**
	 * A command receiver is a component that is able to process arbritrary
	 * commands that come from a transport.
	 **/
	public interface CommandReceiver
	{
		/**
		 * General callback function to process commands coming from a transport.
		 **/
		function receive(cmd:Command):void;
		
		/**
		 * This notifies the receiver that the underlying session should be closed
		 * in a graceful fashion.
		 **/
		function closeGracefully():void;
		
		/**
		 * This notifies the receiver that the underlying session has been closed
		 * abruptly (e.g. due to a Socket error) and
		 * therefore no further commands can be received or sent.
		 **/
		function forceClose():void;
		
		function registerWithSession(s:Session):void;
		
		function addEventListener(method:Method, callback:Function):void;
		
		function removeEventListener(method:Method, callback:Function):void;
	}
}