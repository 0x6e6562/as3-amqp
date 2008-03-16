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
    import flash.utils.IDataInput;
    import flash.utils.ByteArray;
    import flash.utils.IDataOutput;
    import org.amqp.headers.ContentHeader;
    import org.amqp.methods.MethodArgumentWriter;
    import org.amqp.headers.ContentHeaderReader;
    import org.amqp.methods.MethodReader;
    import org.amqp.error.UnexpectedFrameError;
    
	public class Command extends AMQP
	{
		public static var STATE_EXPECTING_METHOD:int = 0;
	    public static var STATE_EXPECTING_CONTENT_HEADER:int = 1;
	    public static var STATE_EXPECTING_CONTENT_BODY:int = 2;
	    public static var STATE_COMPLETE:int = 3;
	
	    // EMPTY_CONTENT_BODY_FRAME_SIZE, 8 = 1 + 2 + 4 + 1
	    //  - 1 byte of frame type
	    //  - 2 bytes of channel number
	    //  - 4 bytes of frame payload length
	    //  - 1 byte of payload trailer FRAME_END byte
	    // See definition of checkEmptyContentBodyFrameSize(), an assertion called at startup.
	    /** Safety definition - see also {@link #checkEmptyContentBodyFrameSize} */
	    public static var EMPTY_CONTENT_BODY_FRAME_SIZE:int = 8;
	    public static var EMPTY_BYTE_ARRAY:ByteArray = new ByteArray();
		
		private var state:int;
		public var method:Method;
		public var contentHeader:ContentHeader;
		private var remainingBodyBytes:int;
		//private var content:Array;
		public  var content:ByteArray = new ByteArray;
		
		public function Command() {
		}
		
		public function init(m:Method, c:ContentHeader, b:ByteArray):void {
            this.method = m;
            this.contentHeader = c;
            //setContentBody(b);
            addToContentBody(b);
            this.state = (m == null) ? STATE_EXPECTING_METHOD : STATE_COMPLETE;
            this.remainingBodyBytes = 0;
        }
		
		public function isComplete():Boolean {
			return this.state == STATE_COMPLETE;
		}
		/*
		public function getContentBody():ByteArray {
            return content;
        }
        */
        
        private function addToContentBody(b:ByteArray):void {
            content.writeBytes(b,content.position,0);
        }
        
		
		public function transmit(channelNumber:int, connection:Connection):void {
    
            var f:Frame = new Frame();
            f.type = FRAME_METHOD;
            f.channel = channelNumber;
          
            var bodyOut:IDataOutput = f.getOutputStream();
            
            if (method.getClassId() < 0 || method.getMethodId() < 0) {
                throw new Error("Method not implemented properly" + method);
            }
            else {
                trace("Class id: " + method.getClassId() + " , Method id: " + method.getMethodId());
            }
            
            
            
            
            bodyOut.writeShort(method.getClassId());
            bodyOut.writeShort(method.getMethodId());
            var argWriter:MethodArgumentWriter = new MethodArgumentWriter(bodyOut);
            method.writeArgumentsTo(argWriter);
            argWriter.flush();
            connection.sendFrame(f);
    
            if (this.method.hasContent()) {
    
                f = new Frame();
                f.type = FRAME_HEADER;
                f.channel = channelNumber;
                bodyOut = f.getOutputStream();
                bodyOut.writeShort(contentHeader.getClassId());
                contentHeader.writeTo(bodyOut, this.content.length);
                connection.sendFrame(f);
    
                var frameMax:int = connection.frameMax;
                var bodyPayloadMax:int =
                    (frameMax == 0) ? this.content.length : frameMax - EMPTY_CONTENT_BODY_FRAME_SIZE;
    
                for (var offset:int = 0; offset < this.content.length; offset += bodyPayloadMax) {
                    var remaining:int = this.content.length - offset;
    
                    f = new Frame();
                    f.type = FRAME_BODY;
                    f.channel = channelNumber;
                    bodyOut = f.getOutputStream();
                    bodyOut.writeBytes(this.content, offset,
                                  (remaining < bodyPayloadMax) ? remaining : bodyPayloadMax);
                    connection.sendFrame(f);
                }
            }
        }

		
		public function handleFrame(frame:Frame):void {
	            
	        switch (this.state) {
	          case STATE_EXPECTING_METHOD:
	              switch (frame.type) {
	                case FRAME_METHOD: {
	                	MethodReader
	                    //this.method = MethodReader .readMethodFrom(frame.getInputStream());
	                    this.state = this.method.hasContent()
	                        ? STATE_EXPECTING_CONTENT_HEADER
	                        : STATE_COMPLETE;
	                    return;
	                }
	                default: { 
	                    throw new UnexpectedFrameError("State: STATE_EXPECTING_METHOD", frame);
	                }
	              }
	
	          case STATE_EXPECTING_CONTENT_HEADER:
	              switch (frame.type) {
	                case FRAME_HEADER: {
	                    var input:IDataInput = frame.getInputStream();
	                    this.contentHeader = ContentHeaderReader.readContentHeaderFrom(input);
	                    this.remainingBodyBytes = this.contentHeader.readFrom(input);
	                    updateContentBodyState();
	                    return;
	                }
	                default: throw new Error("Unexpected frame");
	              }
	
	          case STATE_EXPECTING_CONTENT_BODY:
	              switch (frame.type) {
	                case FRAME_BODY: {
	                    
	                    var fragment:ByteArray = frame.getPayload();
	                    this.remainingBodyBytes -= fragment.length;
	                    updateContentBodyState();
	                    if (this.remainingBodyBytes < 0) {
	                        throw new Error("%%%%%% FIXME unimplemented");
	                    }
	                    addToContentBody(fragment);
	                    return;
	                }
	                default: throw new Error("Unexpected frame");
	              }
	
	          default:
	              throw new Error("Bad Command State " + this.state);
	        }
	        
	    }
	    
	    public function updateContentBodyState():void {
            this.state = (this.remainingBodyBytes > 0)
                ? STATE_EXPECTING_CONTENT_BODY
                : STATE_COMPLETE;
        }
	}
}