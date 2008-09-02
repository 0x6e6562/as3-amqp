package org.amqp.test
{
	import flash.utils.Timer;

	import flexunit.framework.TestSuite;

	import org.amqp.Connection;
	import org.amqp.patterns.CorrelatedMessageEvent;
	import org.amqp.patterns.impl.RpcClientImpl;
	import org.amqp.patterns.impl.RpcServer;

    public class RpcClientServerTest extends AbstractTest {
    	private const FIB_QUESTION:int = 5;
    	private const FIB_ANSWER:int = 8;

        private var rpc:RpcClientImpl;
        private var serv:RpcServer;

        public function RpcClientServerTest(methodName:String=null)
        {
            super(methodName);
        }

        public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new RpcClientServerTest("testConnection"));
            myTS.addTest(new RpcClientServerTest("testRpc"));
            return myTS;
        }

        public function testConnection():void {
            connection = new Connection(buildConnectionState());
        }

        public function testRpc():void {
        	rpc = new RpcClientImpl(connection);
            rpc.serializer = new JSONSerializer();
            rpc.exchange = "rpcx";
            rpc.exchangeType = "direct";
            rpc.routingKey = "rpcx";

            serv = new RpcServer(connection);
            serv.serializer = new JSONSerializer();
            serv.exchange = "rpcx";
            serv.exchangeType = "direct";
            serv.bindingKey = "rpcx";
            serv.requestHandler = new Fibonacci();
            serv.debug = false;

            // Send RPC request with a timeout
        	var o:* = {number:FIB_QUESTION};
        	rpc.send(o, rpcCallback, TIMEOUT);
        }

        public function rpcCallback(event:CorrelatedMessageEvent):void {
            var o:* = event.result;
            assertEquals(o.answer, FIB_ANSWER);
        }
    }
}