package org.amqp.test
{
	import flash.utils.Timer;

	import flexunit.framework.TestSuite;

	import org.amqp.Connection;
	import org.amqp.error.TimeoutError;
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
        	serv = new RpcServer(connection);
            serv.serializer = new JSONSerializer();
            serv.exchange = "rpcx";
            serv.exchangeType = "direct";
            serv.bindingKey = "rpcx";
            serv.requestHandler = new Fibonacci();
            serv.debug = false;

        	rpc = new RpcClientImpl(connection);
            rpc.serializer = new JSONSerializer();
            rpc.exchange = "rpcx";
            rpc.exchangeType = "direct";
            rpc.routingKey = "rpcx";

            // The timeout handler only necessary if the RPC client
            // use the optional timeout argument when sending requests
            rpc.addTimeoutHandler(timeoutHandler);

            // Send RPC request without a timeout
        	var o:* = {number:FIB_QUESTION};
        	rpc.send(o, rpcCallback);

        	// Change the exchange for the RPC client so it doesn't invoke
        	// the server and times-out
        	rpc.exchange = "nobody";
        	rpc.send(o, rpcCallback, TIMEOUT);
        	var timer:Timer = new Timer(TIMEOUT, 1);
        	timer.start();
        }

        public function rpcCallback(event:CorrelatedMessageEvent):void {
            var o:* = event.result;
            assertEquals(o.answer, FIB_ANSWER);
        }

        public function timeoutHandler(event:TimeoutError):void {
        	assertEquals(event.type, TimeoutError.TIMEOUT_ERROR);
        	trace("rpc timed out");
        }
    }
}