package org.amqp.test
{
	import flexunit.framework.TestSuite;
	
	import org.amqp.Connection;
	import org.amqp.patterns.BasicMessageEvent;
	import org.amqp.patterns.impl.PublishSubscribeClientImpl;
	
	public class PublishSubscribeClientTest extends AbstractTest {
		private var client:PublishSubscribeClientImpl;
		//private var serializer:JSONSerializer;
		
		public function PublishSubscribeClientTest(methodName:String=null)
		{
			super(methodName);
		}
		
		public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new PublishSubscribeClientTest("testPublishSubscribeClient"));
            return myTS;
        }
        
        public function testPublishSubscribeClient():void {
        	connection = new Connection(buildConnectionState());
        	client = new PublishSubscribeClientImpl(connection);
        	client.serializer = new JSONSerializer();
        	client.realm = "/data";
        	client.exchange = "pubsubTest";
        	client.exchangeType = "topic";
        	
        	trace("Subscribe to topic a.b.c");
        	client.subscribe("a.b.c", onConsumeABC);
        	
        	trace("Subscribe to topic d.e.f");
        	client.subscribe("d.e.f", onConsumeDEF);
        	
        	trace("Publish to topic a.b.c");
        	client.send("a.b.c", {event:"e-abc-1", msg:1});
        	client.send("a.b.c", {event:"e-abc-2", msg:2});
        	
        	trace("Publish to topic d.e.f");
        	client.send("d.e.f", {event:"e-def-1", msg:1});
        	client.send("d.e.f", {event:"e-def-2", msg:2});
        }
        
       	public function onConsumeABC(event:BasicMessageEvent):void {
       		trace("Consumed message from ABC");
       		
       		var o:* = event.result;
       		
       		switch (o.event) {
       			case "e-abc-1":
       				assertEquals(o.msg, 1);
       				break;
       			case "e-abc-2":
       				assertEquals(o.msg, 2);
       				break;
       			default:
       				break;
       		}
       	}
       	
       	public function onConsumeDEF(event:BasicMessageEvent):void {
       		trace("Consumed message from DEF");
       		
       		var o:* = event.result;
       		
       		switch (o.event) {
       			case "e-def-1":
       				assertEquals(o.msg, 1);
       				break;
       			case "e-def-2":
       				assertEquals(o.msg, 2);
       				break;
       			default:
       				break;
       		}
       	}
	}
}