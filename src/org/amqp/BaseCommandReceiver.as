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
    import flash.events.EventDispatcher;

    public class BaseCommandReceiver implements CommandReceiver
    {
        private var dispatcher:EventDispatcher = new EventDispatcher();

        protected var session:Session;

        public function registerWithSession(s:Session):void {
            session = s;
        }

        public function forceClose():void{}

        public function closeGracefully():void{}

        public function addEventListener(method:Method, fun:Function):void {
            dispatcher.addEventListener(ProtocolEvent.eventType(method), fun);
        }

        public function removeEventListener(method:Method, fun:Function):void {
            dispatcher.removeEventListener(ProtocolEvent.eventType(method), fun);
        }

        public function receive(cmd:Command):void {
            dispatcher.dispatchEvent(new ProtocolEvent(cmd));
        }
    }
}
