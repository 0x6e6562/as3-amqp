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
    import com.ericfeminella.utils.Map;

    import flash.utils.ByteArray;
    import flash.utils.IDataOutput;

    import org.amqp.FrameHelper;
    import org.amqp.LongString;
    import org.amqp.error.IllegalArgumentError;

    public class ContentHeaderPropertyWriter
    {
        public var flags:Array;
        /** Output stream collecting the packet as it is generated */
        public var outBytes:ByteArray;

        /** Current flags word being accumulated */
        public var flagWord:int;
        /** Position within current flags word */
        public var bitCount:int;

        public function ContentHeaderPropertyWriter(){
            this.flags = new Array();
            this.outBytes = new ByteArray();
            this.flagWord = 0;
            this.bitCount = 0;
        }

        /**
         * Private API - encodes the presence or absence of a particular
         * object, and returns true if the main data stream should contain
         * an encoded form of the object.
         */
        public function argPresent(value:Object):Boolean {
            if (bitCount == 15) {
                flags.addItem(flagWord | 1);
                flagWord = 0;
                bitCount = 0;
            }

            if (value != null) {
                var bit:int = 15 - bitCount;
                flagWord |= (1 << bit);
                bitCount++;
                return true;
            } else {
                bitCount++;
                return false;
            }
        }

        public function dumpTo(output:IDataOutput):void {

            if (bitCount > 0) {
                flags.push(flagWord);
            }
            for (var i:int = 0 ; i < flags.length ; i++) {
                output.writeShort(flags[i]);
            }
            output.writeBytes(outBytes,0,0);
        }

        /** Protected API - Writes a String value as a short-string to the stream, if it's non-null */
        public function writeShortstr(x:String):void {
            if (argPresent(x)) {
                _writeShortstr(x);
            }
        }

        public function _writeShortstr(x:String):void {
            outBytes.writeByte(x.length);
            outBytes.writeUTFBytes(x);
        }

        /** Protected API - Writes a String value as a long-string to the stream, if it's non-null */
        public function writeLongstr(x:String):void {
            if(argPresent(x)){
                _writeLongstr(x);
            }
        }

        public function _writeLongstr(x:String):void {
                outBytes.writeInt(x.length);
                outBytes.writeUTFBytes(x);
        }

        /** Protected API - Writes a LongString value to the stream, if it's non-null */
        public function __writeLongstr(x:LongString):void {
            if(argPresent(x)){
                ___writeLongstr(x);
            }
        }

        public function ___writeLongstr(x:LongString):void {
                outBytes.writeInt(x.length());
                outBytes.writeBytes(x.getBytes(),0,0);
        }

        /** Protected API - Writes a short integer value to the stream, if it's non-null */
        public function writeShort(x:int):void {
            if(argPresent(x)) {
                _writeShort(x);
            }
        }

        /** Protected API - Writes a short integer value to the stream, if it's non-null */
        public function _writeShort(x:int):void {
                outBytes.writeShort(x);
        }

        /** Protected API - Writes an integer value to the stream, if it's non-null */
        public function writeLong(x:int):void {
            if(argPresent(x)) {
                _writeLong(x);
            }
        }

        public function _writeLong(x:int):void {
            outBytes.writeInt(x);
        }

        /** Protected API - Writes a long integer value to the stream, if it's non-null */
        public function writeLonglong(x:uint):void {
            if(argPresent(x)) {
                _writeLonglong(x);
            }
        }

        public function _writeLonglong(x:uint):void {
            outBytes.writeUnsignedInt(x);
        }

        /** Protected API - Writes a table value to the stream, if it's non-null */
        public function writeTable(x:Map):void {
            if(argPresent(x)){
                _writeTable(x);
            }
        }
        public function _writeTable(table:Map):void {
            outBytes.writeInt( FrameHelper.tableSize(table) );

            for (var key:String in table) {
                writeShortstr(key);
                var value:Object = table.getValue(key);

                if(value is String) {
                    _writeOctet(83); // 'S'
                    _writeShortstr(value as String);
                }
                else if(value is LongString) {
                    _writeOctet(83); // 'S'
                    ___writeLongstr(value as LongString);
                }
                else if(value is int) {
                    _writeOctet(73); // 'I'
                    _writeShort(value as int);
                }
                else if(value is Date) {
                    _writeOctet(84);//'T'
                    _writeTimestamp(value as Date);
                }
                else if(value is Map) {
                    _writeOctet(70); // 'F"
                    _writeTable(value as Map);
                }
                else if (value == null) {
                    throw new Error("Value for key {" + key + "} was null");
                }
                else {
                    throw new IllegalArgumentError
                        ("Invalid value type: [" + value
                         + "] for key [" + key+"]");
                }
            }

        }

        /** Protected API - Writes an octet value to the stream, if it's non-null */
        public function writeOctet(x:int):void {
            if(argPresent(x)) {
                _writeOctet(x);
            }
        }

        public function _writeOctet(x:int):void {
            outBytes.writeByte(x);
        }

        /** Protected API - Writes a timestamp value to the stream, if it's non-null */
        public function writeTimestamp(x:Date):void {
            if(argPresent(x)) {
                _writeTimestamp(x);
            }
        }

        public function _writeTimestamp(x:Date):void {
            outBytes.writeInt(x.time / 1000);
        }
    }
}
