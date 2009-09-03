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

    import flash.utils.ByteArray;

    import org.amqp.BaseCommandReceiver;
    import org.amqp.Command;
    import org.amqp.ConnectionParameters;
    import org.amqp.LifecycleEventHandler;
    import org.amqp.ProtocolEvent;
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
    public class ConnectionStateHandler extends BaseCommandReceiver
    {
        private static const STATE_CLOSED:int = 0;
        private static const STATE_OPEN:int = 1;
        private static const STATE_CLOSE_REQUESTED:int = 2;

        private var connectionParams:ConnectionParameters;
        private var state:int;

        public function ConnectionStateHandler(params:ConnectionParameters){
            connectionParams = params;
            addEventListener(new Start(), onStart);
            addEventListener(new Tune(), onTune);
        }

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

        public function onCloseOk(cmd:Command):void {
            var closeOk:CloseOk = cmd.method as CloseOk;
            state = STATE_CLOSED;
        }

        ////////////////////////////////////////////////////////////////
        // EVENT HANDLING FOR CONNECTION START
        ////////////////////////////////////////////////////////////////

        public function onStart(event:ProtocolEvent):void {
            var start:Start = event.command.method as Start;
            // Doesn't do anything fancy with the properties from Start yet
            var startOk:StartOk = new StartOk();
            var props:Map = new HashMap();

            props.put("product", LongStringHelper.asLongString("AS-AMQC"));
            props.put("version", LongStringHelper.asLongString("0.1"));
            props.put("platform", LongStringHelper.asLongString("AS3"));

            startOk.clientproperties = props;
            startOk.mechanism = "AMQPLAIN";

            var credentials:Map = new HashMap();
            credentials.put("LOGIN", LongStringHelper.asLongString(connectionParams.username));
            credentials.put("PASSWORD", LongStringHelper.asLongString(connectionParams.password));
            var buf:ByteArray = new ByteArray();
            var generator:BinaryGenerator = new BinaryGenerator(buf);
            generator.writeTable(credentials, false);
            startOk.response = new ByteArrayLongString(buf);
            startOk.locale = "en_US";

            session.sendCommand(new Command(startOk));
        }

        public function onTune(event:ProtocolEvent):void {
            var tune:Tune = event.command.method as Tune;
            var tuneOk:TuneOk = new TuneOk();
            tuneOk.channelmax = tune.channelmax;
            tuneOk.framemax = tune.framemax;
            tuneOk.heartbeat = tune.heartbeat;
            session.sendCommand(new Command(tuneOk));
            var open:Open = new Open();
            open.virtualhost = connectionParams.vhostpath;
            open.capabilities = "";
            open.insist = connectionParams.insist;
            session.rpc(new Command(open), onOpenOk);
        }

        public function onOpenOk(event:ProtocolEvent):void {
            var openOk:OpenOk = event.command.method as OpenOk;
            if (state == STATE_CLOSE_REQUESTED) {
                close();
            }
            else {
                state = STATE_OPEN;
            }
            // Call the lifecycle event handlers
            session.emitLifecyleEvent();
        }

        private function close():void {
            var close:Close = new Close();
            close.replycode = 200;
            close.replytext = "Goodbye";
            close.classid = 0;
            close.methodid = 0;
            session.rpc(new Command(close), onCloseOk);
        }
    }
}
