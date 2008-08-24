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
    import org.amqp.Command;
    import org.amqp.CommandReceiver;
    import org.amqp.Connection;
    import org.amqp.Frame;
    import org.amqp.Method;
    import org.amqp.Session;

    public class SessionImpl implements Session
    {
        private var connection:Connection;
        private var channel:int;
        private var commandReceiver:CommandReceiver;
        private var currentCommand:Command;

        public function SessionImpl(con:Connection, ch:int, receiver:CommandReceiver) {
            connection = con;
            channel = ch;
            commandReceiver = receiver;
        }

        public function handleFrame(frame:Frame):void {
            if (currentCommand == null) {
                currentCommand = new Command();
            }
            currentCommand.handleFrame(frame);
            if (currentCommand.isComplete()) {
                commandReceiver.receive(currentCommand);
                currentCommand = new Command();
            }
        }

        public function sendCommand(cmd:Command):void {
            cmd.transmit(channel, connection);
        }

        public function closeGracefully():void {
            commandReceiver.closeGracefully();
        }

        public function forceClose():void {
            commandReceiver.forceClose();
        }

        public function addEventListener(method:Method, fun:Function):void {
            commandReceiver.addEventListener(method, fun);
        }

        public function removeEventListener(method:Method, fun:Function):void {
            commandReceiver.removeEventListener(method, fun);
        }
    }
}