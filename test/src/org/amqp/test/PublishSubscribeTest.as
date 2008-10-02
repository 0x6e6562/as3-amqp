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
    import flash.events.TimerEvent;
    import flash.utils.ByteArray;
    import flash.utils.Timer;

    import flexunit.framework.TestSuite;

    import org.amqp.BasicConsumer;
    import org.amqp.Command;
    import org.amqp.LifecycleEventHandler;
    import org.amqp.ProtocolEvent;
    import org.amqp.headers.BasicProperties;
    import org.amqp.methods.basic.Consume;
    import org.amqp.methods.basic.Deliver;
    import org.amqp.methods.channel.Open;
    import org.amqp.methods.queue.Declare;

    public class PublishSubscribeTest extends AbstractTest implements BasicConsumer, LifecycleEventHandler
    {
        protected var consumerTag:String;

        public function PublishSubscribeTest(methodName:String=null)
        {
            super(methodName);
            x = "";
            q = "q-" + new Date().getMilliseconds();
            routing_key = q;
        }

        public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new PublishSubscribeTest("testPublish"));
            return myTS;
        }

        public function testPublish():void {
            connection.start();
            connection.baseSession.registerLifecycleHandler(this);
        }

        public function afterOpen():void {
            openChannel(runPublishTest);
        }

        override protected function openChannel(callback:Function):void {

            var whoCares:Function = function(event:ProtocolEvent):void{
                trace("whoCares called");
            };

            sessionHandler = sessionManager.create();
            var open:Open = new Open();
            var queue:org.amqp.methods.queue.Declare = new org.amqp.methods.queue.Declare();
            queue.queue = q;
            sessionHandler.rpc(new Command(open), whoCares);
            sessionHandler.rpc(new Command(queue), callback);
        }

        public function runPublishTest(event:ProtocolEvent):void {
            var consume:Consume = new Consume();
            consume.queue = q;
            consume.noack = true;
            sessionHandler.register(consume, this);
            var data:ByteArray = new ByteArray();
            data.writeUTF("hello, world");
            publish(data);

            var timer:Timer;

            timer = new Timer(DELAY, 1);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, cancel);
            timer.start();

            timer = new Timer(DELAY, 1);
            timer.start();
        }

        public function cancel(event:TimerEvent):void {
            trace("Initiating cancellation");
            assertNotNull(consumerTag);
            sessionHandler.unregister(consumerTag);
        }

        public function onConsumeOk(tag:String):void {
            consumerTag = tag;
            trace("onConsumeOk: " + tag);
        }

        public function onCancelOk(tag:String):void {
            trace("onCancelOk: " + tag);
            var data:ByteArray = new ByteArray();
            data.writeUTF("hello, world again");
            publish(data);
        }

        public function onDeliver(method:Deliver,
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            assertEquals(routing_key, method.routingkey);
            trace("onDeliver --> " + body.readUTF());
        }

    }
}
