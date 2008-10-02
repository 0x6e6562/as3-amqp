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
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    import flexunit.framework.TestSuite;

    import org.amqp.Command;
    import org.amqp.LifecycleEventHandler;
    import org.amqp.ProtocolEvent;
    import org.amqp.methods.channel.Close;
    import org.amqp.methods.connection.Close;
    import org.amqp.methods.exchange.Delete;
    import org.amqp.methods.queue.Delete;

    public class LifecycleTest extends AbstractTest implements LifecycleEventHandler
    {

        public function LifecycleTest(methodName:String){
            super(methodName);
        }

        public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new LifecycleTest("testLifecycle"));
            return myTS;
        }

        public function testLifecycle():void {
            connection.start();
            // Deliberately call this twice to test the state handling of the connection
            connection.start();
            connection.baseSession.registerLifecycleHandler(this);
        }

        public function afterOpen():void {
            openChannel(teardownExchange);
            /*
            var timer:Timer = new Timer(DELAY, 1);
            timer.addEventListener(TimerEvent.TIMER, teardownExchange);
            timer.start();
            */
        }

        public function teardownExchange(event:ProtocolEvent):void {
            trace("teardownExchange");

            var queueDelete:org.amqp.methods.queue.Delete = new org.amqp.methods.queue.Delete();
            queueDelete.queue = q;
            queueDelete.ifempty = false;
            queueDelete.ifunused = false;
            var exchangeDelete:org.amqp.methods.exchange.Delete = new org.amqp.methods.exchange.Delete();
            exchangeDelete.exchange = x;
            exchangeDelete.ifunused = false;

            var whoCares:Function = function(event:ProtocolEvent):void{
                trace("whoCares called");
            };

            sessionHandler.rpc(new Command(queueDelete), whoCares);//addAsync(whoCares, TIMEOUT));
            sessionHandler.rpc(new Command(exchangeDelete), whoCares);//addAsync(whoCares, TIMEOUT));

            var timer:Timer = new Timer(DELAY, 1);
            timer.addEventListener(TimerEvent.TIMER, closeSession);
            timer.start();
        }

        public function closeSession(event:Event):void {
            var close:org.amqp.methods.channel.Close = new org.amqp.methods.channel.Close();
            close.replycode = 200;
            close.replytext = "Goodbye";
            var fun:Function = function(event:ProtocolEvent):void {
                trace("Channel closed");
                closeConnection();
            };
            sessionHandler.rpc(new Command(close), fun);//addAsync(fun, TIMEOUT));
        }

        public function closeConnection():void {
            var close:org.amqp.methods.connection.Close = new org.amqp.methods.connection.Close();
            close.replycode = 200;
            close.replytext = "Goodbye";
            var fun:Function = function(event:ProtocolEvent):void {
                trace("Connection closed");
            };
            sessionHandler.rpc(new Command(close), fun);//addAsync(fun, TIMEOUT));
        }

    }
}
