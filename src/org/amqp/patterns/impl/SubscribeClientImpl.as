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
package org.amqp.patterns.impl
{
    import com.ericfeminella.utils.HashMap;

    import flash.events.EventDispatcher;
    import flash.utils.ByteArray;

    import org.amqp.BasicConsumer;
    import org.amqp.Command;
    import org.amqp.Connection;
    import org.amqp.ProtocolEvent;
    import org.amqp.headers.BasicProperties;
    import org.amqp.methods.basic.Consume;
    import org.amqp.methods.basic.Deliver;
    import org.amqp.methods.queue.Declare;
    import org.amqp.patterns.CorrelatedMessageEvent;
    import org.amqp.patterns.Dispatcher;
    import org.amqp.patterns.SubscribeClient;

    public class SubscribeClientImpl extends AbstractDelegate implements SubscribeClient, BasicConsumer, Dispatcher
    {
        private const CONSUME_HANDLER:Function = consumeHandler;

        private var replyQueue:String = null;
        private var topics:HashMap = new HashMap();
        private var dispatcher:EventDispatcher = new EventDispatcher();
        private var sendBuffer:SendBuffer;

        public function SubscribeClientImpl(c:Connection) {
            super(c);
            sendBuffer = new SendBuffer(this);
        }

        public function subscribe(key:String, callback:Function):void {
            if (topics.containsKey(key)) {
                return;
            }

            topics.put(key, callback);

            if (replyQueue != null) {
                dispatch(key, CONSUME_HANDLER);
            }else {
                sendBuffer.buffer(key, CONSUME_HANDLER);
            }
        }

        public function unsubscribe(key:String):void {
            topics.remove(key);
            dispatcher.removeEventListener(key, CONSUME_HANDLER);
        }

        public function dispatch(o:*, callback:Function):void {
            bindQueue(exchange, replyQueue, o);
            dispatcher.addEventListener(o, callback);
        }

        public function consumeHandler(event:CorrelatedMessageEvent):void {
            var key:String = event.type;

            if (topics.containsKey(key)) {
                var topic:* = topics.getValue(key);
                topic.call(null, event);
            }
        }

        override protected function onChannelOpenOk(event:ProtocolEvent):void {
            declareExchange(exchange,exchangeType);
            setupReplyQueue();
        }

        override protected function declareQueue(q:String):void {
            var queue:org.amqp.methods.queue.Declare = new org.amqp.methods.queue.Declare();
            queue.queue = q;
            queue.autodelete = true;
            sessionHandler.dispatch(new Command(queue));
        }

        override protected function onQueueDeclareOk(event:ProtocolEvent):void {
            replyQueue = getReplyQueue(event);
            var consume:Consume = new Consume();
            consume.queue = replyQueue;
            consume.noack = true;
            sessionHandler.register(consume, this);
            sendBuffer.drain();
        }

        public function onConsumeOk(tag:String):void {}

        public function onCancelOk(tag:String):void {}

        public function onDeliver(method:Deliver,
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            // replyto will always be null since we dont know the queue name
            // ..maybe we set an optional user id in the constructor?
            //if (properties.replyto != replyQueue) {
                var result:* = serializer.deserialize(body);
                dispatcher.dispatchEvent(new CorrelatedMessageEvent(properties.correlationid, result));
            //}
        }
    }
}