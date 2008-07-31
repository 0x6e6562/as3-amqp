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
    
    import org.amqp.Connection;
    import org.amqp.ProtocolEvent;
    import org.amqp.headers.BasicProperties;
    import org.amqp.patterns.PublishClient;
    import org.amqp.util.Properties;

    public class PublishClientImpl extends AbstractDelegate implements PublishClient
    {
        public function PublishClientImpl(c:Connection) {
            super(c);
        }

        public function send(key:String, o:*):void {
            var data:ByteArray = new ByteArray();
            serializer.serialize(o, data);
            var props:BasicProperties = Properties.getBasicProperties();
            publish(exchange, key, data, props);
        }

        override protected function onRequestOk(event:ProtocolEvent):void {     
            declareExchange(exchange, exchangeType);
        }
	}
}