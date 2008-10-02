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
    import org.amqp.methods.basic.Cancel;
    import org.amqp.methods.basic.CancelOk;
    import org.amqp.methods.basic.Consume;
    import org.amqp.methods.basic.Deliver;
    import org.amqp.methods.queue.Declare;
    import org.amqp.patterns.CorrelatedMessageEvent;
    import org.amqp.patterns.Dispatcher;
    import org.amqp.patterns.SubscribeClient;

    public class SubscribeClientImpl extends AbstractDelegate implements SubscribeClient, BasicConsumer, Dispatcher
    {
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

            topics.put(key, {callback:callback, consumerTag:null});

            if (replyQueue != null) {
                dispatch(key, null);
            }else {
                sendBuffer.buffer(key, null);
            }
        }

        public function unsubscribe(key:String):void {
            var cancel:Cancel = new Cancel();
            var topic:* = topics.getValue(key);
            sessionHandler.unregister(topic.consumerTag);
            topics.remove(key);
        }

        public function dispatch(o:*, callback:Function):void {
            var consume:Consume = new Consume();
            consume.queue = replyQueue;
            consume.noack = true;
            consume.consumertag = replyQueue + ":" + o;
            sessionHandler.register(consume, this);

            bindQueue(exchange, replyQueue, o);
        }

        override protected function onChannelOpenOk(event:ProtocolEvent):void {
            declareExchange(exchange, exchangeType);
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
            sendBuffer.drain();
        }

        public function onConsumeOk(tag:String):void {
          var key:String = tag.split(":")[1];
          var topic:* = topics.getValue(key);

          topic.consumerTag = tag;
          topics.put(key, topic);

          dispatcher.addEventListener(key, topic.callback);
        }

        public function onCancelOk(tag:String):void {}

        public function onDeliver(method:Deliver,
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            var result:* = serializer.deserialize(body);
            dispatcher.dispatchEvent(new CorrelatedMessageEvent(properties.correlationid, result));
        }
    }
}
