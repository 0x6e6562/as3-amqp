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
	import flash.utils.IDataOutput;
	import flash.utils.ByteArray;
	import com.ericfeminella.utils.Map;
	import org.amqp.LongString;
	import org.amqp.FrameHelper;
	import org.amqp.util.IOUtils;
	import org.amqp.error.IllegalArgumentError;
	
	public class MethodArgumentWriter
	{
		private var output:IDataOutput;
		
		private var needBitFlush:Boolean;
	    /** The current group of bits */
	    private var bitAccumulator:int;
	    /** The current position within the group of bits */
	    private var bitMask:int;
		
		public function MethodArgumentWriter(output:IDataOutput) {
			this.output = output;
			resetBitAccumulator();
		}
		
		private function resetBitAccumulator(): void {
	        needBitFlush = false;
	        bitAccumulator = 0;
	        bitMask = 1;
	    }
	    
	    /**
	     * Private API - called when we may be transitioning from encoding
	     * a group of bits to encoding a non-bit value.
	     */
	    private final function bitflush():void {
	        if (needBitFlush) {
	            output.writeByte(bitAccumulator);
	            resetBitAccumulator();
	        }
	    }
	    
	    /** Public API - encodes a short string argument. */
	    public final function writeShortstr(str:String):void {
	        bitflush();
	        //byte [] bytes = str.getBytes("utf-8");
	        
	        var buf:ByteArray = new ByteArray();
	        buf.writeUTFBytes(str);
	       
	        output.writeByte(buf.length);
	        output.writeBytes(buf, 0, 0);
	    }
	
	    /** Public API - encodes a long string argument from a LongString. */
	    public final function writeLongstr(str:LongString):void {
	        bitflush();
	        writeLong(str.length());
	        IOUtils.copy(str.getBytes(), output);
	    }
	
	    /** Public API - encodes a long string argument from a String. */
	    public final function writeString(str:String):void {
	        bitflush();
	        //byte [] bytes = str.getBytes("utf-8");
	        writeLong(str.length);
	        output.writeUTFBytes(str);
	    }
	    
	    /** Public API - encodes a short integer argument. */
	    public final function writeShort(s:int):void {
	        bitflush();
	        output.writeShort(s);
	    }
	
	    /** Public API - encodes an integer argument. */
	    public final function writeLong(l:int):void {
	        bitflush();
	        // java's arithmetic on this type is signed, however its
	        // reasonable to use ints to represent the unsigned long
	        // type - for values < Integer.MAX_VALUE everything works
	        // as expected
	        output.writeInt(l);
	    }
	
	    /** Public API - encodes a long integer argument. */
	    public final function writeLonglong(ll:int):void {
	        throw new Error("No longs in Actionscript");
	        //bitflush();
	        //output.writeInt(ll);
	    }
	
	    /** Public API - encodes a boolean/bit argument. */
	    public function writeBit(b:Boolean):void {
	        if (bitMask > 0x80) {
	            bitflush();
	        }
	        if (b) {
	            bitAccumulator |= bitMask;
	        } else {
	            // um, don't set the bit.
	        }
	        
	        bitMask = bitMask << 1;
	        needBitFlush = true;
	    }
	
	    /** Public API - encodes a table argument. */
	    public final function writeTable(table:Map):void {
	        
	        bitflush();
	        if (table == null) {
	            // Convenience.
	            output.writeInt(0);
	        } else {
	            output.writeInt( FrameHelper.tableSize(table) );
	            
	            for (var key:String in table) {
	                writeShortstr(key);
	                var value:Object = table.getValue(key);
	            
	                if(value is String) {
	                    writeOctet(83); // 'S'
	                    writeShortstr(value as String);
	                }
	                else if(value is LongString) {
	                    writeOctet(83); // 'S'
	                    writeLongstr(value as LongString);
	                }
	                else if(value is int) {
	                    writeOctet(73); // 'I'
	                    writeShort(value as int);
	                }
	                /*
	                else if(value is BigDecimal) {
	                    writeOctet(68); // 'D'
	                    BigDecimal decimal = (BigDecimal)value;
	                    writeOctet(decimal.scale());
	                    BigInteger unscaled = decimal.unscaledValue();
	                    if(unscaled.bitLength() > 32) //Integer.SIZE in Java 1.5
	                        throw new IllegalArgumentException
	                            ("BigDecimal too large to be encoded");
	                    writeLong(decimal.unscaledValue().intValue());
	                }
	                */
	                else if(value is Date) {
	                    writeOctet(84);//'T'
	                    writeTimestamp(value as Date);
	                }
	                else if(value is Map) {
	                    writeOctet(70); // 'F"
	                    writeTable(value as Map);
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
	       
	    }
	
	    /** Public API - encodes an octet argument from an int. */
	    public final function writeOctet(octet:int):void {
	        bitflush();
	        output.writeByte(octet);
	    }
	
	    /** Public API - encodes a timestamp argument. */
	    public final function writeTimestamp(timestamp:Date):void {
	        // AMQP uses POSIX time_t which is in seconds since the epoc
	        writeLonglong( timestamp.valueOf() / 1000);
	    }
	
	    /**
	     * Public API - call this to ensure all accumulated argument
	     * values are correctly written to the output stream.
	     */
	    public function flush():void {
	        bitflush();
	        //output.flush();
	    }
	}
}
