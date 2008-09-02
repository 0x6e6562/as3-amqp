package org.amqp.test
{
    import flash.utils.Timer;

    import flexunit.framework.TestSuite;

    import org.amqp.Connection;
    import org.amqp.patterns.CorrelatedMessageEvent;
    import org.amqp.patterns.impl.PublishClientImpl;
    import org.amqp.patterns.impl.SubscribeClientImpl;

    public class PublishSubscribeClientTest extends AbstractTest {
        private var pubClient:PublishClientImpl;
        private var subClient:SubscribeClientImpl;
        private var serializer:JSONSerializer = new JSONSerializer();

        public function PublishSubscribeClientTest(methodName:String=null)
        {
            super(methodName);
        }

        public static function suite():TestSuite{
            var myTS:TestSuite = new TestSuite();
            myTS.addTest(new PublishSubscribeClientTest("testConnection"));
            myTS.addTest(new PublishSubscribeClientTest("testSubscribe"));
            myTS.addTest(new PublishSubscribeClientTest("testPublish"));
            return myTS;
        }

        public function testConnection():void {
            connection = new Connection(buildConnectionState());
        }

        public function testSubscribe():void {
            subClient = new SubscribeClientImpl(connection);
            subClient.serializer = serializer;
            subClient.exchange = "pubsubx";
            subClient.exchangeType = "topic";

            subClient.subscribe("utest.topic-abc", onConsumeABC);
            subClient.subscribe("utest.topic-def", onConsumeDEF);
        }

        public function testPublish():void {
            pubClient = new PublishClientImpl(connection);
            pubClient.serializer = serializer;
            pubClient.exchange = "pubsubx";
            pubClient.exchangeType = "topic";

            // wait until the topic subscription is completed
            var timer:Timer = new Timer(DELAY*2, 1);

            pubClient.send("utest.topic-abc", {msg:"e-abc-1", value:1});
            pubClient.send("utest.topic-abc", {msg:"e-abc-2", value:2});

            pubClient.send("utest.topic-def", {msg:"e-def-1", value:1});
            pubClient.send("utest.topic-def", {msg:"e-def-2", value:2});
        }

       public function onConsumeABC(event:CorrelatedMessageEvent):void {
           trace("Consumed message from ABC");

           var o:* = event.result;

           switch (o.msg) {
               case "e-abc-1":
                   assertEquals(o.value, 1);
                   break;
               case "e-abc-2":
                   assertEquals(o.value, 2);
                   break;
               default:
                   break;
           }
       }

       public function onConsumeDEF(event:CorrelatedMessageEvent):void {
           trace("Consumed message from DEF");

           var o:* = event.result;

           switch (o.msg) {
               case "e-def-1":
                   assertEquals(o.value, 1);
                   break;
               case "e-def-2":
                   assertEquals(o.value, 2);
                   break;
               default:
                   break;
           }
       }
    }
}