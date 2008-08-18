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
	import de.polygonal.ds.ArrayedQueue;
	
	import flash.utils.ByteArray;
	
	import org.amqp.Connection;
	import org.amqp.ProtocolEvent;
	import org.amqp.headers.BasicProperties;
	import org.amqp.patterns.PublishClient;
	import org.amqp.util.Properties;

    public class PublishClientImpl extends AbstractDelegate implements PublishClient
    {
    	private var sendBuffer:ArrayedQueue = new ArrayedQueue(100);
    	private var requestOk:Boolean;
    	
        public function PublishClientImpl(c:Connection) {
            super(c);
        }

		public function send(key:String, o:*):void {
			if (o != null) {
				if (requestOk) {
					dispatch(key, o);
				}else {
					buffer(key, o);
				}
			}
		}
		
		private function buffer(key:String, o:*):void {
			var queuedObj:Object = {key:key, payload:o}; 
			sendBuffer.enqueue(queuedObj);
		}
		
		private function drainBuffer():void {
			while(!sendBuffer.isEmpty()) {
				// why is "o" a constant?
				const o:Object = sendBuffer.dequeue();
				var key:String = o.key;
				var data:* = o.payload;
				dispatch(key, data);
			}
		}

        public function dispatch(key:String, o:*):void {
            var data:ByteArray = new ByteArray();
            serializer.serialize(o, data);
            var props:BasicProperties = Properties.getBasicProperties();
            publish(exchange, key, data, props);
        }

		// Ben: You mentioned in a comment that Request/RequestOk will disappear from Rabbit
		// ... if thats the case then how can we handle this event to know when its okay
		// to begin making requests to the broker?
		// ... I suppose we can use OpenOk, but then we'll have to change how AbstractDelegate
		// is written
        override protected function onRequestOk(event:ProtocolEvent):void {
            declareExchange(exchange, exchangeType);
            
            requestOk = true;
            drainBuffer();
        }
	}
}