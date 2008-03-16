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
    import flash.utils.IDataOutput;

    public class ContentHeader
    {
        public function readFrom(input:IDataInput):int {
            var weight:int = input.readShort();
            // TODO this is a workaround because AS doesn't support 64 bit integers
            var bodySizeUpperBytes:int = input.readInt();
            var bodySize:int = input.readInt();
            readPropertiesFrom(new ContentHeaderPropertyReader(input));
            return bodySize;
        }

        public function writeTo(out:IDataOutput, bodySize:int):void{
            out.writeShort(0); // weight

            // This is a hack because AS doesn't support 64-bit integers
            // The java code calls out.writeLong(bodySize)
            // so to fake this, write out 4 zero bytes before writing the body size
            out.writeInt(0);
            out.writeInt(bodySize);

            var writer:ContentHeaderPropertyWriter = new ContentHeaderPropertyWriter();
            writePropertiesTo(writer);
            writer.dumpTo(out);
        }

        public function getClassId():int{
            return -1;
        }

        public function readPropertiesFrom(reader:ContentHeaderPropertyReader):void{}


        public function writePropertiesTo(writer:ContentHeaderPropertyWriter):void{}
    }
}