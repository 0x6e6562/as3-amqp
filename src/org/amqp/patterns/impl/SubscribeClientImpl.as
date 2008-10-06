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
    import de.polygonal.ds.HashMap;

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
    import org.amqp.methods.queue.Unbind;
    import org.amqp.patterns.CorrelatedMessageEvent;
    import org.amqp.patterns.Dispatcher;
    import org.amqp.patterns.SubscribeClient;

    public class SubscribeClientImpl extends AbstractDelegate implements SubscribeClient, BasicConsumer, Dispatcher
    {
        public var reservedExchange:Boolean;

        public var replyQueue:String = null;
        private var topics:HashMap = new HashMap();
        private var dispatcher:EventDispatcher = new EventDispatcher();
        private var sendBuffer:SendBuffer;

        public function SubscribeClientImpl(c:Connection) {
            super(c);
            sendBuffer = new SendBuffer(this);
            reservedExchange = false;
        }

        public function subscribe(key:String, callback:Function):void {
            if (topics.containsKey(key)) {
                return;
            }

            topics.insert(key, {callback:callback});

            if (replyQueue != null) {
                dispatch(key, null);
            }else {
                sendBuffer.buffer(key, null);
            }
        }

        public function unsubscribe(key:String):void {
            var unbind:Unbind = new Unbind();
            var topic:* = topics.find(key);
            unbind.exchange = exchange;
            unbind.queue = replyQueue;
            unbind.routingkey = key;

            sessionHandler.rpc(new Command(unbind), onUnbindOk);

            dispatcher.removeEventListener(key, topic.callback);
            topics.remove(key);
        }

        public function dispatch(o:*, callback:Function):void {
            bindQueue(exchange, replyQueue, o);

            var topic:* = topics.find(o);
            topics.insert(o, topic);
            dispatcher.addEventListener(o, topic.callback);
        }

        override protected function onChannelOpenOk(event:ProtocolEvent):void {
            if (reservedExchange == false) {
                declareExchange(exchange, exchangeType);
            }
            setupReplyQueue();
        }

        override protected function declareQueue(q:String):void {
            var queue:Declare = new Declare();
            queue.queue = q;
            queue.autodelete = true;
            sessionHandler.rpc(new Command(queue), onQueueDeclareOk);
        }

        override protected function onQueueDeclareOk(event:ProtocolEvent):void {
            replyQueue = getReplyQueue(event);

            var consume:Consume = new Consume();
            consume.queue = replyQueue;
            consume.noack = true;
            consume.consumertag = replyQueue;
            sessionHandler.register(consume, this);

            sendBuffer.drain();
        }

        public function onConsumeOk(tag:String):void {}

        public function onCancelOk(tag:String):void {}

        public function onUnbindOk(event:ProtocolEvent):void {}

        public function onDeliver(method:Deliver,
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            trace("onDeliver");
            var result:* = serializer.deserialize(body);

            var topic:String = matchTopic(properties.correlationid || method.routingkey);
            if (topic != null) {
                dispatcher.dispatchEvent(new CorrelatedMessageEvent(topic, result, method));
            }
        }

        private function matchTopic(topic:String):String {
            var pattern:String;

            for each (var key:String in topics.getKeySet()) {
                pattern = key.replace("\.", "\\.");
                pattern = pattern.replace("*", "(.+)");
                pattern = "^" + pattern + "$";

                if (topic.search(pattern) >= 0) {
                    return key;
                }
            }

            return null;
        }
    }
}
