package org.amqp.patterns
{
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	public interface Serializer
	{
		function serialize(o:*,stream:IDataOutput):void;
		function deserialize(stream:IDataInput):*;		
	}
}