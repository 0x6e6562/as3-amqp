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
package org.amqp
{
	import org.amqp.methods.MethodArgumentWriter;
	import org.amqp.methods.MethodArgumentReader;
	import flash.events.Event;
	
    public class Method
    {
        public function writeArgumentsTo(writer:MethodArgumentWriter):void {}

		public function readArgumentsFrom(reader:MethodArgumentReader):void {}

		public function hasContent():Boolean {
		    return false;
		}

        public function hasResponse():Boolean {
             return false;
        }

        public function getResponse():Method {
             return null;
        }

        public function eventId():String {
		    return getClassId() + "/" + getMethodId();
		}

		public function event():Event {
		    return null;//new MethodEvent(eventId());
		}

		public function getClassId():int{
		    return -1;
		}

		public function getMethodId():int{
		    return -1;
		}
    }
}

