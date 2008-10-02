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
    import flash.utils.ByteArray;

    import org.amqp.Command;
    import org.amqp.Connection;
    import org.amqp.ProtocolEvent;
    import org.amqp.headers.BasicProperties;
    import org.amqp.impl.SessionStateHandler;
    import org.amqp.methods.basic.Publish;
    import org.amqp.methods.channel.Open;
    import org.amqp.methods.connection.OpenOk;
    import org.amqp.methods.exchange.Declare;
    import org.amqp.methods.queue.Bind;
    import org.amqp.methods.queue.DeclareOk;
    import org.amqp.patterns.Serializer;
    import org.amqp.util.Properties;

    public class AbstractDelegate
    {
        public var exchange:String;
        public var exchangeType:String;
        public var realm:String;
        public var connection:Connection;

        public var serializer:Serializer;

        protected var sessionHandler:SessionStateHandler;

        public function AbstractDelegate(c:Connection) {
            connection = c;
            connection.start();
            connection.baseSession.addEventListener(new OpenOk(), openChannel);
        }

        protected function openChannel(event:ProtocolEvent):void {
            sessionHandler = connection.sessionManager.create();
            var open:Open = new Open();
            sessionHandler.dispatch(new Command(open));
            sessionHandler.addEventListener(new org.amqp.methods.channel.OpenOk(), onChannelOpenOk);
        }

        protected function publish(x:String, routing_key:String, data:ByteArray, properties:BasicProperties = null):void {
            var publish:Publish = new Publish();
            publish.exchange = x;
            publish.routingkey = routing_key;
            var props:BasicProperties = (properties == null) ? Properties.getBasicProperties() : properties;
            var cmd:Command = new Command(publish, props, data);
            sessionHandler.dispatch(cmd);
        }

        protected function declareExchange(x:String, type:String):void {
            var exchange:org.amqp.methods.exchange.Declare = new org.amqp.methods.exchange.Declare();
            exchange.exchange = x;
            exchange.type = type;
            sessionHandler.dispatch(new Command(exchange));
        }

        protected function declareQueue(q:String):void {
            var queue:org.amqp.methods.queue.Declare = new org.amqp.methods.queue.Declare();
            queue.queue = q;
            sessionHandler.dispatch(new Command(queue));
        }

        protected function bindQueue(x:String,q:String, key:String):void {
            var bind:Bind = new Bind();
            bind.exchange = x;
            bind.queue = q;
            bind.routingkey = key;
            sessionHandler.dispatch(new Command(bind));
        }

        protected function setupReplyQueue():void {
            declareQueue("");
            sessionHandler.addEventListener(new DeclareOk(),onQueueDeclareOk);
        }

        protected function getReplyQueue(event:ProtocolEvent):String {
            var declareOk:DeclareOk = event.command.method as DeclareOk;
            return declareOk.queue;
        }


        /**
         * This should be overriden by specializing classes
         **/
        protected function onChannelOpenOk(event:ProtocolEvent):void {}

        /**
         * This should be overriden by specializing classes
         **/
        protected function onQueueDeclareOk(event:ProtocolEvent):void {}

    }
}
