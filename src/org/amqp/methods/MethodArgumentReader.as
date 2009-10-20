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
package org.amqp.methods
{
    import flash.utils.IDataInput;
    import flash.utils.ByteArray;
    import com.ericfeminella.utils.Map;
    import com.ericfeminella.utils.HashMap;
    import org.amqp.LongString;
    import org.amqp.impl.ByteArrayLongString;
    import org.amqp.error.MalformedFrameError;

    public class MethodArgumentReader
    {

        private static var INT_MASK:uint = 0xffff;
        private var input:IDataInput;

        /** If we are reading one or more bits, holds the current packed collection of bits */
        private var bits:int;
        /** If we are reading one or more bits, keeps track of which bit position we are reading from */
        private var bit:int;

        public function MethodArgumentReader(input:IDataInput) {
            this.input = input;
            clearBits();
        }

        /**
         * Private API - resets the bit group accumulator variables when
         * some non-bit argument value is to be read.
         */
        private function clearBits():void {
            bits = 0;
            bit = 0x100;
        }

        protected static function unsignedExtend(value:int):int {
            return value & INT_MASK;
        }

        public static function _readLongstr(input:IDataInput):LongString {
            var contentLength:int = input.readInt();
            if(contentLength < int.MAX_VALUE) {
                var buf:ByteArray = new ByteArray();
                input.readBytes(buf, 0, contentLength);
                return new ByteArrayLongString(buf);
            }
            else {
                throw new Error("Very long strings not currently supported");
            }
        }

        public static function _readShortstr(input:IDataInput):String {
            var length:int = input.readUnsignedByte();
            return input.readUTFBytes(length);
        }

        public final function readLongstr():LongString {
            clearBits();
            return _readLongstr(input);
        }

        public final function readShortstr():String {
            clearBits();
            return _readShortstr(input);
        }

        /** Public API - reads a short integer argument. */
        public final function readShort():int {
            clearBits();
            return input.readShort();
        }

        /** Public API - reads an integer argument. */
        public final function readLong():int{
            clearBits();
            return input.readInt();
        }

        /** Public API - reads a long integer argument. */
        public final function readLonglong():uint {
            clearBits();
            var higher:int = input.readInt();
            var lower:int = input.readInt();
            return lower + higher << 0x100000000;
        }

        /** Public API - reads a bit/boolean argument. */
        public final function readBit():Boolean {
            if (bit > 0x80) {
                bits = input.readUnsignedByte();
                bit = 0x01;
            }
            var result:Boolean = (bits&bit) != 0;
            bit = bit << 1;
            return result;
        }

        /** Public API - reads a table argument. */
        public final function readTable():Map {
            clearBits();
            return _readTable(this.input);
        }

        /**
         * Public API - reads a table argument from a given stream. Also
         * called by {@link ContentHeaderPropertyReader}.
         */
        public static function _readTable(input:IDataInput):Map {

            var table:Map = new HashMap();
            var tableLength:int = input.readInt();
            if (tableLength == 0) return table; // readBytes(tableIn,0,0) reads ALL bytes

            var tableIn:ByteArray = new ByteArray();
            input.readBytes(tableIn, 0, tableLength);
            var value:Object = null;

            while(tableIn.bytesAvailable > 0) {
                var name:String = _readShortstr(tableIn);
                var type:uint = tableIn.readUnsignedByte();
                switch(type) {
                    case 83 : //'S'
                        value = _readLongstr(tableIn);
                        break;
                    case 73: //'I'
                        value = tableIn.readInt();
                        break;
                    case 84: //'T':
                        value = _readTimestamp(tableIn);
                        break;
                    case 70: //'F':
                        value = _readTable(tableIn);
                        break;
                    default:
                        throw new MalformedFrameError("Unrecognised type in table");
                }

                if(!table.containsKey(name))
                    table.put(name, value);
            }

            return table;
        }

        /** Public API - reads an octet argument. */
        public final function readOctet():int{
            clearBits();
            return input.readUnsignedByte();
        }

        /** Public API - convenience method - reads a timestamp argument from the DataInputStream. */
        public static function _readTimestamp(input:IDataInput):Date {
            var date:Date = new Date();
            date.setTime(input.readInt() * 1000)
            return date;
        }

        /** Public API - reads an timestamp argument. */
        public final function readTimestamp():Date {
            clearBits();
            return _readTimestamp(input);
        }
    }
}
