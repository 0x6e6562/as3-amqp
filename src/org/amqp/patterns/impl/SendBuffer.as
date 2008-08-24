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

    import org.amqp.patterns.Dispatcher;

    public class SendBuffer
    {
        private var sendBuffer:ArrayedQueue = new ArrayedQueue(100);
        private var dispatcher:Dispatcher;

        public function SendBuffer(dispatcher:Dispatcher) {
            this.dispatcher = dispatcher;
        }

        public function buffer(o:*, callback:Function):void {
            var o:Object = {payload:o,handler:callback};
            sendBuffer.enqueue(o);
        }

        public function drain():void {
            while(!sendBuffer.isEmpty()) {
                var o:Object = sendBuffer.dequeue();
                var data:* = o.payload;
                var callback:Function = o.handler;
                dispatcher.dispatch(data,callback);
            }
        }

    }
}