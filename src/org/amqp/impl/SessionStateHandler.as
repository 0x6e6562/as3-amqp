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
    import de.polygonal.ds.ArrayedQueue;
    import de.polygonal.ds.HashMap;
    import de.polygonal.ds.PriorityQueue;

    import flash.utils.ByteArray;

    import org.amqp.BaseCommandReceiver;
    import org.amqp.BasicConsumer;
    import org.amqp.Command;
    import org.amqp.ConsumerRegistry;
    import org.amqp.Method;
    import org.amqp.ProtocolEvent;
    import org.amqp.SynchronousCommandClient;
    import org.amqp.error.IllegalStateError;
    import org.amqp.headers.BasicProperties;
    import org.amqp.headers.ChannelProperties;
    import org.amqp.headers.ConnectionProperties;
    import org.amqp.methods.basic.Cancel;
    import org.amqp.methods.basic.CancelOk;
    import org.amqp.methods.basic.Consume;
    import org.amqp.methods.basic.ConsumeOk;
    import org.amqp.methods.basic.Deliver;
    import org.amqp.methods.channel.CloseOk;
    import org.amqp.methods.channel.OpenOk;

    public class SessionStateHandler extends BaseCommandReceiver implements SynchronousCommandClient, ConsumerRegistry
    {
        private static const STATE_CLOSED:int = 0;
        private static const STATE_CONNECTION:int = new ConnectionProperties().getClassId();
        private static const STATE_CHANNEL:int = new ChannelProperties().getClassId();
        private static const STATE_OPEN:int = STATE_CHANNEL + 1;

        protected var state:int = STATE_CONNECTION;
        protected var QUEUE_SIZE:int = 100;

        protected var pendingConsumers:ArrayedQueue = new ArrayedQueue(QUEUE_SIZE);
        protected var consumers:HashMap = new HashMap();

        public function SessionStateHandler(){
            // TODO Look into whether this is really necessary
            addEventListener(new Deliver(), onDeliver);
        }

        override public function forceClose():void{
            trace("forceClose called");
            transition(STATE_CLOSED);
        }

        override public function closeGracefully():void{
            trace("closeGracefully called");
            transition(STATE_CLOSED);
        }

        public function rpc(cmd:Command, fun:Function):void {
            session.rpc(cmd, fun);
        }

        private function cancelRpcHandler(method:Method, fun:Function):void {
            removeEventListener(method, fun);
        }

        public function dispatch(cmd:Command):void {
            session.sendCommand(cmd, null);
        }

        public function register(consume:Consume, consumer:BasicConsumer):void{
            pendingConsumers.enqueue(consumer);
            rpc(new Command(consume), onConsumeOk);
        }

        public function unregister(tag:String):void{
            var cancel:Cancel = new Cancel();
            cancel.consumertag = tag;
            rpc(new Command(cancel), onCancelOk);
        }

        public function onConsumeOk(event:ProtocolEvent):void {
            var consumeOk:ConsumeOk = event.command.method as ConsumeOk;
            var consumer:BasicConsumer = pendingConsumers.dequeue() as BasicConsumer;
            var tag:String = consumeOk.consumertag;
            consumers.insert(tag, consumer);
            consumer.onConsumeOk(tag);
        }

        public function onCancelOk(event:ProtocolEvent):void {
            var cancelOk:CancelOk = event.command.method as CancelOk;
            var tag:String = cancelOk.consumertag;
            var consumer:BasicConsumer = consumers.remove(tag);
            if (null != consumer) {
                consumer.onCancelOk(tag);
            }
        }

        public function onDeliver(event:ProtocolEvent):void {
            var deliver:Deliver = event.command.method as Deliver;
            var props:BasicProperties = event.command.contentHeader as BasicProperties;
            var body:ByteArray = event.command.content as ByteArray;
            body.position = 0;
            var consumer:BasicConsumer = consumers.find(deliver.consumertag) as BasicConsumer;
            consumer.onDeliver(deliver, props, body);
        }

        public function onOpenOk(event:ProtocolEvent):void {
            transition(STATE_OPEN);
        }

        /**
         *  This frees up any resources associated with this session.
         **/
        public function onCloseOk(event:ProtocolEvent):void {
            transition(STATE_CONNECTION);
        }

        /**
         * Cheap hack of an FSM
         **/
        private function transition(newState:int):void {
            switch (state) {
                case STATE_CLOSED: { stateError(newState); }
                default: state = newState;
            }
        }

        /**
         * Renders an error according to the attempted transition.
         **/
        private function stateError(newState:int):void {
            throw new IllegalStateError("Illegal state transition: " + state + " ---> " + newState)
        }
    }
}
							