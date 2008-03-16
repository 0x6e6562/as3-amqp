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
package org.amqp.headers
{
	import flash.utils.IDataInput;
	
    public class ContentHeaderReader
    {
        public static function readContentHeaderFrom(input:IDataInput):ContentHeader {
          var classId:int = input.readShort();
          switch (classId) {
	            case 10: return new ConnectionProperties();
	            case 20: return new ChannelProperties();
	            case 30: return new AccessProperties();
	            case 40: return new ExchangeProperties();
	            case 50: return new QueueProperties();
	            case 60: return new BasicProperties();
	            case 70: return new FileProperties();
	            case 80: return new StreamProperties();
	            case 90: return new TxProperties();
	            case 100: return new DtxProperties();
	            default: return null;
	      }
        }

    }
}    