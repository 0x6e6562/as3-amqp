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
package org.amqp.error
{
	import flash.events.ErrorEvent;

    public class ConnectionError extends ErrorEvent
    {
    	public static const CONNECTION_ERROR:String = "connectionError";
        public const message:String = "Connection failed";
        
        public function ConnectionError()
        {
            super(CONNECTION_ERROR, false, false, message);
        }
    }
}