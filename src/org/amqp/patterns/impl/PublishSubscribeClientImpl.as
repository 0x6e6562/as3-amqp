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
	
	import de.polygonal.ds.ArrayedQueue;
	
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
	import org.amqp.methods.queue.Purge;
	import org.amqp.patterns.BasicMessageEvent;
	import org.amqp.patterns.PublishSubscribeClient;
	import org.amqp.util.Properties;

    public class PublishSubscribeClientImpl extends AbstractDelegate implements PublishSubscribeClient, BasicConsumer
    {
    	private const QUEUE_SIZE:int = 100;
    	
        private var topics:HashMap = new HashMap();
        private var topicBuffer:ArrayedQueue = new ArrayedQueue(QUEUE_SIZE);
        private var sendBuffer:ArrayedQueue = new ArrayedQueue(QUEUE_SIZE);
        private var dispatcher:EventDispatcher = new EventDispatcher();
    
    	private var requestOk:Boolean;
    
        public function PublishSubscribeClientImpl(c:Connection) {
            super(c);
        }
        
        public function send(key:String, o:*):void {
			if (o != null) {
				var buffer:Boolean;
				
				if (requestOk) {
					if (topics.containsKey(key)) {
						if (topics.getValue(key).consumeOk) {
							buffer = false;
						}else {
							buffer = true;
						}
					}else {
						buffer = false;
					}
				}else {
					buffer = true;
				}
				
				if (buffer) {
					pubBuffer(key, o);
				}else {
					dispatch(key, o);
				}
			}
		}
        
        private function pubBuffer(key:String, o:*):void {
			var queuedObj:Object = {key:key, payload:o};
			
			if (topics.containsKey(key)) {
				var topic:* = topics.getValue(key);
				topic.buffer.enqueue(queuedObj);
				topics.put(key, topic);
			}else {
				sendBuffer.enqueue(queuedObj);
			}
		}
		
		private function drainPubBuffer(key:String=null):void {
			var topic:*;
			var buffer:ArrayedQueue;
			
			if (key == null) {
				buffer = sendBuffer;
			}else {
				topic = topics.getValue(key);
				buffer = topic.buffer;
			}
			
			while(!buffer.isEmpty()) {
				// why is "o" a constant?
				const o:Object = buffer.dequeue();
				var key:String = o.key;
				var data:* = o.payload;
				dispatch(key, data);
			}
			
			if (key != null) {
				topics.put(key, topic);
			}
		}

        public function dispatch(key:String, o:*):void {
            var data:ByteArray = new ByteArray();
            serializer.serialize(o, data);
            var props:BasicProperties = Properties.getBasicProperties();
            publish(exchange, key, data, props);
        }
        
        public function subscribe(key:String, callback:Function):void {
        	if (topics.containsKey(key)) {
        		return;
        	}
        	
        	topics.put(key, {
        		callback:callback,
        		replyQueue:null,
        		consumeOk:false,
        		buffer:new ArrayedQueue(QUEUE_SIZE)
        	});
        	
        	subBuffer(key);
        	
        	if (requestOk) {
        		drainSubBuffer();
        	}
        }
        
        private function subBuffer(key:String):void {
        	var queuedObj:String = key;
			topicBuffer.enqueue(queuedObj);
        }
        
        private function drainSubBuffer():void {
        	var bufSize:int = topicBuffer.size;
        	
        	for (var i:int=0; i < bufSize; i++) {
        		setupReplyQueue();
        	}
        }
                
        public function unsubscribe(key:String):void {
        	/*if (key == null) {
        		// unsubscribe all of them
        	}*/
        	
        	// should unsubscription commands be queued?
        	
			if (topics.containsKey(key)) {
				var topic:* = topics.getValue(key);
				var purgeQueue:Purge = new Purge();
				purgeQueue.queue = topic.replyQueue;
				sessionHandler.dispatch(new Command(purgeQueue));
				dispatcher.removeEventListener(key, topic.callback);
				topics.remove(key);
			}
        }
        
        public function onConsumeOk(tag:String):void {
        	var topic:* = topics.getValue(tag);
        	topic.consumeOk = true;
        	topics.put(tag, topic);
        	
        	dispatcher.addEventListener(tag, topic.callback);
        	drainPubBuffer(tag);
        }
        
        public function onCancelOk(tag:String):void {}
        
        public function onDeliver(method:Deliver, 
                                  properties:BasicProperties,
                                  body:ByteArray):void {
            var result:* = serializer.deserialize(body);
            dispatcher.dispatchEvent(new BasicMessageEvent(method.consumertag, result));
        }
        
        // ** note: would be nice if ths event sent use the consumerTag or queue name that
        // was purged instead of just removing it from the topic hash in unsubscribe()
        //public function onPurgeOk(event:ProtocolEvent):void {}
        
		override protected function declareQueue(q:String):void {        	
        	var queue:org.amqp.methods.queue.Declare = new org.amqp.methods.queue.Declare();
        	queue.queue = q;
			queue.autodelete = true;
        	sessionHandler.dispatch(new Command(queue));
        }

        override protected function onRequestOk(event:ProtocolEvent):void {
        	requestOk = true;
        	
        	declareExchange(exchange, exchangeType);            
            drainSubBuffer();
            drainPubBuffer();
            
			//sessionHandler.addEventListener(new PurgeOk(), onPurgeOk);
        }
        
        override protected function onQueueDeclareOk(event:ProtocolEvent):void {
            var replyQueue:String = getReplyQueue(event);
            
            if (!topicBuffer.isEmpty()) {
            	const key:String = topicBuffer.dequeue();
            	
            	var topic:* = topics.getValue(key);
            	topic.replyQueue = replyQueue;
            	topics.put(key, topic);
            	
            	bindQueue(exchange, replyQueue, key);
				
				var consume:Consume = new Consume();
            	consume.queue = replyQueue;
            	consume.noack = true;
            	consume.consumertag = key;
            
            	sessionHandler.register(consume, this);
            }
        }
	}
}
