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
package org.amqp.test
{
    import com.hurlant.crypto.tls.TLSConfig;
    import com.hurlant.crypto.tls.TLSEngine;

    import flexunit.framework.TestSuite;

    import org.amqp.ConnectionState;

    public class TLSTest extends org.amqp.test.LifecycleTest
    {
        public function TLSTest(methodName:String)
        {
            super(methodName);
        }

        public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new TLSTest("testLifecycle"));
            return myTS;
        }

        override public function buildConnectionState():ConnectionState {
            var state:ConnectionState = super.buildConnectionState();
            state.useTLS = true;
            state.options = new TLSConfig(TLSEngine.CLIENT);
            return state;
        }

    }
}