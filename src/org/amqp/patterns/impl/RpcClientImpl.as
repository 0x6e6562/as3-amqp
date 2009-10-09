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

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;
    import flash.utils.ByteArray;
    import flash.utils.Timer;

    import org.amqp.BasicConsumer;
    import org.amqp.Command;
    import org.amqp.Connection;
    import org.amqp.ProtocolEvent;
    import org.amqp.error.TimeoutError;
    import org.amqp.headers.BasicProperties;
    import org.amqp.methods.basic.Consume;
    import org.amqp.methods.basic.Deliver;
    import org.amqp.methods.queue.Declare;
    import org.amqp.patterns.CorrelatedMessageEvent;
    import org.amqp.patterns.Dispatcher;
    import org.amqp.patterns.RpcClient;
    import org.amqp.util.Guid;
    import org.amqp.util.Properties;

    public class RpcClientImpl extends AbstractDelegate implements RpcClient, BasicConsumer, Dispatcher
    {
        public var routingKey:String;

        public var replyQueue:String;
        public var consumerTag:String;

        private var dispatcher:EventDispatcher = new EventDispatcher();
        private var sendBuffer:SendBuffer;
        private var calls:HashMap = new HashMap();

        public function RpcClientImpl(c:Connection) {
            super(c);
            sendBuffer = new SendBuffer(this);
        }

        public function send(o:*,callback:Function,timeout:int=-1):void {
            if (null != o) {
                var data:* = {data:o, timeout:timeout};

                if (null == consumerTag) {
                    sendBuffer.buffer(data,callback);
                }
                else {
                    dispatch(data,callback);
                }
            }
        }

        public function dispatch(o:*,callback:Function):void {
            var correlationId:String = Guid.next();
            var data:ByteArray = new ByteArray();
            serializer.serialize(o.data,data);
            var props:BasicProperties = Properties.getBasicProperties();
            props.correlationid = correlationId;
            props.replyto = replyQueue;

            if (o.timeout < 0) {
                dispatcher.addEventListener(correlationId,callback);
            }else {
                dispatcher.addEventListener(correlationId,timeoutHandler);

                var timer:Timer = new Timer(o.timeout,1);
                timer.addEventListener(TimerEvent.TIMER_COMPLETE,timeoutHandler);
                timer.start();

                calls.put(correlationId, {callback:callback, timer:timer});
            }

            publish(exchange,routingKey,data,props);
        }

        public function timeoutHandler(event:Event):void {
            if (event.type == TimerEvent.TIMER_COMPLETE) {
                dispatcher.dispatchEvent(new TimeoutError());
            }else {
                var response:* = calls.getValue(event.type);
                response.timer.stop();
                response.callback.call(null, event);
                calls.remove(event.type);
            }
        }

        public function addTimeoutHandler(callback:Function):void {
            dispatcher.addEventListener(TimeoutError.TIMEOUT_ERROR, callback);
        }

        override protected function onChannelOpenOk(event:ProtocolEvent):void {
            declareExchange(exchange,exchangeType);
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
            sessionHandler.register(consume, this);
        }

        public function onConsumeOk(tag:String):void {
            consumerTag = tag;
            sendBuffer.drain();
        }

        public function onCancelOk(tag:String):void {}

        public function onDeliver(method:Deliver,
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            var result:* = serializer.deserialize(body);
            dispatcher.dispatchEvent(new CorrelatedMessageEvent(properties.correlationid,result));
        }

    }
}