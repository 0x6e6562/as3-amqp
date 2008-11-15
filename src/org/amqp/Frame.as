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
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;
    import org.amqp.error.MalformedFrameError;

    public class Frame
    {

        public var type:uint;
        public var channel:int;
        protected var payload:ByteArray;
        protected var accumulator:ByteArray;

        public function Frame() {
            this.payload = new ByteArray();
            this.accumulator = new ByteArray();
        }

        public function readFrom(input:IDataInput):Boolean {

            type = input.readUnsignedByte();

            if (type == 'A' as uint) {
                /* Probably an AMQP.... header indicating a version mismatch. */
                /* Otherwise meaningless, so try to read the version, and
                 * throw an exception, whether we read the version okay or
                 * not. */
                protocolVersionMismatch(input);
            }

            channel = input.readUnsignedShort();
            var payloadSize:int = input.readInt();

            if (payloadSize > 0) {
                payload = new ByteArray();
                input.readBytes(payload, 0, payloadSize);
            }

            accumulator = null;

            var frameEndMarker:int = input.readUnsignedByte();

            if (frameEndMarker != AMQP.FRAME_END) {
                throw new MalformedFrameError("Bad frame end marker: " + frameEndMarker);
            }

            return true;
        }

        private function protocolVersionMismatch(input:IDataInput):void {

            var x:Error = null;

            try {
                var gotM:Boolean = input.readUnsignedByte() == 'M' as uint;
                var gotQ:Boolean = input.readUnsignedByte() == 'Q' as uint;
                var gotP:Boolean = input.readUnsignedByte() == 'P' as uint;
                var transportHigh:uint = input.readUnsignedByte();
                var transportLow:uint = input.readUnsignedByte();
                var serverMajor:uint = input.readUnsignedByte();
                var serverMinor:uint = input.readUnsignedByte();
                x = new MalformedFrameError("AMQP protocol version mismatch; we are version " +
                                                AMQP.PROTOCOL_MAJOR + "." +
                                                AMQP.PROTOCOL_MINOR + ", server is " +
                                                serverMajor + "." + serverMinor +
                                                " with transport " +
                                                transportHigh + "." + transportLow);
            } catch (e:Error) {
                throw new Error("Invalid AMQP protocol header from server");
            }

            throw x;
        }

        public function finishWriting():void {
            if (accumulator != null) {
                payload.writeBytes(accumulator,0,accumulator.bytesAvailable);
                payload.position = 0;
                accumulator = null;
            }
        }

        /**
         * Public API - writes this Frame to the given DataOutputStream
         */
        public function writeTo(os:IDataOutput):void{
            finishWriting();
            os.writeByte(type);
            os.writeShort(channel);
            os.writeInt(payload.length);
            os.writeBytes(payload);
            os.writeByte(AMQP.FRAME_END);
        }

        public function toString():String{
            return "(" + type + ", " + channel + ", length = " +
                ((accumulator == null) ? payload.length : accumulator.length) + ")";
        }

        /**
         * Public API - retrieves the frame payload
         */
        public function getPayload():ByteArray {
            return payload;
        }

        /**
         * Public API - retrieves a new DataInputStream streaming over the payload
         */
        public function getInputStream():IDataInput {
            return payload;
        }

        /**
         * Public API - retrieves a fresh DataOutputStream streaming into the accumulator
         */
        public function getOutputStream():IDataOutput {
            return accumulator;
        }
    }
}
