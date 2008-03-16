/*
 Copyright (c) 2006 Eric J. Feminella  <eric@ericfeminella.com>
 All rights reserved.
  
 Permission is hereby granted, free of charge, to any person obtaining a copy 
 of this software and associated documentation files (the "Software"), to deal 
 in the Software without restriction, including without limitation the rights 
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished 
 to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all 
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 @ignore
 */
 
package com.ericfeminella.utils
{
    /**
     * Defines the default contract for lightweight HashMap 
     * implementations which provide an API for working with 
     * a managed collection of key and values
     */
    public interface Map
    {
        /**
         * Adds a key / value to the current Map
         * 
         * @param the key to add to the map
         * @param the value of the specified key
         */
        function put(key:String, value:*):void
        
        /**
         * Removes a key / value from the current Map
         * 
         * @param the key to remove from the map
         */
        function remove(key:String):void

        /**
         * Determines if a key exists in the current map
         * 
         * @param  the key in which to determine existance in the map
         * @return true if the key exisits, false if not
         */
        function containsKey(key:String):Boolean

        /**
         * Determines if a value exists in the current map
         * 
         * @param  the value in which to determine existance in the map
         * @return true if the value exisits, false if not
         */
        function containsValue(value:*):Boolean

        /**
         * Returns a key value from the current Map
         * 
         * @param  the key in which to retrieve the value of
         * @return the value of the specified key
         */
        function getKey(value:*):String

        /**
         * Returns a key value from the current Map
         * 
         * @param  the key in which to retrieve the value of
         * @return the value of the specified key
         */
        function getValue(key:String):*
        
        /**
         * Returns the size of this map
         * 
         * @return the current size of the map instance
         */
        function size():int

        /**
         * Determines if the current map is empty
         * 
         * @return true if the current map is empty, false if not
         */
        function isEmpty():Boolean

        /**
         * Resets all key / values in map to null
         */
        function clear():void
    }
}
