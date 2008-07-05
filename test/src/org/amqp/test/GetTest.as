package org.amqp.test
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	import flexunit.framework.TestSuite;
	
	import org.amqp.Command;
	import org.amqp.ProtocolEvent;
	import org.amqp.methods.basic.Get;
	import org.amqp.methods.connection.OpenOk;
	
	public class GetTest extends AbstractTest
	{
		public function GetTest(methodName:String=null)
		{
			super(methodName);
		}
		
		public static function suite():TestSuite {
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new GetTest("testGet"));
            return myTS;
        }
        
        public function testGet():void {    
        	connection.start();
        	baseSession.addEventListener(new OpenOk(), addAsync(runGetTest, TIMEOUT) );
        }
        
        public function runGetTest(event:Event):void {
        	openChannel();
        	var data:ByteArray = new ByteArray();
        	data.writeUTF("hello, world");
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
        		trace("onGetOk ---> " + data.readUTF());
        	}
        }
	}
}