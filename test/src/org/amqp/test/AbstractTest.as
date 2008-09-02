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
package org.amqp.test
{
    import flash.utils.ByteArray;
    import flash.utils.Timer;

    import flexunit.framework.TestCase;

    import org.amqp.Command;
    import org.amqp.Connection;
    import org.amqp.ConnectionParameters;
    import org.amqp.ProtocolEvent;
    import org.amqp.Session;
    import org.amqp.SessionManager;
    import org.amqp.headers.BasicProperties;
    import org.amqp.impl.SessionStateHandler;
    import org.amqp.methods.basic.Publish;
    import org.amqp.methods.channel.Open;
    import org.amqp.methods.exchange.Declare;
    import org.amqp.methods.queue.Bind;
    import org.amqp.methods.queue.BindOk;
    import org.amqp.util.Properties;

    public class AbstractTest extends TestCase
    {
        protected static const TIMEOUT:int = 3000;
        protected static const DELAY:int = 2000;

        protected var x:String = "x";
        protected var q:String = "q";
        protected var x_type:String = "topic";
        protected var bind_key:String = "a.b.c.*"
        protected var routing_key:String = "a.b.c.d"

        protected var connection:Connection;
        protected var baseSession:Session;
        protected var sessionManager:SessionManager;
        protected var sessionHandler:SessionStateHandler;

        public function AbstractTest(methodName:String=null) {
            super(methodName);
        }

        public function buildConnectionParams():ConnectionParameters {
            var params:ConnectionParameters = new ConnectionParameters();
            params.username = "guest";
            params.password = "guest";
            params.vhostpath = "/";
            params.serverhost = "localhost";
            return params;
        }

        override public function setUp():void {
            connection = new Connection(buildConnectionParams());
            baseSession = connection.baseSession;
            sessionManager = connection.sessionManager;
        }

        protected function publish(data:ByteArray):void {
            var publish:Publish = new Publish();
            publish.exchange = x;
            publish.routingkey = routing_key;
            var props:BasicProperties = Properties.getBasicProperties();
            var cmd:Command = new Command(publish, props, data);
            sessionHandler.dispatch(cmd);
            var timer:Timer = new Timer(DELAY, 1);
            timer.start();
        }

        protected function openChannel():void {
            sessionHandler = sessionManager.create();

            var open:Open = new Open();

            var exchange:org.amqp.methods.exchange.Declare = new org.amqp.methods.exchange.Declare();
            exchange.exchange = x;
            exchange.type = x_type;

            var queue:org.amqp.methods.queue.Declare = new org.amqp.methods.queue.Declare();
            queue.queue = q;

            var bind:Bind = new Bind();
            bind.exchange = x;
            bind.queue = q;
            bind.routingkey = bind_key;

            var onBindOk:Function = function(event:ProtocolEvent):void{
                trace("onBindOk called");
            };

            sessionHandler.dispatch(new Command(open));
            sessionHandler.dispatch(new Command(exchange));
            sessionHandler.dispatch(new Command(queue));
            sessionHandler.dispatch(new Command(bind));

            sessionHandler.addEventListener(new BindOk(), addAsync(onBindOk, TIMEOUT) );
        }
    }
}
