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
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import flexunit.framework.TestSuite;
	
	import org.amqp.BasicConsumer;
	import org.amqp.Command;
	import org.amqp.ProtocolEvent;
	import org.amqp.headers.BasicProperties;
	import org.amqp.methods.basic.Cancel;
	import org.amqp.methods.basic.Consume;
	import org.amqp.methods.basic.Deliver;
	import org.amqp.methods.basic.Get;
	import org.amqp.methods.basic.Publish;
	import org.amqp.methods.connection.OpenOk;
	import org.amqp.util.Properties;
	
	public class PublishSubscribeTest extends AbstractTest implements BasicConsumer
	{		
		protected var consumerTag:String;
		
		public function PublishSubscribeTest(methodName:String=null)
		{
			super(methodName);
		}
		
		public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new PublishSubscribeTest("testPublish"));
            return myTS;
        }
        
        public function testPublish():void {    
        	connection.start();
        	baseSession.addEventListener(new OpenOk(), addAsync(runPublishTest, TIMEOUT) );
        }
        
        public function runPublishTest(event:Event):void {
        	openChannel();        	
        	var consume:Consume = new Consume();
        	consume.queue = q;
        	consume.noack = true;
        	sessionHandler.register(consume, this);
        	var data:ByteArray = new ByteArray();
        	data.writeUTF("hello, world");
        	publish(data);
        	
        	var timer:Timer = new Timer(DELAY, 1);
        	timer.addEventListener(TimerEvent.TIMER_COMPLETE, cancel);
        	timer.start();        	
        	
        	var timer:Timer = new Timer(DELAY, 1);
        	timer.start(); 
        }        
        
        public function cancel(event:TimerEvent):void {
        	assertNotNull(consumerTag);
        	var cancel:Cancel = new Cancel();
        	cancel.consumertag = consumerTag;
        	sessionHandler.dispatch(new Command(cancel));
        }
        
        public function onConsumeOk(tag:String):void {
        	consumerTag = tag;
        	trace("onConsumeOk");
        }
        
		public function onCancelOk(tag:String):void {
			trace("onCancelOk");
		}
		
		public function onDeliver(method:Deliver, 
								  properties:BasicProperties,
								  body:ByteArray):void {
			trace("onDeliver --> " + body.readUTF());	
		}
		
	}
}