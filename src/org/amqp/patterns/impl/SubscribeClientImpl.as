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
    import flash.events.EventDispatcher;
    import flash.utils.ByteArray;
    
    import org.amqp.BasicConsumer;
    import org.amqp.Command;
    import org.amqp.Connection;
    import org.amqp.ProtocolEvent;
    import org.amqp.headers.BasicProperties;
    import org.amqp.methods.basic.Consume;
    import org.amqp.methods.basic.Deliver;
    import org.amqp.methods.queue.Purge;
    import org.amqp.methods.queue.PurgeOk;
    import org.amqp.patterns.BasicMessageEvent;
    import org.amqp.patterns.SubscribeClient;

    public class SubscribeClientImpl extends AbstractDelegate implements SubscribeClient, BasicConsumer
    {
        // todo: array list of all subscribed keys and functions
        
		// for now just works with a subscription to only one topic
        public var bindingKey:String;   
        public var replyQueue:String;
        
        private var receiver:Function;
        private var dispatcher:EventDispatcher = new EventDispatcher();
    
        public function SubscribeClientImpl(c:Connection) {
        	// there is a timing constraint here.. the arguments must be set in time
            super(c);
        }
        
        public function subscribe(key:String, callback:Function):void {
        	// add to a list of objects of keys and callbacks
        	// check if already subscribed
        	// return Boolean
        	
        	bindingKey = key;
			receiver = callback;
			
			dispatcher.addEventListener(bindingKey, receiver);
        }
                
        public function unsubscribe(key:String):void {
        	if (key == null) {
        		// unsubscribe all of them
        	}
        	
            var purgeQueue:Purge = new Purge();
            purgeQueue.queue = replyQueue;
            sessionHandler.dispatch(new Command(purgeQueue));
            sessionHandler.addEventListener(new PurgeOk(), onPurgeOk);
            dispatcher.removeEventListener(key, receiver);

			// bring back the state of the object to before the queue was bound
			// - also remove the consumer
			// - what about exchange and type?
        }
        
        public function onConsumeOk(tag:String):void {}
        
        public function onCancelOk(tag:String):void {}
        
        public function onDeliver(method:Deliver, 
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            var result:* = serializer.deserialize(body);                                                                                    
            dispatcher.dispatchEvent(new BasicMessageEvent(bindingKey, result));
        }
        
        public function onPurgeOk(event:ProtocolEvent):void {
            replyQueue = "";
            // remove the subscription from the list
        }
        
		override protected function declareQueue(q:String):void {
        	var queue:org.amqp.methods.queue.Declare = new org.amqp.methods.queue.Declare();
        	queue.queue = q;
			queue.autodelete = true;
        	sessionHandler.dispatch(new Command(queue));
        }

        override protected function onRequestOk(event:ProtocolEvent):void {     
            declareExchange(exchange, exchangeType);
            setupReplyQueue();  
        }
        
        override protected function onQueueDeclareOk(event:ProtocolEvent):void {
            replyQueue = getReplyQueue(event);
            bindQueue(exchange, replyQueue, bindingKey);
            var consume:Consume = new Consume();
            consume.queue = replyQueue;
            consume.noack = true;
            sessionHandler.register(consume, this);
        }
	}
}