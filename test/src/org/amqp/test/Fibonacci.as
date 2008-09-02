package org.amqp.test
{
    import org.amqp.patterns.RequestHandler;

    public class Fibonacci implements RequestHandler {
        public function process(o:*):* {
	        const n:int = o.number;
	        var response:* = new Object();
	        response.question = n;
	        response.answer = fib(n);
	        return response;
        }

	    public function fib(n:int):int {
	        if (n < 2) return 1;
	        else return fib(n-1) + fib(n-2);
	    }

    }
}