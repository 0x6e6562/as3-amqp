package org.amqp.test
{
    import flash.utils.ByteArray;

    import flexunit.framework.TestSuite;

    import org.amqp.Command;
    import org.amqp.LifecycleEventHandler;
    import org.amqp.ProtocolEvent;
    import org.amqp.methods.basic.Get;

    public class GetTest extends AbstractTest implements LifecycleEventHandler
    {

        private const testString:String = "hello, world";

        public function GetTest(methodName:String=null)
        {
            super(methodName);
        }

        public static function suite():TestSuite {
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new GetTest("testGet"));
            return myTS;
        }

        public function afterOpen():void {
            openChannel(runGetTest);
        }

        public function testGet():void {
            connection.start();
            connection.baseSession.registerLifecycleHandler(this);
        }

        public function runGetTest(event:ProtocolEvent):void {
            var data:ByteArray = new ByteArray();
            data.writeUTF(testString);
            publish(data);
            var _get:Get = new Get();
            _get.queue = q;
            _get.noack = true;
            sessionHandler.rpc(new Command(_get), onGetOk);
        }

        public function onGetOk(event:ProtocolEvent):void {
            var data:ByteArray = event.command.content;
            data.position = 0;
            if (data.bytesAvailable > 0) {
                var msg:String = data.readUTF();
                assertEquals(testString, msg);
                trace("onGetOk ---> " + msg);
            }
        }
    }
}
